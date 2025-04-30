require 'mini_exiftool'
require 'logger'

module AudioParser
  class FLACMetadata
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def self.extract(file_path)
      @@logger.debug "Extracting FLAC metadata from: #{file_path}"
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
          bits_per_sample: exif.bits_per_sample
        }
        @@logger.debug "Successfully extracted FLAC metadata"
      rescue => e
        @@logger.error "Error extracting FLAC metadata: #{e.message}"
      end
      
      metadata
    end
  end
end 