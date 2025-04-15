class AudioFile < ApplicationRecord
  validates :filename, presence: true

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
    
    # List all files in the directory
    all_files = Dir.glob(File.join(directory_path, '**', '*'))
    Rails.logger.info "Found #{all_files.size} total files in directory"
    
    # Log all files found
    all_files.each do |file_path|
      if File.file?(file_path)
        Rails.logger.info "Found file: #{file_path}"
      else
        Rails.logger.info "Found directory: #{file_path}"
      end
    end
    
    # Process audio files
    audio_files = Dir.glob(File.join(directory_path, '**', '*.{mp3,m4a,wav,flac,ogg}'))
    Rails.logger.info "Found #{audio_files.size} audio files to process"
    
    audio_files.each do |file_path|
      Rails.logger.info "Processing audio file: #{file_path}"
      audio_file = find_or_initialize_by(filename: file_path)
      if audio_file.new_record?
        Rails.logger.info "New audio file found, updating metadata: #{file_path}"
        audio_file.update_metadata
      else
        Rails.logger.info "Audio file already exists in database: #{file_path}"
      end
    end
    Rails.logger.info "Completed directory scan: #{directory_path}"
  end
end 