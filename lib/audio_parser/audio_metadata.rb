require 'mp3info'
require 'wavefile'
require 'mini_exiftool'
require 'base64'
require 'tempfile'
require 'logger'
require_relative 'mp3_metadata'
require_relative 'wav_metadata'
require_relative 'flac_metadata'
require_relative 'm4a_metadata'
require_relative 'ogg_metadata'

module AudioParser
  class AudioMetadata
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def self.extract(file_path)
      @@logger.debug "Extracting metadata for: #{file_path}"
      
      # Determine file type and use appropriate metadata extractor
      case File.extname(file_path).downcase
      when '.mp3'
        MP3Metadata.extract(file_path)
      when '.wav'
        WAVMetadata.extract(file_path)
      when '.flac'
        FLACMetadata.extract(file_path)
      when '.m4a'
        M4AMetadata.extract(file_path)
      when '.ogg'
        OGGMetadata.extract(file_path)
      else
        @@logger.warn "Unsupported file format: #{file_path}"
        nil
      end
    rescue StandardError => e
      @@logger.error "Error extracting metadata: #{e.message}"
      nil
    end

    def self.set(file_path, metadata = {})
      begin
        puts "\nUpdating metadata for: #{File.basename(file_path)}"
        
        case File.extname(file_path).downcase
        when '.mp3'
          Mp3Info.open(file_path) do |mp3|
            metadata.each do |key, value|
              case key.to_sym
              when :title
                mp3.tag.title = value
              when :artist
                mp3.tag.artist = value
              when :album
                mp3.tag.album = value
              when :year
                mp3.tag.year = value.to_i
              when :genre
                mp3.tag.genre_s = value
              when :comment
                mp3.tag.comments = value
              end
            end
          end
          puts "  Successfully updated metadata"
          return true
        when '.wav'
          puts "  Warning: WAV files do not support embedded metadata"
          return false
        when '.flac'
          exif = MiniExiftool.new(file_path)
          metadata.each do |key, value|
            case key.to_sym
            when :title
              exif.title = value
            when :artist
              exif.artist = value
            when :album
              exif.album = value
            when :year
              exif.year = value.to_i
            when :genre
              exif.genre = value
            when :comment
              exif.comment = value
            end
          end
          exif.save
          puts "  Successfully updated metadata"
          return true
        else
          puts "  Error: Unsupported file format"
          return false
        end
      rescue => e
        puts "  Error updating metadata: #{e.message}"
        return false
      end
    end

    def self.list_all_tags(file_path)
      unless system("which exiftool > /dev/null 2>&1")
        @@logger.warn "exiftool not found in system"
        return nil
      end
      
      begin
        @@logger.debug "Listing all tags for: #{file_path}"
        result = `exiftool -listx "#{file_path}" 2>/dev/null`
        @@logger.debug "Available tags:\n#{result}"
        return result
      rescue => e
        @@logger.error "Error listing tags: #{e.message}"
        return nil
      end
    end

    def self.find_cover_art_file(file_path)
      dir = File.dirname(file_path)
      base_name = File.basename(dir)
      
      # Common cover art file names
      cover_names = [
        'cover.jpg', 'cover.jpeg', 'cover.png',
        'folder.jpg', 'folder.jpeg', 'folder.png',
        'album.jpg', 'album.jpeg', 'album.png',
        'front.jpg', 'front.jpeg', 'front.png',
        "#{base_name}.jpg", "#{base_name}.jpeg", "#{base_name}.png"
      ]
      
      # Look in current directory
      cover_names.each do |name|
        cover_path = File.join(dir, name)
        if File.exist?(cover_path)
          @@logger.debug "Found cover art file: #{cover_path}"
          return cover_path
        end
      end
      
      # Look in Covers subdirectory
      covers_dir = File.join(dir, 'Covers')
      if File.directory?(covers_dir)
        cover_names.each do |name|
          cover_path = File.join(covers_dir, name)
          if File.exist?(cover_path)
            @@logger.debug "Found cover art file in Covers directory: #{cover_path}"
            return cover_path
          end
        end
      end
      
      # Look in parent directory
      parent_dir = File.dirname(dir)
      cover_names.each do |name|
        cover_path = File.join(parent_dir, name)
        if File.exist?(cover_path)
          @@logger.debug "Found cover art file in parent directory: #{cover_path}"
          return cover_path
        end
      end
      
      nil
    end

    def self.extract_cover_art(file_path)
      # Try to find a cover art file first
      cover_path = find_cover_art_file(file_path)
      if cover_path
        begin
          data = Base64.strict_encode64(File.binread(cover_path))
          @@logger.debug "Successfully read cover art file: #{cover_path}"
          return {
            data: data,
            mime_type: "image/#{File.extname(cover_path)[1..-1]}"
          }
        rescue => e
          @@logger.error "Error reading cover art file: #{e.message}"
        end
      end
      
      # Try exiftool for embedded cover art
      cover_art = extract_cover_art_with_exiftool(file_path)
      return cover_art if cover_art

      # Fall back to ffmpeg if exiftool fails
      extract_cover_art_with_ffmpeg(file_path)
    end

    private

    def self.extract_cover_art_with_ffmpeg(file_path)
      unless system("which ffmpeg > /dev/null 2>&1")
        @@logger.warn "ffmpeg not found in system"
        return nil
      end
      
      temp_file = Tempfile.new(['cover', '.jpg'])
      begin
        @@logger.debug "Running ffmpeg command to extract cover art from: #{file_path}"
        
        # Try different ffmpeg commands in order of preference
        commands = [
          # Try to extract embedded cover art
          "timeout 5s ffmpeg -i \"#{file_path}\" -an -vcodec copy \"#{temp_file.path}\" 2>/dev/null",
          # Try to extract video stream
          "timeout 5s ffmpeg -i \"#{file_path}\" -map 0:v -map -0:V -c copy \"#{temp_file.path}\" 2>/dev/null",
          # Try to extract first image attachment
          "timeout 5s ffmpeg -i \"#{file_path}\" -map 0:v:0 -frames:v 1 \"#{temp_file.path}\" 2>/dev/null"
        ]
        
        success = false
        commands.each do |cmd|
          @@logger.debug "Trying command: #{cmd}"
          success = system(cmd)
          break if success && File.exist?(temp_file.path) && File.size(temp_file.path) > 0
        end
        
        if !success
          @@logger.debug "All ffmpeg commands failed"
          return nil
        end
        
        if File.exist?(temp_file.path) && File.size(temp_file.path) > 0
          @@logger.debug "Cover art extracted to temp file, size: #{File.size(temp_file.path)} bytes"
          data = Base64.strict_encode64(File.binread(temp_file.path))
          @@logger.debug "Cover art data length: #{data.length} characters"
          return {
            data: data,
            mime_type: 'image/jpeg'
          }
        else
          @@logger.debug "No cover art extracted (temp file empty or missing)"
        end
      rescue => e
        @@logger.error "Error extracting cover art with ffmpeg: #{e.message}"
        @@logger.error e.backtrace.join("\n")
      ensure
        temp_file.close
        temp_file.unlink
      end
      
      nil
    end

    def self.extract_cover_art_with_exiftool(file_path)
      unless system("which exiftool > /dev/null 2>&1")
        @@logger.warn "exiftool not found in system"
        return nil
      end
      
      temp_file = Tempfile.new(['cover', '.jpg'])
      begin
        @@logger.debug "Running exiftool command to extract cover art from: #{file_path}"
        
        # Try different tag names for cover art
        tag_names = [
          "-Picture",           # Common tag
          "-CoverArt",         # Alternative tag
          "-CoverImage",       # Another alternative
          "-Artwork",          # Another alternative
          "-ThumbnailImage",   # For thumbnails
          "-PreviewImage"      # For preview images
        ]
        
        success = false
        tag_names.each do |tag|
          @@logger.debug "Trying exiftool with tag: #{tag}"
          success = system("exiftool -b #{tag} \"#{file_path}\" > \"#{temp_file.path}\" 2>/dev/null")
          
          # Check if we got any data
          if success && File.exist?(temp_file.path) && File.size(temp_file.path) > 0
            @@logger.debug "Successfully extracted cover art using tag: #{tag}"
            break
          end
        end
        
        if !success
          @@logger.debug "All exiftool commands failed"
          return nil
        end
        
        if File.exist?(temp_file.path) && File.size(temp_file.path) > 0
          @@logger.debug "Cover art extracted to temp file using exiftool, size: #{File.size(temp_file.path)} bytes"
          data = Base64.strict_encode64(File.binread(temp_file.path))
          @@logger.debug "Cover art data length: #{data.length} characters"
          return {
            data: data,
            mime_type: 'image/jpeg'
          }
        else
          @@logger.debug "No cover art extracted using exiftool (temp file empty or missing)"
        end
      rescue => e
        @@logger.error "Error extracting cover art with exiftool: #{e.message}"
        @@logger.error e.backtrace.join("\n")
      ensure
        temp_file.close
        temp_file.unlink
      end
      
      nil
    end

    def self.prompt_for_metadata
      metadata = {}
      
      puts "\nEnter metadata (press Enter to skip a field):"
      
      print "Title: "
      title = gets.chomp
      metadata[:title] = title unless title.empty?
      
      print "Artist: "
      artist = gets.chomp
      metadata[:artist] = artist unless artist.empty?
      
      print "Album: "
      album = gets.chomp
      metadata[:album] = album unless album.empty?
      
      print "Year: "
      year = gets.chomp
      metadata[:year] = year unless year.empty?
      
      print "Genre: "
      genre = gets.chomp
      metadata[:genre] = genre unless genre.empty?
      
      print "Comment: "
      comment = gets.chomp
      metadata[:comment] = comment unless comment.empty?
      
      metadata
    end
  end
end 