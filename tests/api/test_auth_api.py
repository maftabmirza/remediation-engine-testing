"""
API tests for authentication endpoints
"""
import pytest


@pytest.mark.api
@pytest.mark.critical
def test_login_success(client, test_admin_user):
    """Test successful login"""
    response = client.post("/api/auth/login", json={
        "username": "test_admin",
        "password": "TestPassw0rd!"
    })
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.api
@pytest.mark.critical
def test_login_invalid_password(client, test_admin_user):
    """Test login with invalid password"""
    response = client.post("/api/auth/login", json={
        "username": "test_admin",
        "password": "WrongPassword"
    })
    
    assert response.status_code == 401


@pytest.mark.api
@pytest.mark.critical
def test_login_invalid_username(client):
    """Test login with non-existent username"""
    response = client.post("/api/auth/login", json={
        "username": "nonexistent",
        "password": "password123"
    })
    
    assert response.status_code == 401


@pytest.mark.api
def test_login_inactive_user(client, test_regular_user, db_session):
    """Test login with inactive user"""
    test_regular_user.is_active = False
    db_session.commit()
    
    response = client.post("/api/auth/login", json={
        "username": "test_user",
        "password": "TestPassw0rd!"
    })
    
    assert response.status_code == 401


@pytest.mark.api
@pytest.mark.critical
def test_protected_endpoint_without_token(client):
    """Test accessing protected endpoint without authentication"""
    response = client.get("/api/users")
    
    assert response.status_code == 401


@pytest.mark.api
@pytest.mark.critical
def test_protected_endpoint_with_token(client, auth_headers_admin):
    """Test accessing protected endpoint with valid token"""
    response = client.get("/api/users", headers=auth_headers_admin)
    
    assert response.status_code == 200
    assert isinstance(response.json(), list)
