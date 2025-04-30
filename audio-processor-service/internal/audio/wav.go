package audio

import (
	"os"

	"github.com/anandhan/firstcursor/audio-processor-service/internal/models"
	"github.com/sirupsen/logrus"
	"github.com/mjibson/go-dsp/wav"
)

type WAVHandler struct {
	logger *logrus.Logger
}

func NewWAVHandler(logger *logrus.Logger) *WAVHandler {
	return &WAVHandler{
		logger: logger,
	}
}

func (h *WAVHandler) ExtractMetadata(filePath string) (*models.AudioMetadata, error) {
	h.logger.Infof("Extracting WAV metadata from: %s", filePath)

	// Open the WAV file
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Read WAV file
	wavFile, err := wav.New(file)
	if err != nil {
		return nil, err
	}

	// Create metadata struct
	metadata := &models.AudioMetadata{
		Duration:   float64(wavFile.Duration),
		SampleRate: wavFile.SampleRate,
		Channels:   wavFile.Channels,
		BitRate:    wavFile.SampleRate * wavFile.BitsPerSample * wavFile.Channels,
	}

	return metadata, nil
} 