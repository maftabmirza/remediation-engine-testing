"""
API tests for authentication endpoints
Tests against running remediation-engine instance
"""
import pytest


@pytest.mark.api
@pytest.mark.critical
def test_login_success(api_client, admin_credentials):
    """Test successful admin login"""
    response = api_client.post("/api/auth/login", json=admin_credentials)
    
    assert response.status_code == 200, f"Login failed: {response.text}"
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.api
@pytest.mark.critical
def test_login_invalid_password(api_client):
    """Test login with invalid password"""
    response = api_client.post("/api/auth/login", json={
        "username": "admin",
        "password": "WrongPassword123!"
    })
    
    assert response.status_code == 401


@pytest.mark.api
@pytest.mark.critical
def test_login_invalid_username(api_client):
    """Test login with non-existent username"""
    response = api_client.post("/api/auth/login", json={
        "username": "nonexistent_user_12345",
        "password": "password123"
    })
    
    assert response.status_code == 401


@pytest.mark.api
@pytest.mark.critical
def test_protected_endpoint_without_token(api_client):
    """Test accessing protected endpoint without authentication"""
    response = api_client.get("/api/users")
    
    assert response.status_code == 401


@pytest.mark.api
@pytest.mark.critical
def test_protected_endpoint_with_token(api_client, auth_headers_admin):
    """Test accessing protected endpoint with valid token"""
    response = api_client.get("/api/users", headers=auth_headers_admin)
    
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.api
def test_health_endpoint(api_client):
    """Test health check endpoint"""
    response = api_client.get("/health")
    
    assert response.status_code == 200
    data = response.json()
    assert "status" in data


@pytest.mark.api
@pytest.mark.smoke
def test_api_connectivity(api_client):
    """Smoke test - verify API is reachable"""
    try:
        response = api_client.get("/")
        # Should get some response (200 or redirect)
        assert response.status_code in [200, 307, 404]
    except Exception as e:
        pytest.fail(f"Cannot connect to API: {e}")
