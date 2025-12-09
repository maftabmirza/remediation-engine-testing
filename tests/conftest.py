"""
Shared pytest fixtures and configuration for remote API testing
Tests connect to running remediation-engine instance via HTTP
"""
import asyncio
import os
import pytest
from typing import Generator
import httpx
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

# Set testing environment variables
os.environ["TESTING"] = "true"
os.environ["LOG_LEVEL"] = "DEBUG"

# Get APP_URL from environment (default to local test instance)
APP_URL = os.getenv("APP_URL", "http://172.234.217.11:8080")


# ============================================================================
# Database Fixtures (for direct DB testing)
# ============================================================================

@pytest.fixture(scope="session")
def test_db_engine():
    """Create test database engine for the session"""
    db_url = os.getenv(
        "DATABASE_URL",
        "postgresql://test_user:test_password@localhost:5433/aiops_test"
    )
    engine = create_engine(db_url, echo=False)
    yield engine
    engine.dispose()


@pytest.fixture
def db_session(test_db_engine) -> Generator[Session, None, None]:
    """Create a new database session for each test"""
    SessionLocal = sessionmaker(bind=test_db_engine, expire_on_commit=False)
    session = SessionLocal()
    
    try:
        yield session
    finally:
        session.rollback()
        session.close()


# ============================================================================
# API Client Fixtures
# ============================================================================

@pytest.fixture
def api_client() -> httpx.Client:
    """HTTP client for API testing"""
    with httpx.Client(base_url=APP_URL, timeout=30.0) as client:
        yield client


@pytest.fixture
async def async_api_client() -> httpx.AsyncClient:
    """Async HTTP client for API testing"""
    async with httpx.AsyncClient(base_url=APP_URL, timeout=30.0) as client:
        yield client


# ============================================================================
# Authentication Fixtures
# ============================================================================

@pytest.fixture
def admin_credentials():
    """Admin user credentials"""
    return {
        "username": os.getenv("ADMIN_USERNAME", "admin"),
        "password": os.getenv("ADMIN_PASSWORD", "Passw0rd")
    }


@pytest.fixture
def auth_headers_admin(api_client, admin_credentials) -> dict:
    """Get authentication headers for admin user"""
    response = api_client.post("/api/auth/login", json=admin_credentials)
    
    if response.status_code != 200:
        pytest.skip(f"Could not authenticate admin user: {response.status_code}")
    
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def test_user_credentials():
    """Test user credentials (if exists)"""
    return {
        "username": "test_user",
        "password": "TestPassw0rd!"
    }


@pytest.fixture
def auth_headers_user(api_client, test_user_credentials) -> dict:
    """Get authentication headers for regular user"""
    response = api_client.post("/api/auth/login", json=test_user_credentials)
    
    if response.status_code != 200:
        # User doesn't exist, create it first
        pytest.skip("Test user doesn't exist")
    
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


# ============================================================================
# Test Data Fixtures
# ============================================================================

@pytest.fixture
def sample_alert_data():
    """Sample alert data for testing"""
    return {
        "fingerprint": "test-alert-001",
        "alertname": "HighMemoryUsage",
        "severity": "critical",
        "instance": "prod-server-01",
        "labels": {
            "env": "production",
            "service": "api"
        },
        "annotations": {
            "summary": "Memory usage above 90%",
            "description": "Server memory usage is critically high"
        }
    }


@pytest.fixture
def sample_server_data():
    """Sample server credential data for testing"""
    return {
        "name": "test-server-01",
        "hostname": "192.168.1.100",
        "port": 22,
        "username": "testuser",
        "os_type": "linux",
        "protocol": "ssh",
        "auth_type": "password",
        "password": "test-password",
        "environment": "testing"
    }


# ============================================================================
# Mock Service Fixtures
# ============================================================================

@pytest.fixture
def mock_llm_response():
    """Mock LLM API response"""
    return {
        "analysis": "**Root Cause**: High memory usage detected\\n\\n**Impact**: Service performance degraded",
        "recommendations": [
            "1. Check for memory leaks in application",
            "2. Restart the affected service",
            "3. Monitor memory usage trends"
        ]
    }


# ============================================================================
# Event Loop for Async Tests
# ============================================================================

@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


# ============================================================================
# Helper Functions
# ============================================================================

def get_app_health(api_client: httpx.Client) -> dict:
    """Check if the application is running"""
    try:
        response = api_client.get("/health")
        return response.json()
    except Exception as e:
        pytest.fail(f"Application not reachable at {APP_URL}: {e}")
