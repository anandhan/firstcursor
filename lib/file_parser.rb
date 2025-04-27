require 'parallel'
require 'timeout'
require 'mini_exiftool'
require_relative 'audio_parser/audio_metadata'

class FileParser
  attr_reader :files

  def initialize(options = {})
    @options = {
      file_pattern: ['*.mp3', '*.wav', '*.flac'],
      exclude_dirs: ['.', '..', '.git', 'node_modules', 'vendor', 'tmp', 'log'],
      max_workers: 4,
      extract_cover_art: true,
      metadata_timeout: 5,
      duration_timeout: 5
    }.merge(options)
    @logger = Rails.logger
    @files = []
  end

  def parse_directory(directory_path)
    @logger.info "Starting to parse directory: #{directory_path}"
    @logger.debug "File patterns: #{@options[:file_pattern].inspect}"
    @logger.debug "Excluded directories: #{@options[:exclude_dirs].inspect}"

    @files = []
    collect_audio_files(directory_path)
    @logger.info "Found #{@files.size} files, processing..."
    results = process_files_in_parallel
    @logger.info "Finished processing #{results.compact.size} files successfully"
    results.compact
  end

  private

  def collect_audio_files(directory_path)
    @logger.debug "Scanning directory: #{directory_path}"
    files = Dir.glob(File.join(directory_path, '**', '*'))
    @logger.debug "Dir.glob found #{files.size} total files"
    
    files.each do |file|
      @logger.debug "Examining file: #{file}"
      
      if File.directory?(file)
        @logger.debug "Skipping directory: #{file}"
        next
      end
      
      # Check if the file is in an excluded directory by comparing path components
      path_components = Pathname.new(file).each_filename.to_a
      if path_components.any? { |component| @options[:exclude_dirs].include?(component) }
        @logger.debug "Skipping file in excluded directory: #{file}"
        next
      end
      
      basename = File.basename(file)
      @logger.debug "Checking if #{basename} matches any pattern in #{@options[:file_pattern].inspect}"
      
      if @options[:file_pattern].any? { |pattern| File.fnmatch(pattern, basename, File::FNM_CASEFOLD) }
        @logger.debug "Found audio file: #{file}"
        @files << file
      else
        @logger.debug "File does not match any pattern: #{file}"
      end
    end
    
    @logger.debug "Found #{@files.size} audio files in directory"
  end

  def process_files_in_parallel
    Parallel.map(@files, in_threads: @options[:max_workers]) do |file_path|
      begin
        @logger.debug "Processing file: #{file_path}"
        result = process_audio_file(file_path)
        @logger.debug "Successfully processed: #{file_path}" if result
        result
      rescue => e
        @logger.error "Error processing #{file_path}: #{e.message}"
        @logger.error e.backtrace.join("\n")
        nil
      end
    end
  end

  def process_audio_file(file_path)
    begin
      size = File.size(file_path)
      metadata = AudioMetadata.extract(file_path)
      duration = get_duration(file_path)

      {
        path: file_path,
        size: size,
        metadata: metadata,
        duration: duration
      }
    rescue => e
      @logger.error "Error processing #{file_path}: #{e.message}"
      @logger.error e.backtrace.join("\n")
      nil
    end
  end

  def get_duration(file_path)
    case File.extname(file_path).downcase
    when '.mp3'
      get_mp3_duration(file_path)
    when '.wav'
      get_wav_duration(file_path)
    when '.flac'
      get_flac_duration(file_path)
    else
      nil
    end
  end

  def get_mp3_duration(file_path)
    Mp3Info.open(file_path) do |mp3|
      mp3.length
    end
  rescue => e
    @logger.error "Error getting MP3 duration: #{e.message}"
    nil
  end

  def get_wav_duration(file_path)
    WaveFile::Reader.info(file_path).duration.seconds
  rescue => e
    @logger.error "Error getting WAV duration: #{e.message}"
    nil
  end

  def get_flac_duration(file_path)
    # TODO: Implement FLAC duration extraction
    nil
  end
end 