require 'mp3info'
require 'wavefile'

class AudioMetadata
  def self.extract(file_path)
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
        end
      when '.wav'
        reader = WaveFile::Reader.new(file_path)
        format = reader.format
        metadata = {
          title: File.basename(file_path, '.wav'),
          channels: format.channels,
          sample_rate: format.sample_rate,
          bits_per_sample: format.bits_per_sample,
          duration: reader.total_duration.seconds
        }
      end
    rescue => e
      puts "  Warning: Could not extract metadata: #{e.message}"
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
      else
        puts "  Error: Unsupported file format"
        return false
      end
    rescue => e
      puts "  Error updating metadata: #{e.message}"
      return false
    end
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