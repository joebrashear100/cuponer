#!/bin/bash

# FURG Backend Test Runner
# Run with: ./run_tests.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  FURG Backend Test Suite${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install -q -r requirements.txt

# Set test environment variables
export DEBUG=true
export JWT_SECRET="test-secret-key-for-testing-only-32chars"
export DATABASE_URL="postgresql://test:test@localhost:5432/test_db"

# Parse command line arguments
COVERAGE=""
VERBOSE=""
MARKERS=""
SPECIFIC_TEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage|-c)
            COVERAGE="--cov=. --cov-report=html --cov-report=term-missing"
            shift
            ;;
        --verbose|-v)
            VERBOSE="-v"
            shift
            ;;
        --unit)
            MARKERS="-m unit"
            shift
            ;;
        --integration)
            MARKERS="-m integration"
            shift
            ;;
        --auth)
            SPECIFIC_TEST="tests/test_auth.py"
            shift
            ;;
        --api)
            SPECIFIC_TEST="tests/test_api_endpoints.py"
            shift
            ;;
        --db)
            SPECIFIC_TEST="tests/test_database.py"
            shift
            ;;
        --services)
            SPECIFIC_TEST="tests/test_services.py"
            shift
            ;;
        --rate-limiter)
            SPECIFIC_TEST="tests/test_rate_limiter.py"
            shift
            ;;
        --help|-h)
            echo ""
            echo "Usage: ./run_tests.sh [options]"
            echo ""
            echo "Options:"
            echo "  --coverage, -c     Run with coverage report"
            echo "  --verbose, -v      Verbose output"
            echo "  --unit             Run only unit tests"
            echo "  --integration      Run only integration tests"
            echo "  --auth             Run only auth tests"
            echo "  --api              Run only API endpoint tests"
            echo "  --db               Run only database tests"
            echo "  --services         Run only service layer tests"
            echo "  --rate-limiter     Run only rate limiter tests"
            echo "  --help, -h         Show this help message"
            echo ""
            exit 0
            ;;
        *)
            SPECIFIC_TEST="$1"
            shift
            ;;
    esac
done

# Run tests
echo ""
echo -e "${GREEN}Running tests...${NC}"
echo ""

if [ -n "$SPECIFIC_TEST" ]; then
    pytest $SPECIFIC_TEST $VERBOSE $COVERAGE $MARKERS
else
    pytest tests/ $VERBOSE $COVERAGE $MARKERS
fi

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  All tests passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  Some tests failed${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi

# Show coverage report location if generated
if [ -n "$COVERAGE" ]; then
    echo ""
    echo -e "${YELLOW}Coverage report generated: htmlcov/index.html${NC}"
fi
