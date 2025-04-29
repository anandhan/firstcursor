#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[STATUS]${NC} $1"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    print_error "Ruby is not installed. Please install Ruby 3.1.3 or higher."
    exit 1
fi

# Check Ruby version
RUBY_VERSION=$(ruby -v | cut -d' ' -f2)
if [[ "$RUBY_VERSION" < "3.1.3" ]]; then
    print_warning "Ruby version $RUBY_VERSION is lower than recommended (3.1.3). Some features may not work correctly."
fi

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
    print_status "Installing Bundler..."
    gem install bundler
fi

# Check if exiftool is installed
if ! command -v exiftool &> /dev/null; then
    print_warning "exiftool is not installed. Cover art extraction may be limited."
    print_warning "Please install exiftool using your package manager:"
    print_warning "  - macOS: brew install exiftool"
    print_warning "  - Ubuntu/Debian: sudo apt-get install libimage-exiftool-perl"
    print_warning "  - Fedora: sudo dnf install perl-Image-ExifTool"
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    print_warning "ffmpeg is not installed. Cover art extraction will not work."
    print_warning "Please install ffmpeg using your package manager:"
    print_warning "  - macOS: brew install ffmpeg"
    print_warning "  - Ubuntu/Debian: sudo apt-get install ffmpeg"
    print_warning "  - Fedora: sudo dnf install ffmpeg"
fi

# Check if Redis is installed (optional)
if ! command -v redis-cli &> /dev/null; then
    print_warning "Redis is not installed. Background processing will be disabled."
    print_warning "Please install Redis for optimal performance:"
    print_warning "  - macOS: brew install redis"
    print_warning "  - Ubuntu/Debian: sudo apt-get install redis-server"
    print_warning "  - Fedora: sudo dnf install redis"
fi

# Install dependencies
print_status "Installing dependencies..."
bundle install

if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies. Please check the error messages above."
    exit 1
fi

# Create necessary directories
print_status "Creating required directories..."
mkdir -p log tmp/pids

# Set up the database
print_status "Setting up the database..."
bin/rails db:create db:migrate

if [ $? -ne 0 ]; then
    print_error "Failed to set up the database. Please check the error messages above."
    exit 1
fi

print_status "Installation completed successfully!"
print_status "To start the application, run:"
print_status "  bin/rails server"
print_status ""
print_status "Then open your browser and navigate to:"
print_status "  http://localhost:3000" 