require 'wavefile'
require 'logger'

module AudioParser
  class WAVMetadata
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def self.extract(file_path)
      @@logger.debug "Extracting WAV metadata from: #{file_path}"
      metadata = {}
      
      begin
        reader = WaveFile::Reader.new(file_path)
        format = reader.format
        
        metadata = {
          duration: reader.total_duration.seconds,
          channels: format.channels,
          sample_rate: format.sample_rate,
          bits_per_sample: format.bits_per_sample,
          block_align: format.block_align,
          byte_rate: format.byte_rate
        }
        
        @@logger.debug "Successfully extracted WAV metadata"
      rescue => e
        @@logger.error "Error extracting WAV metadata: #{e.message}"
      end
      
      metadata
    end
  end
end 