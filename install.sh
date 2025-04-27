#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[x] $1${NC}"
}

# Check if Ruby is installed
print_status "Checking Ruby installation..."
if ! command -v ruby &> /dev/null; then
    print_error "Ruby is not installed. Please install Ruby 3.1.3 or higher."
    exit 1
fi

# Check Ruby version
RUBY_VERSION=$(ruby -v | cut -d' ' -f2)
if [[ "$RUBY_VERSION" < "3.1.3" ]]; then
    print_warning "Ruby version $RUBY_VERSION is lower than recommended 3.1.3"
    print_warning "The application might not work as expected."
fi

# Check if Bundler is installed
print_status "Checking Bundler installation..."
if ! command -v bundle &> /dev/null; then
    print_status "Installing Bundler..."
    gem install bundler
fi

# Check if Redis is installed (for production)
print_status "Checking Redis installation..."
if ! command -v redis-server &> /dev/null; then
    print_warning "Redis is not installed. It's required for production mode."
    print_warning "For development, you can continue without Redis."
fi

# Install dependencies
print_status "Installing dependencies..."
bundle install

if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies. Please check the error messages above."
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p log tmp/pids

# Set up the database (if needed)
print_status "Setting up the database..."
bin/rails db:create db:migrate

# Start the server
print_status "Starting the Rails server..."
print_status "The application will be available at http://localhost:3000"
print_status "Press Ctrl+C to stop the server"

# Start the server in development mode
bin/rails server -b 0.0.0.0

# If you want to start in production mode, uncomment the following line:
# RAILS_ENV=production bin/rails server -b 0.0.0.0 