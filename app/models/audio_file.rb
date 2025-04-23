require 'mini_exiftool'
require 'taglib'

class AudioFile
  AUDIO_EXTENSIONS = ['.mp3', '.wav', '.m4a', '.flac', '.ogg'].freeze

  def self.scan_directory(directory_path)
    Rails.logger.info "Scanning directory: #{directory_path}"
    return [] unless File.directory?(directory_path)

    Dir.glob(File.join(directory_path, '**', '*')).select do |file|
      next unless File.file?(file)
      ext = File.extname(file).downcase
      AUDIO_EXTENSIONS.include?(ext)
    end
  end

  def self.update_metadata(file_path)
    Rails.logger.info "Updating metadata for: #{file_path}"
    begin
      # First try with ExifTool for basic metadata
      exiftool = MiniExiftool.new(file_path)
      Rails.logger.info "ExifTool initialized successfully"
      
      # Extract basic metadata
      metadata = {
        title: exiftool.title || File.basename(file_path, '.*'),
        artist: exiftool.artist,
        album: exiftool.album,
        year: exiftool.year,
        genre: exiftool.genre
      }
      Rails.logger.info "Extracted metadata: #{metadata.inspect}"
      
      # Now try to extract cover art using TagLib
      begin
        TagLib::FileRef.open(file_path) do |file|
          unless file.null?
            tag = file.tag
            if tag
              # Update metadata with TagLib data if ExifTool didn't find it
              metadata[:title] ||= tag.title
              metadata[:artist] ||= tag.artist
              metadata[:album] ||= tag.album
              metadata[:year] ||= tag.year
              metadata[:genre] ||= tag.genre
            end
            
            # Try to get cover art
            if file.respond_to?(:properties)
              properties = file.properties
              if properties && properties.respond_to?(:pictures)
                pictures = properties.pictures
                if pictures && !pictures.empty?
                  Rails.logger.info "Found #{pictures.size} pictures using TagLib"
                  picture = pictures.first
                  if picture && picture.data
                    Rails.logger.info "Picture data size: #{picture.data.bytesize} bytes"
                    
                    # Save the cover art
                    cover_dir = Rails.root.join('public', 'cover_art')
                    FileUtils.mkdir_p(cover_dir) unless Dir.exist?(cover_dir)
                    
                    filename = "#{File.basename(file_path, '.*')}_#{Time.now.to_i}.jpg"
                    cover_path = cover_dir.join(filename)
                    
                    begin
                      File.binwrite(cover_path, picture.data)
                      if File.exist?(cover_path)
                        metadata[:cover_art_path] = "/cover_art/#{filename}"
                        Rails.logger.info "Cover art successfully saved to: #{cover_path}"
                      end
                    rescue => e
                      Rails.logger.error "Error saving cover art: #{e.message}"
                    end
                  end
                end
              end
            end
          end
        end
      rescue => e
        Rails.logger.error "Error with TagLib: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end

      metadata
    rescue => e
      Rails.logger.error "Error processing #{file_path}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {}
    end
  end

  private

  def self.is_valid_cover_art?(data)
    return false unless data.respond_to?(:bytesize)
    
    # Check for JPEG markers
    if data.include?("\xFF\xD8\xFF") && data.include?("\xFF\xD9")
      Rails.logger.info "Cover art appears to be a valid JPEG"
      return true
    end
    
    # Check for PNG markers
    if data.include?("\x89PNG\r\n\x1a\n")
      Rails.logger.info "Cover art appears to be a valid PNG"
      return true
    end
    
    # If we can't determine the format but the data exists, accept it
    if data.bytesize > 0
      Rails.logger.info "Cover art data exists but format is unknown"
      return true
    end
    
    false
  end

  def self.extract_embedded_image(file_path)
    begin
      file_data = File.binread(file_path)
      # Look for JPEG markers
      if file_data.include?("\xFF\xD8\xFF")
        start_idx = file_data.index("\xFF\xD8\xFF")
        end_idx = file_data.index("\xFF\xD9", start_idx)
        if end_idx
          return file_data[start_idx..end_idx+1]
        end
      end
    rescue => e
      Rails.logger.error "Error extracting embedded image: #{e.message}"
    end
    nil
  end

  def self.list_directory_contents(directory_path)
    Rails.logger.info "Listing contents of directory: #{directory_path}"
    
    # Ensure directory path is valid
    directory_path = File.expand_path(directory_path)
    unless File.directory?(directory_path)
      Rails.logger.error "Invalid directory path: #{directory_path}"
      return { directories: [], files: [] }
    end
    
    all_files = Dir.glob(File.join(directory_path, '**', '*'))
    Rails.logger.info "Found #{all_files.size} total items in directory"
    
    # Sort files and directories for better readability
    directories = []
    files = []
    
    all_files.each do |item|
      begin
        if File.directory?(item)
          directories << item
        else
          # Only include readable files
          if File.readable?(item)
            files << item
          else
            Rails.logger.warn "Skipping unreadable file: #{item}"
          end
        end
      rescue => e
        Rails.logger.error "Error processing item #{item}: #{e.message}"
      end
    end
    
    # Log directories first
    Rails.logger.info "\nDirectories:"
    directories.sort.each do |dir|
      relative_path = dir.gsub(directory_path, '')
      Rails.logger.info "📁 #{relative_path}"
    end
    
    # Log files with their sizes and types
    Rails.logger.info "\nFiles:"
    files.sort.each do |file|
      begin
        relative_path = file.gsub(directory_path, '')
        size = File.size(file)
        size_str = size < 1024 ? "#{size} B" : 
                   size < 1024 * 1024 ? "#{(size / 1024.0).round(2)} KB" :
                   "#{(size / (1024.0 * 1024.0)).round(2)} MB"
        
        file_type = File.extname(file).downcase
        icon = case file_type
               when '.mp3', '.wav', '.m4a', '.flac', '.ogg' then '🎵'
               when '.jpg', '.jpeg', '.png', '.gif' then '🖼️'
               when '.txt', '.md' then '📝'
               else '📄'
               end
        
        Rails.logger.info "#{icon} #{relative_path} (#{size_str})"
      rescue => e
        Rails.logger.error "Error processing file #{file}: #{e.message}"
      end
    end
    
    return {
      directories: directories.map { |d| d.gsub(directory_path, '') },
      files: files.map { |f| 
        begin
          {
            path: f.gsub(directory_path, ''),
            size: File.size(f),
            type: File.extname(f).downcase
          }
        rescue => e
          Rails.logger.error "Error getting file info for #{f}: #{e.message}"
          nil
        end
      }.compact
    }
  end

  def self.parse_directory(directory_path)
    Rails.logger.info "Starting directory parse: #{directory_path}"
    
    # Initialize statistics
    stats = {
      total_files: 0,
      audio_files: 0,
      processed_files: 0,
      directories: 0,
      start_time: Time.now
    }
    
    # Initialize directory contents
    contents = {
      directories: [],
      files: [],
      audio_files: []  # New array for audio files specifically
    }
    
    begin
      # Ensure the directory path is absolute and exists
      directory_path = File.expand_path(directory_path)
      unless File.directory?(directory_path)
        Rails.logger.error "Invalid directory path: #{directory_path}"
        return { contents: contents, stats: stats }
      end
      
      # First pass: discover all files
      Dir.glob(File.join(directory_path, '**', '*')).each do |path|
        next if File.directory?(path)
        
        stats[:total_files] += 1
        relative_path = path.sub(directory_path + '/', '')
        
        if File.directory?(File.dirname(path))
          if File.directory?(path)
            stats[:directories] += 1
            contents[:directories] << { name: relative_path, size: 0 }
          else
            file_info = {
              name: File.basename(path),
              path: relative_path,
              size: File.size(path),
              type: File.extname(path).downcase,
              full_path: path
            }
            contents[:files] << file_info
            
            # Track audio files separately
            if ['.mp3', '.m4a', '.wav', '.flac', '.ogg'].include?(file_info[:type])
              stats[:audio_files] += 1
              contents[:audio_files] << file_info
            end
          end
        end
      end
      
      # Second pass: process audio files
      contents[:audio_files].each do |file_info|
        begin
          audio_file = find_or_initialize_by(filename: file_info[:full_path])
          if audio_file.new_record?
            Rails.logger.info "Processing new audio file: #{file_info[:full_path]}"
            if audio_file.update_metadata
              stats[:processed_files] += 1
              Rails.logger.info "Successfully processed file: #{file_info[:full_path]}"
            else
              Rails.logger.error "Failed to process file: #{file_info[:full_path]}"
            end
          else
            Rails.logger.info "Skipping already processed file: #{file_info[:full_path]}"
          end
        rescue => e
          Rails.logger.error "Error processing file #{file_info[:full_path]}: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end
      
      stats[:processing_time] = Time.now - stats[:start_time]
      Rails.logger.info "Directory parse completed in #{stats[:processing_time]} seconds"
      Rails.logger.info "Statistics: #{stats}"
      
      return { contents: contents, stats: stats }
    rescue => e
      Rails.logger.error "Error parsing directory: #{e.message}\n#{e.backtrace.join("\n")}"
      return { contents: contents, stats: stats }
    end
  end
end 