# Audio Processor Service

This is the backend service for audio file processing, written in Go. It provides HTTP endpoints for extracting metadata and cover art from audio files.

## Prerequisites

1. Install Go (1.21 or later):
   - macOS: `brew install go`
   - Linux: `sudo apt-get install golang`
   - Windows: Download from https://golang.org/dl/

## Project Structure

```
audio-processor-service/
├── cmd/
│   └── server/
│       └── main.go         # Entry point
├── internal/
│   ├── api/               # HTTP handlers
│   ├── processor/         # Audio processing logic
│   └── models/            # Data models
├── pkg/                   # Public packages
├── go.mod                # Go module file
└── README.md             # This file
```

## Setup

1. Install dependencies:
```bash
go mod tidy
```

2. Run the server:
```bash
go run cmd/server/main.go
```

## API Endpoints

### GET /health
Health check endpoint

### POST /api/v1/audio/metadata
Extract metadata from audio file

### POST /api/v1/audio/cover-art
Extract cover art from audio file

## Integration with Rails Frontend

Add the following environment variables to your Rails application:
```
AUDIO_PROCESSOR_URL=http://localhost:8080
``` 