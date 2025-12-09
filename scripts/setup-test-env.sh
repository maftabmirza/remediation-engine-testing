#!/bin/bash

# setup-test-env.sh - Initialize testing environment
# Usage: ./scripts/setup-test-env.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Setting Up Test Environment ===${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Python
if ! command -v python3.12 &> /dev/null && ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3.12+ not found. Please install Python first.${NC}"
    exit 1
fi
PYTHON_CMD=$(command -v python3.12 || command -v python3)
echo -e "${GREEN}✓ Python found: $($PYTHON_CMD --version)${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found. Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found: $(docker --version)${NC}"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose not found. Please install Docker Compose first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found${NC}"

echo ""

# Create virtual environment
echo -e "${YELLOW}Creating virtual environment...${NC}"
if [ ! -d ".venv" ]; then
    $PYTHON_CMD -m venv .venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${YELLOW}  Virtual environment already exists${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source .venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --quiet --upgrade pip setuptools wheel
echo -e "${GREEN}✓ pip upgraded${NC}"

# Install dependencies
echo -e "${YELLOW}Installing test dependencies...${NC}"
if [ -f "requirements-test.txt" ]; then
    pip install --quiet -r requirements-test.txt
    echo -e "${GREEN}✓ Test dependencies installed${NC}"
else
    echo -e "${RED}requirements-test.txt not found${NC}"
    exit 1
fi

# Install Playwright browsers
echo -e "${YELLOW}Installing Playwright browsers...${NC}"
playwright install chromium firefox

# Install Playwright system dependencies (optional, for UI tests)
echo -e "${YELLOW}Installing Playwright system dependencies...${NC}"
playwright install-deps || echo -e "${YELLOW}  Skipping Playwright deps (run 'playwright install-deps' manually if needed)${NC}"
echo -e "${GREEN}✓ Playwright browsers installed${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p reports/{coverage,allure-results,allure-report}
mkdir -p tests/{unit,integration,api,ui,security,performance,fixtures,mocks,data}
mkdir -p config
echo -e "${GREEN}✓ Directories created${NC}"

# Setup environment file
echo -e "${YELLOW}Setting up environment configuration...${NC}"
if [ ! -f "config/test.env" ]; then
    if [ -f "config/test.env.example" ]; then
        cp config/test.env.example config/test.env
        echo -e "${GREEN}✓ Created config/test.env from example${NC}"
        echo -e "${YELLOW}  Please review and update config/test.env with your settings${NC}"
    else
        echo -e "${YELLOW}  config/test.env.example not found, skipping${NC}"
    fi
else
    echo -e "${YELLOW}  config/test.env already exists${NC}"
fi

# Detect docker compose command (newer Docker uses 'docker compose' with space)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}ERROR: Docker Compose not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Using: $DOCKER_COMPOSE${NC}"

# Start Docker infrastructure
echo ""
echo -e "${YELLOW}Starting test infrastructure...${NC}"
cd infrastructure

# Stop existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
$DOCKER_COMPOSE down -v 2>/dev/null || true

# Start new containers
echo -e "${YELLOW}Starting containers...${NC}"
$DOCKER_COMPOSE up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo -e "${YELLOW}Checking service health...${NC}"
$DOCKER_COMPOSE ps

cd ..

echo ""
echo -e "${GREEN}=== Test Environment Setup Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review configuration in config/test.env"
echo "  2. Run tests: ./scripts/run-tests.sh --suite all"
echo "  3. View test infrastructure: docker-compose -f infrastructure/docker-compose.yml ps"
echo "  4. View logs: docker-compose -f infrastructure/docker-compose.yml logs -f"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  • Run unit tests:        ./scripts/run-tests.sh --suite unit"
echo "  • Run with coverage:     ./scripts/run-tests.sh --suite all --report html"
echo "  • Generate Allure:       ./scripts/run-tests.sh --suite all --report allure"
echo "  • Stop infrastructure:   docker-compose -f infrastructure/docker-compose.yml down"
echo ""
