require 'mp3info'
require 'wavefile'
require 'mini_exiftool'
require 'base64'
require 'tempfile'
require 'logger'

class AudioMetadata
  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::DEBUG

  def self.extract(file_path, options = {})
    options = {
      extract_cover_art: true,
      timeout: 5
    }.merge(options)

    metadata = {}
    
    begin
      case File.extname(file_path).downcase
      when '.mp3'
        Mp3Info.open(file_path) do |mp3|
          metadata = {
            title: mp3.tag.title,
            artist: mp3.tag.artist,
            album: mp3.tag.album,
            year: mp3.tag.year,
            genre: mp3.tag.genre_s,
            comment: mp3.tag.comments
          }

          if options[:extract_cover_art] && mp3.tag2.pictures.any?
            @@logger.debug "Found pictures in MP3 file"
            picture = mp3.tag2.pictures.first
            if picture && picture.data
              @@logger.debug "Found picture data, mime type: #{picture.mime_type}"
              metadata[:cover_art] = Base64.strict_encode64(picture.data)
              metadata[:cover_art_mime_type] = picture.mime_type
            end
          end
        end
      when '.wav'
        reader = WaveFile::Reader.new(file_path)
        format = reader.format
        metadata = {
          title: File.basename(file_path, '.wav'),
          channels: format.channels,
          sample_rate: format.sample_rate,
          bits_per_sample: format.bits_per_sample,
          duration: reader.total_duration.seconds,
          format: 'WAV',
          file_size: File.size(file_path)
        }

        # Try to extract cover art from WAV if enabled
        if options[:extract_cover_art]
          begin
            @@logger.debug "Attempting to extract cover art from WAV file"
            cover_art = extract_cover_art_with_ffmpeg(file_path)
            if cover_art
              metadata[:cover_art] = cover_art[:data]
              metadata[:cover_art_mime_type] = cover_art[:mime_type]
              @@logger.debug "Successfully extracted cover art from WAV file"
            else
              @@logger.debug "No cover art found in WAV file"
            end
          rescue => e
            @@logger.error "Error extracting WAV cover art: #{e.message}"
          end
        end
      when '.flac'
        exif = MiniExiftool.new(file_path)
        metadata = {
          title: exif.title || File.basename(file_path, '.flac'),
          artist: exif.artist,
          album: exif.album,
          year: exif.year,
          genre: exif.genre,
          comment: exif.comment,
          sample_rate: exif.sample_rate,
          channels: exif.channels,
          bits_per_sample: exif.bits_per_sample,
          duration: exif.duration,
          format: 'FLAC',
          file_size: File.size(file_path)
        }

        # Try to extract cover art from FLAC if enabled
        if options[:extract_cover_art]
          begin
            cover_art = extract_cover_art_with_ffmpeg(file_path)
            if cover_art
              metadata[:cover_art] = cover_art[:data]
              metadata[:cover_art_mime_type] = cover_art[:mime_type]
            end
          rescue => e
            @@logger.error "Error extracting FLAC cover art: #{e.message}"
          end
        end
      end
    rescue => e
      @@logger.error "Could not extract metadata: #{e.message}"
      @@logger.error e.backtrace.join("\n")
    end
    
    metadata
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