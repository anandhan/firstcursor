package services

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/anandhan/firstcursor/audio-processor-service/internal/audio"
	"github.com/anandhan/firstcursor/audio-processor-service/internal/models"
	"github.com/sirupsen/logrus"
)

type AudioService struct {
	logger     *logrus.Logger
	wavHandler *audio.WAVHandler
}

func NewAudioService(logger *logrus.Logger) *AudioService {
	return &AudioService{
		logger:     logger,
		wavHandler: audio.NewWAVHandler(logger),
	}
}

// ExtractMetadata extracts metadata from an audio file
func (s *AudioService) ExtractMetadata(filePath string) (*models.AudioMetadata, error) {
	s.logger.Infof("Processing file: %s", filePath)

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return nil, err
	}

	// Get file extension
	ext := strings.ToLower(filepath.Ext(filePath))

	// Extract metadata based on file type
	switch ext {
	case ".mp3":
		// TODO: Implement MP3 metadata extraction
		s.logger.Info("MP3 metadata extraction not implemented yet")
	case ".wav":
		return s.wavHandler.ExtractMetadata(filePath)
	case ".flac":
		// TODO: Implement FLAC metadata extraction
		s.logger.Info("FLAC metadata extraction not implemented yet")
	case ".m4a":
		// TODO: Implement M4A metadata extraction
		s.logger.Info("M4A metadata extraction not implemented yet")
	case ".ogg":
		// TODO: Implement OGG metadata extraction
		s.logger.Info("OGG metadata extraction not implemented yet")
	default:
		s.logger.Warnf("Unsupported file type: %s", ext)
		return nil, nil
	}

	return nil, nil
}

// ExtractCoverArt extracts cover art from an audio file
func (s *AudioService) ExtractCoverArt(filePath string) (*models.CoverArt, error) {
	s.logger.Infof("Extracting cover art from: %s", filePath)

	// TODO: Implement cover art extraction
	s.logger.Info("Cover art extraction not implemented yet")
	return nil, nil
} 