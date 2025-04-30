require 'mini_exiftool'
require 'logger'

module AudioParser
  class OGGMetadata
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def self.extract(file_path)
      @@logger.debug "Extracting OGG metadata from: #{file_path}"
      metadata = {}
      
      begin
        exif = MiniExiftool.new(file_path)
        metadata = {
          title: exif.title,
          artist: exif.artist,
          album: exif.album,
          year: exif.year,
          genre: exif.genre,
          comment: exif.comment,
          duration: exif.duration,
          sample_rate: exif.sample_rate,
          channels: exif.channels,
          nominal_bitrate: exif.nominal_bitrate
        }
        @@logger.debug "Successfully extracted OGG metadata"
      rescue => e
        @@logger.error "Error extracting OGG metadata: #{e.message}"
      end
      
      metadata
    end
  end
end 