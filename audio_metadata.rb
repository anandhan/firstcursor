require 'taglib'

class AudioMetadata
  def self.extract(file_path)
    metadata = {}
    
    begin
      TagLib::FileRef.open(file_path) do |file|
        unless file.null?
          tag = file.tag
          metadata = {
            title: tag.title,
            artist: tag.artist,
            album: tag.album,
            year: tag.year,
            genre: tag.genre,
            comment: tag.comment
          }
        end
      end
    rescue => e
      puts "  Warning: Could not extract metadata: #{e.message}"
    end
    
    metadata
  end

  def self.set(file_path, metadata = {})
    begin
      puts "\nUpdating metadata for: #{File.basename(file_path)}"
      
      TagLib::FileRef.open(file_path) do |file|
        if file.null?
          puts "  Error: Could not open file for writing"
          return false
        end

        tag = file.tag
        metadata.each do |key, value|
          case key.to_sym
          when :title
            tag.title = value
          when :artist
            tag.artist = value
          when :album
            tag.album = value
          when :year
            tag.year = value.to_i
          when :genre
            tag.genre = value
          when :comment
            tag.comment = value
          end
        end

        # Save the changes
        if file.save
          puts "  Successfully updated metadata"
          return true
        else
          puts "  Error: Could not save metadata changes"
          return false
        end
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