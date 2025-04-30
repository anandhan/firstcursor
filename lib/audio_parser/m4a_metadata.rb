require 'mini_exiftool'
require 'logger'

module AudioParser
  class M4AMetadata
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def self.extract(file_path)
      @@logger.debug "Extracting M4A metadata from: #{file_path}"
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
          sample_rate: exif.audio_sample_rate,
          channels: exif.audio_channels,
          bits_per_sample: exif.bits_per_sample
        }
        @@logger.debug "Successfully extracted M4A metadata"
      rescue => e
        @@logger.error "Error extracting M4A metadata: #{e.message}"
      end
      
      metadata
    end
  end
end 