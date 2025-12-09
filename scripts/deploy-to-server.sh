#!/bin/bash

# deploy-to-server.sh - Deploy test infrastructure to remote server
# Usage: ./scripts/deploy-to-server.sh [OPTIONS]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
SERVER_HOST="172.234.217.11"
SERVER_USER="aftab"
ENVIRONMENT="staging"
DEPLOY_DIR="/home/aftab/remediation-engine-testing"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            SERVER_HOST="$2"
            shift 2
            ;;
        --user)
            SERVER_USER="$2"
            shift 2
            ;;
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --dir)
            DEPLOY_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./scripts/deploy-to-server.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --host HOST      Server hostname/IP (default: 172.234.217.11)"
            echo "  --user USER      SSH username (default: aftab)"
            echo "  --env ENV        Environment: staging|production (default: staging)"
            echo "  --dir DIR        Deployment directory (default: /home/aftab/remediation-engine-testing)"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== Deploying Test Infrastructure to Server ===${NC}"
echo -e "${YELLOW}Host: $SERVER_USER@$SERVER_HOST${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}Directory: $DEPLOY_DIR${NC}"
echo ""

# Check SSH connectivity
echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh -o ConnectTimeout=10 $SERVER_USER@$SERVER_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${RED}Cannot connect to server. Please check SSH access.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection successful${NC}"

# Create deployment directory
echo -e "${YELLOW}Creating deployment directory...${NC}"
ssh $SERVER_USER@$SERVER_HOST "mkdir -p $DEPLOY_DIR"
echo -e "${GREEN}✓ Directory created${NC}"

# Sync files to server
echo -e "${YELLOW}Syncing files to server...${NC}"
rsync -avz --progress \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='.venv' \
    --exclude='*.pyc' \
    --exclude='reports/' \
    --exclude='*.log' \
    ./ $SERVER_USER@$SERVER_HOST:$DEPLOY_DIR/

echo -e "${GREEN}✓ Files synced${NC}"

# Execute setup on server
echo -e "${YELLOW}Setting up environment on server...${NC}"
ssh $SERVER_USER@$SERVER_HOST << EOF
    set -e
    cd $DEPLOY_DIR
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "Docker not found on server. Please install Docker."
        exit 1
    fi
    
    # Stop existing infrastructure
    echo "Stopping existing infrastructure..."
    cd infrastructure
    docker-compose down -v 2>/dev/null || true
    
    # Start new infrastructure
    echo "Starting test infrastructure..."
    docker-compose up -d
    
    # Wait for services
    echo "Waiting for services to start..."
    sleep 15
    
    # Check service status
    echo "Checking service status..."
    docker-compose ps
    
    cd ..
    
    echo ""
    echo "=== Deployment Complete! ==="
    echo ""
    echo "Test infrastructure is running at:"
    echo "  • Application:  http://$SERVER_HOST:8081"
    echo "  • Prometheus:   http://$SERVER_HOST:9091"
    echo "  • Grafana:      http://$SERVER_HOST:3001"
    echo "  • Allure:       http://$SERVER_HOST:5050"
    echo ""
    echo "To run tests:"
    echo "  ssh $SERVER_USER@$SERVER_HOST"
    echo "  cd $DEPLOY_DIR"
    echo "  ./scripts/run-tests.sh --suite all"
    echo ""
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    echo ""
    echo -e "${YELLOW}Access your test server:${NC}"
    echo "  ssh $SERVER_USER@$SERVER_HOST"
    echo "  cd $DEPLOY_DIR"
    echo ""
    echo -e "${YELLOW}Run tests:${NC}"
    echo "  ./scripts/run-tests.sh --suite all --report allure"
    echo ""
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi
