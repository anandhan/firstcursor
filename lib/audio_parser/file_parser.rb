#!/usr/bin/env ruby

require 'mp3info'
require 'wavefile'
require 'pathname'
require_relative 'audio_metadata'

module AudioParser
  class FileParser
    def initialize(options = {})
      @options = {
        # Common audio file extensions
        file_pattern: /\.(mp3|wav)$/i,  # Case insensitive match, only MP3 and WAV supported
        exclude_dirs: ['.', '..', '.git', 'node_modules'],
        exclude_files: [/^\._/],  # Exclude macOS metadata files
        verbose: true  # Always show verbose output for better debugging
      }.merge(options)
      
      @processed_files = 0
      @successful_files = 0
    end

    def parse_directory(directory_path, &block)
      unless File.directory?(directory_path)
        puts "Error: #{directory_path} is not a valid directory"
        return
      end

      process_directory(directory_path, &block)
    end

    private

    def process_directory(directory_path, &block)
      Dir.foreach(directory_path) do |entry|
        # Skip excluded directories and files
        next if @options[:exclude_dirs].include?(entry)
        next if @options[:exclude_files].any? { |pattern| entry.match(pattern) }

        full_path = File.join(directory_path, entry)
        
        if File.directory?(full_path)
          process_directory(full_path, &block)
        elsif File.file?(full_path) && entry.match(@options[:file_pattern])
          @processed_files += 1
          if process_audio_file(full_path, &block)
            @successful_files += 1
          end
        end
      end
    end

    def process_audio_file(file_path, &block)
      success = false
      begin
        file_size = File.size(file_path)
        file_extension = File.extname(file_path).downcase
        
        puts "\nProcessing: #{File.basename(file_path)}"
        puts "File size: #{format_file_size(file_size)}"
        
        # Get audio metadata and duration
        metadata = AudioParser::AudioMetadata.extract(file_path)
        duration = get_audio_duration(file_path)
        
        # Format the output
        output = {
          path: file_path,
          size: format_file_size(file_size),
          type: file_extension,
          duration: format_duration(duration),
          metadata: metadata || {}
        }
        
        # Always yield the output
        block.call(output) if block_given?
        success = true
        
        puts "Successfully processed: #{File.basename(file_path)}"
      rescue => e
        puts "Error processing #{File.basename(file_path)}: #{e.message}"
        puts e.backtrace.join("\n")
      end
      success
    end

    def get_audio_duration(file_path)
      case File.extname(file_path).downcase
      when '.mp3'
        get_mp3_duration(file_path)
      when '.wav'
        get_wav_duration(file_path)
      else
        puts "  Warning: Unsupported file format for duration extraction"
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
        duration = reader.total_duration.seconds
        reader.close
        duration
      rescue => e
        puts "  Warning: Could not get WAV duration: #{e.message}"
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
    parser = AudioParser::FileParser.new
    
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
    parser = AudioParser::FileParser.new
    
    puts "\nEnter the metadata you want to set for all files in the directory."
    puts "Leave fields empty to keep their current values."
    metadata = AudioParser::AudioMetadata.prompt_for_metadata
    
    if metadata.empty?
      puts "\nNo metadata provided. Exiting..."
      exit
    end
    
    puts "\nUpdating metadata for files in: #{directory_path}"
    puts "This may take a while depending on the number of files..."
    
    updated_files = 0
    failed_files = 0
    
    parser.parse_directory(directory_path) do |file_info|
      if AudioParser::AudioMetadata.set(file_info[:path], metadata)
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