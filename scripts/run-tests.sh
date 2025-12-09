#!/bin/bash

# run-tests.sh - Main test execution script
# Usage: ./scripts/run-tests.sh [OPTIONS]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
SUITE="all"
MARKER=""
VERBOSE=""
REPORT_TYPE=""
PARALLEL=""
COVERAGE="--cov=app --cov-report=term-missing"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --suite)
            SUITE="$2"
            shift 2
            ;;
        --marker)
            MARKER="-m $2"
            shift 2
            ;;
        --report)
            REPORT_TYPE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE="-vv"
            shift
            ;;
        --parallel)
            PARALLEL="-n auto"
            shift
            ;;
        --no-cov)
            COVERAGE=""
            shift
            ;;
        --help|-h)
            echo "Usage: ./scripts/run-tests.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --suite SUITE       Test suite to run: all|unit|integration|api|ui|security|performance"
            echo "  --marker MARKER     Run tests with specific marker: critical|smoke|slow"
            echo "  --report TYPE       Generate report: html|allure|junit"
            echo "  --verbose, -v       Verbose output"
            echo "  --parallel          Run tests in parallel"
            echo "  --no-cov            Disable coverage reporting"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./scripts/run-tests.sh --suite unit"
            echo "  ./scripts/run-tests.sh --marker critical --report allure"
            echo "  ./scripts/run-tests.sh --suite api --verbose --parallel"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=== Remediation Engine Test Suite ===${NC}"
echo -e "${YELLOW}Suite: $SUITE${NC}"
echo ""

# Determine test path based on suite
case $SUITE in
    all)
        TEST_PATH="tests/"
        ;;
    unit)
        TEST_PATH="tests/unit/"
        ;;
    integration)
        TEST_PATH="tests/integration/"
        ;;
    api)
        TEST_PATH="tests/api/"
        ;;
    ui)
        TEST_PATH="tests/ui/"
        ;;
    security)
        TEST_PATH="tests/security/"
        ;;
    performance)
        TEST_PATH="tests/performance/"
        ;;
    smoke)
        TEST_PATH="tests/"
        MARKER="-m smoke"
        ;;
    regression)
        TEST_PATH="tests/"
        MARKER="-m 'not slow'"
        ;;
    *)
        echo -e "${RED}Unknown test suite: $SUITE${NC}"
        echo "Available suites: all, unit, integration, api, ui, security, performance, smoke, regression"
        exit 1
        ;;
esac

# Build pytest command
PYTEST_CMD="pytest $TEST_PATH $MARKER $VERBOSE $PARALLEL $COVERAGE --tb=short"

# Add reporting options
mkdir -p reports
case $REPORT_TYPE in
    html)
        PYTEST_CMD="$PYTEST_CMD --html=reports/test-report.html --self-contained-html"
        ;;
    allure)
        PYTEST_CMD="$PYTEST_CMD --alluredir=reports/allure-results"
        ;;
    junit)
        PYTEST_CMD="$PYTEST_CMD --junit-xml=reports/junit.xml"
        ;;
    "")
        # No additional reporting
        ;;
    *)
        echo -e "${YELLOW}Warning: Unknown report type '$REPORT_TYPE'. Skipping.${NC}"
        ;;
esac

# Check if running in Docker
if [ -f /.dockerenv ]; then
    echo -e "${YELLOW}Running in Docker container${NC}"
else
    echo -e "${YELLOW}Running on host machine${NC}"
    
    # Check if virtual environment is activated
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo -e "${YELLOW}Warning: No virtual environment detected. Attempting to activate...${NC}"
        if [ -d ".venv" ]; then
            source .venv/bin/activate
        elif [ -d "venv" ]; then
            source venv/bin/activate
        else
            echo -e "${RED}No virtual environment found. Please run setup-test-env.sh first.${NC}"
            exit 1
        fi
    fi
fi

# Run tests
echo -e "${GREEN}Executing: $PYTEST_CMD${NC}"
echo ""

if $PYTEST_CMD; then
    echo ""
    echo -e "${GREEN}✓ Tests passed successfully!${NC}"
    
    # Generate Allure report if requested
    if [ "$REPORT_TYPE" = "allure" ]; then
        echo ""
        echo -e "${YELLOW}Generating Allure report...${NC}"
        allure generate reports/allure-results -o reports/allure-report --clean
        echo -e "${GREEN}Allure report generated at: reports/allure-report${NC}"
        echo -e "${YELLOW}To view report: allure serve reports/allure-results${NC}"
    fi
    
    # Show coverage report location
    if [ -n "$COVERAGE" ]; then
        echo -e "${GREEN}Coverage report: reports/coverage/index.html${NC}"
    fi
    
    exit 0
else
    echo ""
    echo -e "${RED}✗ Tests failed!${NC}"
    echo -e "${YELLOW}Check the output above for details.${NC}"
    exit 1
fi
