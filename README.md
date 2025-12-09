# Remediation Engine - Testing Suite

> **Automated testing infrastructure using Infrastructure-as-Code**

[![Tests](https://github.com/maftabmirza/remediation-engine-testing/actions/workflows/test-suite.yml/badge.svg)](https://github.com/maftabmirza/remediation-engine-testing/actions)
[![Coverage](https://codecov.io/gh/maftabmirza/remediation-engine-testing/branch/main/graph/badge.svg)](https://codecov.io/gh/maftabmirza/remediation-engine-testing)

---

## Overview

Complete automated testing suite for the AIOps Remediation Engine with Infrastructure-as-Code deployment.

### Test Coverage

| Test Type | Count | Coverage |
|-----------|-------|----------|
| Unit Tests | 150+ | Core logic |
| Integration Tests | 80+ | Component interactions |
| API Tests | 100+ | REST endpoints |
| UI Tests | 40+ | User interface |
| Security Tests | 30+ | Security controls |
| Performance Tests | 15+ | Load & stress |
| **Total** | **415+** | **70%+ code coverage** |

---

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Python 3.12+
- Git

### Clone & Setup

```bash
# Clone repository
git clone https://github.com/maftabmirza/remediation-engine-testing.git
cd remediation-engine-testing

# Make scripts executable
chmod +x scripts/*.sh

# Setup test environment
./scripts/setup-test-env.sh

# Run all tests
./scripts/run-tests.sh --suite all
```

---

## Running Tests

### All Tests
```bash
./scripts/run-tests.sh --suite all
```

### Specific Test Suites
```bash
# Unit tests only
./scripts/run-tests.sh --suite unit

# Integration tests
./scripts/run-tests.sh --suite integration

# API tests
./scripts/run-tests.sh --suite api

# UI tests
./scripts/run-tests.sh --suite ui

# Security tests
./scripts/run-tests.sh --suite security

# Performance tests
./scripts/run-tests.sh --suite performance
```

### By Priority
```bash
# Critical tests only
./scripts/run-tests.sh --marker critical

# Smoke tests
./scripts/run-tests.sh --marker smoke
```

### With Reporting
```bash
# Generate HTML report
./scripts/run-tests.sh --suite all --report html

# Generate Allure report
./scripts/run-tests.sh --suite all --report allure

# View Allure report
allure serve reports/allure-results
```

---

## Test Server Deployment

### Deploy to Test Server (172.234.217.11)

```bash
# SSH to server
ssh aftab@172.234.217.11

# Clone repository
git clone https://github.com/maftabmirza/remediation-engine-testing.git
cd remediation-engine-testing

# Deploy infrastructure
./scripts/deploy-to-server.sh --env staging

# Run tests
./scripts/run-tests.sh --suite regression --report
```

### Automated Deployment

```bash
# From local machine (with SSH access)
./scripts/deploy-to-server.sh --host 172.234.217.11 --user aftab --env staging
```

---

## Infrastructure

### Docker Compose Stack

The test infrastructure includes:

- **PostgreSQL 16**: Test database
- **Redis 7**: Caching layer
- **Remediation Engine**: Application under test
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Test Runner**: Pytest container
- **Allure**: Report server

### Start Infrastructure

```bash
# Start all services
docker-compose -f infrastructure/docker-compose.yml up -d

# Check service health
docker-compose -f infrastructure/docker-compose.yml ps

# View logs
docker-compose -f infrastructure/docker-compose.yml logs -f
```

### Stop Infrastructure

```bash
docker-compose -f infrastructure/docker-compose.yml down
```

---

## CI/CD Pipeline

### GitHub Actions

Automated tests run on:
- Every push to `main` or `develop`
- Every pull request
- Daily scheduled regression tests (2 AM UTC)
- Manual workflow dispatch

### Workflow Status

Check [Actions](https://github.com/maftabmirza/remediation-engine-testing/actions) for latest runs.

---

## Project Structure

```
remediation-engine-testing/
├── README.md                        # This file
├── .github/workflows/               # CI/CD pipelines
├── infrastructure/                  # IaC files
│   ├── docker-compose.yml           # Test stack
│   └── docker-compose.prod.yml      # Production-like
├── tests/                           # Test suites
│   ├── unit/                        # Unit tests
│   ├── integration/                 # Integration tests
│   ├── api/                         # API tests
│   ├── ui/                          # UI tests
│   ├── security/                    # Security tests
│   ├── performance/                 # Performance tests
│   ├── fixtures/                    # Test data
│   └── mocks/                       # Mock services
├── scripts/                         # Automation scripts
├── config/                          # Configuration files
└── reports/                         # Test reports
```

---

## Configuration

### Environment Variables

Copy and customize:

```bash
cp config/test.env.example config/test.env
# Edit config/test.env with your settings
```

### Test Database

```bash
# Database URL (configured in .env)
DATABASE_URL=postgresql://test_user:test_password@localhost:5433/aiops_test
```

---

## Development

### Adding New Tests

1. Create test file in appropriate directory
2. Use existing fixtures from `conftest.py`
3. Follow naming convention: `test_*.py`
4. Add appropriate markers

Example:
```python
import pytest

@pytest.mark.unit
@pytest.mark.critical
def test_user_creation(db_session):
    # Your test code
    pass
```

### Running Tests Locally

```bash
# Activate virtual environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Run pytest directly
pytest tests/unit -v
pytest tests/api -v --cov=app
```

---

## Troubleshooting

### Database Connection Issues

```bash
# Check database is running
docker ps | grep postgres-test

# Restart database
docker-compose -f infrastructure/docker-compose.yml restart postgres-test

# View logs
docker logs aiops-postgres-test
```

### Port Conflicts

```bash
# Check what's using port 5433
sudo lsof -i :5433  # Linux/Mac
netstat -ano | findstr :5433  # Windows

# Modify ports in infrastructure/docker-compose.yml if needed
```

### Test Failures

```bash
# Run with verbose output
./scripts/run-tests.sh --suite all --verbose

# Run specific failing test
pytest tests/unit/test_models.py::test_user_creation -vv

# Check logs
tail -f reports/test.log
```

---

## Documentation

- [Test Case Catalog](docs/test_cases.md) - Complete list of 643 test cases
- [Feature List](docs/feature_list.md) - All application features
- [Setup Guide](docs/testing_environment_setup.md) - Detailed setup instructions
- [API Documentation](https://github.com/maftabmirza/remediation-engine) - Main application docs

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

---

## License

Same as main remediation-engine project.

---

## Support

For issues or questions:
- Open an issue on GitHub
- Contact: [Your Contact Info]

---

## Test Results

Latest test results: [View on GitHub Actions](https://github.com/maftabmirza/remediation-engine-testing/actions)

Test coverage report: [View on Codecov](https://codecov.io/gh/maftabmirza/remediation-engine-testing)
