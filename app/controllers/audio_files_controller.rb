class AudioFilesController < ApplicationController
  def index
    @audio_files = AudioFile.all
    Rails.logger.info "User accessed audio files index page"
  end

  def parse
    directory_path = params[:directory_path]
    Rails.logger.info "User attempted to parse directory: #{directory_path}"
    
    if directory_path.present?
      begin
        if Dir.exist?(directory_path)
          Rails.logger.info "Directory exists, starting parse process"
          AudioFile.parse_directory(directory_path)
          flash[:notice] = "Directory parsed successfully!"
          Rails.logger.info "Directory parsed successfully: #{directory_path}"
        else
          flash[:alert] = "Directory not found: #{directory_path}"
          Rails.logger.error "Directory not found: #{directory_path}"
        end
      rescue => e
        flash[:alert] = "Error parsing directory: #{e.message}"
        Rails.logger.error "Error parsing directory: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    else
      flash[:alert] = "Please provide a directory path"
      Rails.logger.warn "User submitted empty directory path"
    end
    redirect_to audio_files_path
  end

  def update_metadata
    @audio_file = AudioFile.find(params[:id])
    Rails.logger.info "User requested metadata update for file: #{@audio_file.filename}"
    
    if @audio_file.update_metadata
      flash[:notice] = "Metadata updated successfully!"
      Rails.logger.info "Metadata updated successfully for file: #{@audio_file.filename}"
    else
      flash[:alert] = "Error updating metadata"
      Rails.logger.error "Failed to update metadata for file: #{@audio_file.filename}"
    end
    redirect_to audio_files_path
  end
end
