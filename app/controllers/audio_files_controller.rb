class AudioFilesController < ApplicationController
  def index
    @audio_files = []
  end

  def scan
    path = params[:path]
    
    if path.blank?
      flash[:alert] = "Please enter a directory path"
      redirect_to root_path
      return
    end

    begin
      path = File.expand_path(path)
      
      unless File.directory?(path)
        flash[:alert] = "Invalid directory path"
        redirect_to root_path
        return
      end

      @audio_files = []
      Dir.foreach(path) do |file|
        next if file == '.' || file == '..'
        ext = File.extname(file).downcase
        if ['.mp3', '.wav', '.m4a', '.flac', '.ogg'].include?(ext)
          @audio_files << { name: file, type: ext }
        end
      end

      flash[:notice] = "Found #{@audio_files.size} audio files"
    rescue => e
      flash[:alert] = "Error: #{e.message}"
    end

    render :index
  end

  def update_metadata
    @audio_file = AudioFile.find(params[:id])
    Rails.logger.info "User attempting to update metadata for file: #{@audio_file.filename}"
    
    if @audio_file.update_metadata
      flash[:notice] = "Metadata updated successfully"
      Rails.logger.info "Successfully updated metadata for file: #{@audio_file.filename}"
    else
      flash[:alert] = "Failed to update metadata"
      Rails.logger.error "Failed to update metadata for file: #{@audio_file.filename}"
    end
    
    redirect_to audio_files_path
  end
end
