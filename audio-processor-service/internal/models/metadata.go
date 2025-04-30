package models

// AudioMetadata represents the metadata extracted from an audio file
type AudioMetadata struct {
	Title      string      `json:"title,omitempty"`
	Artist     string      `json:"artist,omitempty"`
	Album      string      `json:"album,omitempty"`
	Year       string      `json:"year,omitempty"`
	Genre      string      `json:"genre,omitempty"`
	Duration   float64     `json:"duration,omitempty"`
	BitRate    int         `json:"bitrate,omitempty"`
	SampleRate int         `json:"sample_rate,omitempty"`
	Channels   int         `json:"channels,omitempty"`
	CoverArt   *CoverArt  `json:"cover_art,omitempty"`
}

// CoverArt represents the cover art data extracted from an audio file
type CoverArt struct {
	Data     string `json:"data"`      // Base64 encoded image data
	MimeType string `json:"mime_type"` // MIME type of the image
} 