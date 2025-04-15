# Audio File Parser

A Ruby script to recursively parse and analyze audio files in a directory. The script provides detailed information about audio files including metadata, duration, and technical specifications.

## Features

- Recursively scans directories for audio files
- Supports multiple audio formats (WAV, MP3, AAC, FLAC, OGG, M4A, WMA, AIFF, ALAC)
- Extracts audio metadata (title, artist, album, year, genre)
- Provides technical details (channels, sample rate, bit depth)
- Shows file size and duration
- Handles macOS metadata files
- Interactive directory selection

## Requirements

- Ruby 2.7 or higher
- Bundler

## Installation

1. Clone the repository:
```bash
git clone <your-repository-url>
cd audio-file-parser
```

2. Install dependencies:
```bash
bundle install
```

## Usage

Run the script:
```bash
ruby file_parser.rb
```

The script will prompt you to enter the path to your music directory. You can use:
- Full path: `/Users/username/Music`
- Home directory shortcut: `~/Music`
- Relative path: `./music`

## Example Output

```
Processing: song.wav
File size: 77.65 MB
WAV format: 2 channels, 48000 Hz, 24 bits per sample
Duration: 03:45
```

## License

MIT License 