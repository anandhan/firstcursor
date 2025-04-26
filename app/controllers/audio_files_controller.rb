class AudioFilesController < ApplicationController
  require_relative '../../lib/audio_parser/file_parser'
  require_relative '../../lib/audio_parser/audio_metadata'

  def index
  end

  def parse
    @parser = FileParser.new
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

  def update_metadata
    directory_path = params[:directory_path]
    metadata = {
      title: params[:title],
      artist: params[:artist],
      album: params[:album],
      year: params[:year],
      genre: params[:genre],
      comment: params[:comment]
    }.compact

    if directory_path.blank?
      flash[:error] = "Please provide a directory path"
      redirect_to audio_files_path and return
    end

    if metadata.empty?
      flash[:error] = "Please provide at least one metadata field to update"
      redirect_to audio_files_path and return
    end

    begin
      parser = FileParser.new
      updated_files = 0
      failed_files = 0

      parser.parse_directory(directory_path) do |file_info|
        if AudioMetadata.set(file_info[:path], metadata)
          updated_files += 1
        else
          failed_files += 1
        end
      end

      flash[:notice] = "Updated #{updated_files} files. Failed to update #{failed_files} files."
    rescue => e
      flash[:error] = "Error updating metadata: #{e.message}"
    end

    redirect_to audio_files_path
  end
end 