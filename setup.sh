#!/bin/bash

# FURG Setup Script
# Quick setup for development environment

set -e  # Exit on error

echo "🚀 FURG Setup Script"
echo "===================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.11+"
    exit 1
fi
echo "✅ Python 3 found: $(python3 --version)"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker not found. Docker is recommended but optional."
    echo "   Install from: https://docker.com"
else
    echo "✅ Docker found: $(docker --version)"
fi

# Check for PostgreSQL (if not using Docker)
if ! command -v psql &> /dev/null; then
    echo "⚠️  PostgreSQL not found. You'll need Docker or PostgreSQL installed."
else
    echo "✅ PostgreSQL found: $(psql --version)"
fi

echo ""
echo "Setting up backend..."

# Navigate to backend directory
cd backend

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Dependencies installed"

# Setup environment file
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit backend/.env with your API keys:"
    echo "   - ANTHROPIC_API_KEY (get from https://console.anthropic.com/)"
    echo "   - PLAID_CLIENT_ID and PLAID_SECRET (get from https://plaid.com/)"
    echo "   - JWT_SECRET (generate with: python -c \"import secrets; print(secrets.token_urlsafe(32))\")"
    echo ""
else
    echo "✅ .env file already exists"
fi

# Go back to root
cd ..

echo ""
echo "Database setup..."
read -p "Do you want to use Docker for PostgreSQL? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v docker-compose &> /dev/null; then
        echo "Starting PostgreSQL with Docker Compose..."
        docker-compose up -d postgres
        echo "✅ PostgreSQL started"
        echo "Waiting for database to be ready..."
        sleep 5
        echo "✅ Database ready"
    else
        echo "❌ docker-compose not found. Please install Docker Compose."
        exit 1
    fi
else
    echo "Make sure PostgreSQL is running and create the database:"
    echo "  createdb frugal_ai"
    echo "  psql frugal_ai < database/schema.sql"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit backend/.env with your API keys"
echo "2. Start the backend:"
echo "   cd backend"
echo "   source venv/bin/activate"
echo "   python main.py"
echo ""
echo "3. Visit http://localhost:8000/docs for API documentation"
echo ""
echo "For Docker users:"
echo "   docker-compose up -d"
echo ""
echo "Happy roasting! 🔥"
