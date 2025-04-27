# Audio File Parser Web

A web application for parsing and managing audio file metadata, supporting MP3, WAV, and FLAC formats.

## Features

- Parse audio files from any directory
- Extract metadata including:
  - Title, Artist, Album, Year, Genre, Comments
  - Technical details (channels, sample rate, bit depth)
  - Duration
  - File size
- Extract and display cover art (for MP3 and WAV files)
- Update metadata for supported formats
- Modern, responsive web interface

## Supported Formats

- MP3 files (using ruby-mp3info)
- WAV files (using wavefile)
- FLAC files (using mini_exiftool)

## Requirements

- Ruby 3.1.3 or higher
- Bundler
- ffmpeg (for cover art extraction)
- Redis (optional, for background processing)

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd audio_file_parser_web
   ```

2. Run the installation script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

The installation script will:
- Check for required dependencies
- Install Ruby gems
- Set up the database
- Start the Rails server

## Usage

1. Start the application:
   ```bash
   bin/rails server
   ```

2. Open your browser and navigate to:
   ```
   http://localhost:3000
   ```

3. Enter a directory path containing audio files and click "Parse Directory"

4. View and manage your audio files' metadata

## Development

- The application uses Rails 7.1.5.1
- Main components:
  - `AudioMetadata` class for metadata extraction
  - `FileParser` class for directory scanning
  - Modern UI with Tailwind CSS

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
