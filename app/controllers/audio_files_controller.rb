class AudioFilesController < ApplicationController
  def index
    @audio_files = AudioFile.all
    @directory_contents = nil
  end

  def parse
    @audio_files = AudioFile.all
    
    if params[:directory_path].present?
      directory_path = params[:directory_path]
      Rails.logger.info "Received directory path: #{directory_path}"
      
      begin
        # Ensure the path is absolute and exists
        directory_path = File.expand_path(directory_path)
        Rails.logger.info "Expanded directory path: #{directory_path}"

        if File.directory?(directory_path)
          @directory_contents = AudioFile.parse_directory(directory_path)
          @audio_files = AudioFile.all
          flash[:notice] = "Successfully scanned directory: #{directory_path}"
          Rails.logger.info "Successfully scanned directory: #{directory_path}"
        else
          flash[:alert] = "Please select a valid directory"
          Rails.logger.error "Invalid directory path provided: #{directory_path}"
        end
      rescue => e
        flash[:alert] = "Error scanning directory: #{e.message}"
        Rails.logger.error "Error scanning directory: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    else
      flash[:alert] = "Please select a directory to scan"
      Rails.logger.error "No directory selected"
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
