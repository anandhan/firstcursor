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
        AudioParser::MP3Metadata.extract(file_path)
      when '.wav'
        AudioParser::WAVMetadata.extract(file_path)
      when '.flac'
        AudioParser::FLACMetadata.extract(file_path)
      when '.m4a'
        AudioParser::M4AMetadata.extract(file_path)
      when '.ogg'
        AudioParser::OGGMetadata.extract(file_path)
      else
        @@logger.warn "Unsupported file format: #{file_path}"
        nil
      end
    rescue StandardError => e
      @@logger.error "Error extracting metadata: #{e.message}"
      nil
    end
  end
end 