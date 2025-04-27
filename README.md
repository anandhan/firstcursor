# Audio File Parser Web

A Ruby on Rails web application for parsing and analyzing audio files (MP3 and WAV formats). This application allows users to scan directories for audio files, view their metadata, and analyze their properties.

## Features

- Scan directories for audio files (MP3 and WAV formats)
- Display file information including:
  - File name and path
  - File size
  - File type
  - Duration
  - Metadata (for MP3 files)
  - Technical details (for WAV files)
- Modern, responsive web interface
- Real-time processing feedback

## Dependencies

- Ruby 3.1.3
- Rails 7.1.5
- [ruby-mp3info](https://github.com/moumar/ruby-mp3info) - For MP3 file metadata and duration
- [wavefile](https://github.com/jstrait/wavefile) - For WAV file analysis
- SQLite3 (development database)
- Redis (for Action Cable in production)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/anandhan/firstcursor.git
   cd firstcursor/audio_file_parser_web
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Start the Rails server:
   ```bash
   bin/rails server
   ```

4. Access the application at `http://localhost:3000`

## Usage

1. Enter the path to a directory containing audio files
2. Click "Parse Directory" to scan for audio files
3. View the results in the table below, which shows:
   - File information
   - Duration
   - Metadata (for MP3 files)
   - Technical details (for WAV files)

## File Support

### MP3 Files
- Extracts ID3 tags (title, artist, album, year, genre, comments)
- Calculates duration
- Supports metadata updates

### WAV Files
- Extracts technical information:
  - Number of channels
  - Sample rate
  - Bits per sample
  - Duration
- Note: WAV files do not support embedded metadata

## Development

### Running Tests
```bash
bin/rails test
```

### Code Style
The project follows standard Ruby and Rails conventions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
