#!/bin/bash

# [AI-GENERATED: Claude Code]
# Quick test runner for Vietnamese PT Anatomy Selector E2E tests
#
# Usage:
#   ./run-anatomy-tests.sh                    # Run all anatomy selector tests
#   ./run-anatomy-tests.sh testMethodName     # Run specific test method
#   ./run-anatomy-tests.sh --verbose          # Run with verbose output

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================\033[0m"
echo -e "${BLUE}Vietnamese PT Anatomy Selector E2E Tests${NC}"
echo -e "${BLUE}===========================================\033[0m"
echo ""

# Detect if running in Docker or locally
if [[ -f "/.dockerenv" ]]; then
    # Running inside Docker container
    PHPUNIT="/openemr/vendor/bin/phpunit"
    TEST_PATH="/openemr/tests/Tests/E2e/VietnamesePT/AnatomySelectorTest.php"
else
    # Running on host - check if we should use Docker
    if command -v docker &> /dev/null && docker compose ps openemr &> /dev/null; then
        echo -e "${GREEN}Using Docker environment...${NC}"
        DOCKER_CMD="docker compose exec openemr"
        PHPUNIT="./vendor/bin/phpunit"
        TEST_PATH="tests/Tests/E2e/VietnamesePT/AnatomySelectorTest.php"
    else
        # Local execution
        PHPUNIT="./vendor/bin/phpunit"
        TEST_PATH="tests/Tests/E2e/VietnamesePT/AnatomySelectorTest.php"
    fi
fi

# Build command
CMD="${PHPUNIT} --colors=always --testdox"

# Handle arguments
if [[ "$1" = "--verbose" ]] || [[ "$1" = "-v" ]]; then
    CMD="${CMD} --verbose"
    shift
elif [[ -n "$1" ]]; then
    # Specific test method or filter
    CMD="${CMD} --filter $1"
fi

CMD="${CMD} ${TEST_PATH}"

# Add Docker prefix if needed
if [[ -n "${DOCKER_CMD}" ]]; then
    CMD="${DOCKER_CMD} ${CMD}"
fi

echo -e "${GREEN}Running command:${NC}"
echo "${CMD}"
echo ""

# Run the tests and capture exit code
if eval "${CMD}"; then
    echo ""
    echo -e "${GREEN}===========================================\033[0m"
    echo -e "${GREEN}All tests passed!${NC}"
    echo -e "${GREEN}===========================================\033[0m"
else
    echo ""
    echo -e "${RED}===========================================\033[0m"
    echo -e "${RED}Some tests failed!${NC}"
    echo -e "${RED}===========================================\033[0m"
    exit 1
fi
