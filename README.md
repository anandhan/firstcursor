# Audio File Parser Web Application

A Ruby on Rails web application for parsing and managing audio file metadata. The application allows users to scan directories for audio files, extract their metadata, and manage cover art.

## Features

- Directory scanning for audio files (supports .mp3, .m4a, .wav, .flac, .ogg)
- Metadata extraction including:
  - Title
  - Artist
  - Album
  - Year
  - Genre
  - Composer
- Cover art extraction and management
- Directory contents listing
- File type detection and categorization
- File size display
- Modern, responsive UI with Bootstrap

## Prerequisites

- Ruby 3.1.3 or higher
- Rails 7.2.2 or higher
- SQLite3
- ExifTool (for metadata extraction)

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd audio_file_parser_web
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Install ExifTool (required for metadata extraction):
   ```bash
   # On macOS
   brew install exiftool
   
   # On Ubuntu/Debian
   sudo apt-get install libimage-exiftool-perl
   ```

4. Set up the database:
   ```bash
   rails db:create db:migrate
   ```

5. Start the Rails server:
   ```bash
   rails server
   ```

6. Open your browser and navigate to `http://localhost:3000`

## Usage

1. **Directory Selection**
   - Click the "Browse" button to select a directory containing audio files
   - The application will display the selected directory path
   - Click "Parse Directory" to scan the directory

2. **Directory Contents**
   - The application will display all files and subdirectories
   - Files are categorized by type with appropriate icons
   - File sizes are displayed in human-readable format

3. **Audio Files**
   - Audio files are displayed in a grid layout
   - Each file shows:
     - Cover art (if available)
     - Title (or filename if no title metadata)
     - Artist
     - Album
     - Year
     - Genre
     - Composer
   - Click "Update Metadata" to refresh the metadata for a specific file

## Technical Details

- Uses `mini_exiftool` gem for metadata extraction
- Implements custom directory scanning with file type detection
- Handles various audio file formats
- Provides detailed logging for debugging
- Implements error handling for invalid paths and file processing

## Development

- The application is built with Ruby on Rails 7.2.2
- Uses Bootstrap 5 for styling
- Implements responsive design for various screen sizes
- Includes comprehensive logging for debugging

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
