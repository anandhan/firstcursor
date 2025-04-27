#!/usr/bin/env ruby

require 'taglib'
require 'mp3info'
require 'wavefile'
require 'pathname'
require_relative 'audio_metadata'
require 'parallel'
require 'timeout'
require 'mini_exiftool'

class FileParser
  attr_reader :files

  def initialize(options = {})
    @options = {
      file_pattern: /\.(mp3|wav|flac)$/i,
      exclude_dirs: ['.', '..', '.git', 'node_modules'],
      verbose: true,
      max_workers: 4,  # Number of parallel workers
      extract_cover_art: true,  # Whether to extract cover art
      metadata_timeout: 5,  # Timeout for metadata extraction
      duration_timeout: 5   # Timeout for duration extraction
    }.merge(options)
    
    @files = []
    @processed_files = 0
    @successful_files = 0
  end

  def parse_directory(directory_path)
    unless File.directory?(directory_path)
      puts "Error: #{directory_path} is not a valid directory"
      return
    end

    # First, collect all audio files
    audio_files = collect_audio_files(directory_path)
    puts "Found #{audio_files.size} audio files to process"

    # Process files in parallel
    results = Parallel.map(audio_files, in_processes: @options[:max_workers]) do |file_path|
      process_audio_file(file_path)
    end

    # Filter out nil results and add to @files
    @files = results.compact
    puts "Successfully processed #{@files.size} files"
  end

  private

  def collect_audio_files(directory_path)
    audio_files = []
    Dir.foreach(directory_path) do |entry|
      next if @options[:exclude_dirs].include?(entry)
      
      full_path = File.join(directory_path, entry)
      
      if File.directory?(full_path)
        audio_files.concat(collect_audio_files(full_path))
      elsif File.file?(full_path) && entry.match(@options[:file_pattern])
        audio_files << full_path
      end
    end
    audio_files
  end

  def process_audio_file(file_path)
    return unless File.file?(file_path)
    
    begin
      file_name = File.basename(file_path)
      puts "\nProcessing: #{file_name}"
      
      # Get file size in MB
      size_mb = File.size(file_path).to_f / (1024 * 1024)
      puts "File size: #{'%.2f' % size_mb} MB"
      
      # Extract metadata with timeout
      metadata = nil
      begin
        Timeout.timeout(@options[:metadata_timeout]) do
          metadata = AudioMetadata.extract(file_path, 
            extract_cover_art: @options[:extract_cover_art],
            timeout: @options[:metadata_timeout]
          )
        end
      rescue Timeout::Error
        puts "  Warning: Metadata extraction timed out for #{file_name}"
        metadata = {}
      end
      
      # Get duration from metadata or extract it
      duration = metadata[:duration]
      if duration.nil?
        begin
          Timeout.timeout(@options[:duration_timeout]) do
            duration = get_duration(file_path)
          end
        rescue Timeout::Error
          puts "  Warning: Duration extraction timed out for #{file_name}"
        end
      end
      
      file_info = {
        path: file_path,
        size: "#{'%.2f' % size_mb} MB",
        type: File.extname(file_path).upcase[1..-1],
        duration: duration,
        metadata: metadata || {}
      }
      
      puts "Successfully processed: #{file_name}"
      file_info
      
    rescue => e
      puts "  Error processing #{file_path}: #{e.message}"
      puts e.backtrace.join("\n")
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
    begin
      Mp3Info.open(file_path) do |mp3|
        mp3.length
      end
    rescue => e
      puts "  Warning: Could not get MP3 duration: #{e.message}"
      nil
    end
  end

  def get_wav_duration(file_path)
    begin
      reader = WaveFile::Reader.new(file_path)
      reader.total_duration.seconds
    rescue => e
      puts "  Warning: Could not get WAV duration: #{e.message}"
      nil
    end
  end

  def get_flac_duration(file_path)
    begin
      exif = MiniExiftool.new(file_path)
      exif.duration
    rescue => e
      puts "  Warning: Could not get FLAC duration: #{e.message}"
      nil
    end
  end

  def format_file_size(bytes)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    size = bytes.to_f
    unit = 0
    
    while size >= 1024 && unit < units.size - 1
      size /= 1024
      unit += 1
    end
    
    "#{size.round(2)} #{units[unit]}"
  end

  def format_duration(seconds)
    return "Unknown" if seconds.nil?
    
    hours = (seconds / 3600).floor
    minutes = ((seconds % 3600) / 60).floor
    seconds = (seconds % 60).floor
    
    if hours > 0
      format("%02d:%02d:%02d", hours, minutes, seconds)
    else
      format("%02d:%02d", minutes, seconds)
    end
  end
end

# Interactive prompt for directory path
def get_directory_path
  puts "\nAudio File Parser"
  puts "-----------------"
  puts "Please enter the path to your music directory:"
  print "> "
  
  path = gets.chomp
  
  # Expand home directory shortcut (~)
  path = File.expand_path(path)
  
  until File.directory?(path)
    puts "\nError: '#{path}' is not a valid directory."
    puts "Please enter a valid directory path:"
    print "> "
    path = File.expand_path(gets.chomp)
  end
  
  path
end

# Main execution
if __FILE__ == $0
  puts "\nAudio File Parser"
  puts "-----------------"
  puts "1. Scan and display file information"
  puts "2. Update metadata for files"
  print "\nSelect an option (1 or 2): "
  
  option = gets.chomp
  
  case option
  when "1"
    directory_path = get_directory_path
    parser = FileParser.new
    
    puts "\nScanning directory: #{directory_path}"
    puts "This may take a while depending on the number of files..."
    puts "\nFound audio files:"
    
    processed_files = 0
    successful_files = 0
    
    parser.parse_directory(directory_path) do |file_info|
      processed_files += 1
      puts "\nFile ##{processed_files}:"
      puts "Path: #{file_info[:path]}"
      puts "Size: #{file_info[:size]}"
      puts "Type: #{file_info[:type]}"
      puts "Duration: #{file_info[:duration]}"
      
      if file_info[:metadata].any? { |_, v| !v.nil? && !v.empty? }
        puts "\nMetadata:"
        file_info[:metadata].each do |key, value|
          puts "#{key.capitalize}: #{value}" unless value.nil? || value.empty?
        end
      end
      puts "---"
      successful_files += 1
    end
    
    puts "\nScan complete!"
    puts "Total files processed: #{processed_files}"
    puts "Successfully processed: #{successful_files}"
    
  when "2"
    directory_path = get_directory_path
    parser = FileParser.new
    
    puts "\nEnter the metadata you want to set for all files in the directory."
    puts "Leave fields empty to keep their current values."
    metadata = AudioMetadata.prompt_for_metadata
    
    if metadata.empty?
      puts "\nNo metadata provided. Exiting..."
      exit
    end
    
    puts "\nUpdating metadata for files in: #{directory_path}"
    puts "This may take a while depending on the number of files..."
    
    updated_files = 0
    failed_files = 0
    
    parser.parse_directory(directory_path) do |file_info|
      if AudioMetadata.set(file_info[:path], metadata)
        updated_files += 1
      else
        failed_files += 1
      end
    end
    
    puts "\nUpdate complete!"
    puts "Successfully updated: #{updated_files} files"
    puts "Failed to update: #{failed_files} files"
    
  else
    puts "Invalid option. Please run the script again and select 1 or 2."
  end
end 