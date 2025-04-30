require 'mp3info'
require 'logger'

module AudioParser
  class MP3Metadata
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO

    def self.extract(file_path)
      @@logger.debug "Extracting MP3 metadata from: #{file_path}"
      metadata = {}
      
      begin
        Mp3Info.open(file_path) do |mp3|
          metadata = {
            title: mp3.tag.title,
            artist: mp3.tag.artist,
            album: mp3.tag.album,
            year: mp3.tag.year,
            genre: mp3.tag.genre_s,
            comment: mp3.tag.comments,
            duration: mp3.length,
            bitrate: mp3.bitrate,
            sample_rate: mp3.samplerate,
            channels: mp3.channel_mode
          }
        end
        @@logger.debug "Successfully extracted MP3 metadata"
      rescue => e
        @@logger.error "Error extracting MP3 metadata: #{e.message}"
      end
      
      metadata
    end
  end
end 