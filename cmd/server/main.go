package main

import (
	"net/http"
	"os"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
)

var log = logrus.New()

func main() {
	// Configure logging
	log.SetFormatter(&logrus.JSONFormatter{})
	log.SetOutput(os.Stdout)
	log.SetLevel(logrus.InfoLevel)

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize router
	router := mux.NewRouter()

	// Health check endpoint
	router.HandleFunc("/health", healthCheck).Methods("GET")

	// Audio processing endpoints
	router.HandleFunc("/api/v1/audio/metadata", extractMetadata).Methods("POST")
	router.HandleFunc("/api/v1/audio/cover-art", extractCoverArt).Methods("POST")

	// Start server
	log.Infof("Server starting on port %s", port)
	if err := http.ListenAndServe(":"+port, router); err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status": "healthy"}`))
}

func extractMetadata(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement metadata extraction
	w.WriteHeader(http.StatusNotImplemented)
}

func extractCoverArt(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement cover art extraction
	w.WriteHeader(http.StatusNotImplemented)
} 