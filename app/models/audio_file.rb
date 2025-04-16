class AudioFile < ApplicationRecord
  validates :filename, presence: true

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

  def update_metadata
    begin
      Rails.logger.info "Starting metadata update for file: #{filename}"
      
      # Initialize ExifTool
      exif = MiniExiftool.new(filename)
      Rails.logger.info "ExifTool initialized for file: #{filename}"
      
      # Extract metadata
      self.title = exif.title || File.basename(filename, '.*')
      self.artist = exif.artist
      self.album = exif.album
      self.year = exif.year
      self.genre = exif.genre
      self.composer = exif.composer
      
      Rails.logger.info "Extracted metadata: title=#{title}, artist=#{artist}, album=#{album}, year=#{year}, genre=#{genre}"
      
      # Handle cover art
      if exif.picture
        Rails.logger.info "Found cover art in file: #{filename}"
        cover_art_dir = Rails.root.join('public', 'cover_art')
        FileUtils.mkdir_p(cover_art_dir)
        Rails.logger.info "Created cover art directory at: #{cover_art_dir}"
        
        cover_art_filename = "#{SecureRandom.hex(8)}.jpg"
        cover_art_path = cover_art_dir.join(cover_art_filename)
        
        begin
          File.open(cover_art_path, 'wb') do |f|
            f.write(exif.picture)
          end
          Rails.logger.info "Successfully wrote cover art to: #{cover_art_path}"
          self.cover_art = "/cover_art/#{cover_art_filename}"
        rescue => e
          Rails.logger.error "Failed to write cover art: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      else
        Rails.logger.info "No cover art found in file: #{filename}"
      end
      
      if save
        Rails.logger.info "Successfully updated metadata for file: #{filename}"
        Rails.logger.info "Metadata: title=#{title}, artist=#{artist}, album=#{album}, year=#{year}, genre=#{genre}"
        Rails.logger.info "Cover art path: #{cover_art}" if cover_art
        true
      else
        Rails.logger.error "Failed to save metadata for file: #{filename}"
        Rails.logger.error "Errors: #{errors.full_messages.join(', ')}"
        false
      end
    rescue => e
      Rails.logger.error "Error updating metadata for file: #{filename}\n#{e.message}\n#{e.backtrace.join("\n")}"
      false
    end
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