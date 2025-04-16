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
      exif = MiniExiftool.new(filename)
      
      Rails.logger.info "Extracted metadata for file: #{filename}"
      Rails.logger.debug "Title: #{exif.title}, Artist: #{exif.artist}, Album: #{exif.album}"
      
      self.title = exif.title
      self.artist = exif.artist
      self.album = exif.album
      self.year = exif.year
      self.genre = exif.genre
      self.composer = exif.composer
      
      # Handle cover art
      if exif.picture && !exif.picture.empty?
        Rails.logger.info "Found cover art for file: #{filename}"
        cover_art_dir = Rails.root.join('public', 'cover_art')
        FileUtils.mkdir_p(cover_art_dir)
        
        cover_art_filename = "#{SecureRandom.uuid}.jpg"
        cover_art_path = cover_art_dir.join(cover_art_filename)
        
        File.binwrite(cover_art_path, exif.picture)
        self.cover_art = "/cover_art/#{cover_art_filename}"
        Rails.logger.info "Saved cover art to: #{cover_art_path}"
      else
        Rails.logger.info "No cover art found for file: #{filename}"
      end
      
      if save
        Rails.logger.info "Successfully saved metadata for file: #{filename}"
        true
      else
        Rails.logger.error "Failed to save metadata for file: #{filename}. Errors: #{errors.full_messages.join(', ')}"
        false
      end
    rescue => e
      Rails.logger.error "Error updating metadata for file: #{filename}\nError: #{e.message}\n#{e.backtrace.join("\n")}"
      false
    end
  end

  def self.parse_directory(directory_path)
    Rails.logger.info "Starting directory scan: #{directory_path}"
    
    # Get directory contents
    contents = list_directory_contents(directory_path)
    
    # Process audio files
    audio_files = contents[:files].select { |f| ['.mp3', '.m4a', '.wav', '.flac', '.ogg'].include?(f[:type]) }
    Rails.logger.info "\nFound #{audio_files.size} audio files to process"
    
    audio_files.each do |file_info|
      file_path = File.join(directory_path, file_info[:path])
      Rails.logger.info "\nProcessing audio file: #{file_path}"
      audio_file = find_or_initialize_by(filename: file_path)
      if audio_file.new_record?
        Rails.logger.info "New audio file found, updating metadata: #{file_path}"
        audio_file.update_metadata
      else
        Rails.logger.info "Audio file already exists in database: #{file_path}"
      end
    end
    
    Rails.logger.info "\nCompleted directory scan: #{directory_path}"
    contents
  end
end 