require_relative '../../lib/audio_parser/file_parser'
require_relative '../../lib/audio_parser/audio_metadata'

class AudioFilesController < ApplicationController
  def index
    @audio_files = []
  end

  def parse
    @parser = AudioParser::FileParser.new
    directory_path = params[:directory_path]

    if directory_path.blank?
      flash[:error] = "Please provide a directory path"
      redirect_to audio_files_path and return
    end

    begin
      @files = []
      @parser.parse_directory(directory_path) do |file_info|
        @files << file_info
      end

      if @files.empty?
        flash[:notice] = "No audio files found in the specified directory"
      end
    rescue => e
      flash[:error] = "Error processing directory: #{e.message}"
    end

    render :index
  end

  private

  def audio_file?(file)
    %w[.mp3 .wav].include?(File.extname(file).downcase)
  end

  def format_file_size(bytes)
    return "#{bytes} B" if bytes < 1024
    
    units = ['KB', 'MB', 'GB', 'TB']
    size = bytes.to_f
    unit = 0
    
    while size >= 1024 && unit < units.size - 1
      size /= 1024
      unit += 1
    end
    
    "#{size.round(2)} #{units[unit]}"
  end

  def extract_cover_art(file_path)
    # Create a directory for cover art if it doesn't exist
    cover_art_dir = Rails.root.join('public', 'cover_art')
    FileUtils.mkdir_p(cover_art_dir)

    # Generate a unique filename for the cover art
    filename = Digest::MD5.hexdigest(file_path) + '.jpg'
    cover_art_path = cover_art_dir.join(filename)

    # Only extract if we haven't already
    return "/cover_art/#{filename}" if File.exist?(cover_art_path)

    begin
      # Use ffmpeg to extract the cover art
      system("ffmpeg -i \"#{file_path}\" -an -vcodec copy \"#{cover_art_path}\" 2>/dev/null")
      
      # If extraction failed, try another method
      unless File.exist?(cover_art_path)
        system("ffmpeg -i \"#{file_path}\" -map 0:v -map -0:V -c copy \"#{cover_art_path}\" 2>/dev/null")
      end

      # If we successfully extracted cover art, return the path
      if File.exist?(cover_art_path)
        "/cover_art/#{filename}"
      else
        nil
      end
    rescue => e
      Rails.logger.error "Error extracting cover art: #{e.message}"
      nil
    end
  end
end
