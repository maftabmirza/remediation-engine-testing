"""
Shared pytest fixtures and configuration for all tests
"""
import asyncio
import os
import pytest
from typing import AsyncGenerator, Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from fastapi.testclient import TestClient

# Set testing environment variables
os.environ["TESTING"] = "true"
os.environ["LOG_LEVEL"] = "DEBUG"


# Import after setting environment
from app.main import app
from app.database import Base, get_db
from app.models import User, Alert, ServerCredential, LLMProvider
from app.services.auth_service import get_password_hash


# ============================================================================
# Database Fixtures
# ============================================================================

@pytest.fixture(scope="session")
def test_db_engine():
    """Create test database engine for the session"""
    db_url = os.getenv(
        "DATABASE_URL",
        "postgresql://test_user:test_password@localhost:5433/aiops_test"
    )
    engine = create_engine(db_url, echo=False)
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    yield engine
    
    # Drop all tables after tests
    Base.metadata.drop_all(bind=engine)
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


@pytest.fixture
def override_get_db(db_session):
    """Override the database dependency for FastAPI"""
    def _override_get_db():
        try:
            yield db_session
        finally:
            pass
    
    app.dependency_overrides[get_db] = _override_get_db
    yield
    app.dependency_overrides.clear()


# ============================================================================
# API Client Fixtures
# ============================================================================

@pytest.fixture
def client(override_get_db) -> TestClient:
    """FastAPI test client"""
    return TestClient(app)


# ============================================================================
# User & Authentication Fixtures
# ============================================================================

@pytest.fixture
def test_admin_user(db_session) -> User:
    """Create a test admin user"""
    user = User(
        username="test_admin",
        email="admin@test.com",
        full_name="Test Admin",
        password_hash=get_password_hash("TestPassw0rd!"),
        role="admin",
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_engineer_user(db_session) -> User:
    """Create a test engineer user"""
    user = User(
        username="test_engineer",
        email="engineer@test.com",
        full_name="Test Engineer",
        password_hash=get_password_hash("TestPassw0rd!"),
        role="engineer",
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_regular_user(db_session) -> User:
    """Create a test regular user"""
    user = User(
        username="test_user",
        email="user@test.com",
        full_name="Test User",
        password_hash=get_password_hash("TestPassw0rd!"),
        role="user",
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def auth_headers_admin(client, test_admin_user) -> dict:
    """Get authentication headers for admin user"""
    response = client.post("/api/auth/login", json={
        "username": "test_admin",
        "password": "TestPassw0rd!"
    })
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def auth_headers_engineer(client, test_engineer_user) -> dict:
    """Get authentication headers for engineer user"""
    response = client.post("/api/auth/login", json={
        "username": "test_engineer",
        "password": "TestPassw0rd!"
    })
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def auth_headers_user(client, test_regular_user) -> dict:
    """Get authentication headers for regular user"""
    response = client.post("/api/auth/login", json={
        "username": "test_user",
        "password": "TestPassw0rd!"
    })
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


# ============================================================================
# Test Data Fixtures
# ============================================================================

@pytest.fixture
def sample_alert(db_session, test_admin_user) -> Alert:
    """Create a sample alert for testing"""
    alert = Alert(
        fingerprint="test-alert-001",
        alert_name="HighMemoryUsage",
        severity="critical",
        instance="prod-server-01",
        job="node-exporter",
        status="firing",
        labels_json={
            "env": "production",
            "service": "api",
            "alertname": "HighMemoryUsage"
        },
        annotations_json={
            "summary": "Memory usage above 90%",
            "description": "Server memory usage is critically high"
        },
        raw_alert_json={}
    )
    db_session.add(alert)
    db_session.commit()
    db_session.refresh(alert)
    return alert


@pytest.fixture
def sample_server(db_session, test_admin_user) -> ServerCredential:
    """Create a sample server credential for testing"""
    from app.utils.crypto import encrypt_value
    
    server = ServerCredential(
        name="test-server-01",
        hostname="192.168.1.100",
        port=22,
        username="testuser",
        os_type="linux",
        protocol="ssh",
        auth_type="key",
        ssh_key_encrypted=encrypt_value("test-ssh-key"),
        environment="testing",
        created_by=test_admin_user.id
    )
    db_session.add(server)
    db_session.commit()
    db_session.refresh(server)
    return server


@pytest.fixture
def sample_llm_provider(db_session) -> LLMProvider:
    """Create a sample LLM provider for testing"""
    from app.utils.crypto import encrypt_value
    
    provider = LLMProvider(
        name="Test OpenAI",
        provider_type="openai",
        model_id="gpt-4",
        api_key_encrypted=encrypt_value("sk-test-key"),
        is_default=True,
        enabled=True
    )
    db_session.add(provider)
    db_session.commit()
    db_session.refresh(provider)
    return provider


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


@pytest.fixture
def mock_ssh_output():
    """Mock SSH command output"""
    return {
        "stdout": "Memory usage: 92%\\nSwap usage: 45%",
        "stderr": "",
        "exit_code": 0
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
# Cleanup Fixtures
# ============================================================================

@pytest.fixture(autouse=True)
def cleanup_test_data(db_session):
    """Cleanup test data after each test"""
    yield
    # Cleanup is handled by session rollback in db_session fixture
