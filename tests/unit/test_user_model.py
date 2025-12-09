"""
Unit tests for User model and authentication
"""
import pytest
from app.models import User
from app.services.auth_service import get_password_hash, verify_password


@pytest.mark.unit
@pytest.mark.critical
def test_user_creation(db_session):
    """Test creating a new user"""
    user = User(
        username="newuser",
        email="newuser@test.com",
        full_name="New User",
        password_hash=get_password_hash("password123"),
        role="user",
        is_active=True
    )
    
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    
    assert user.id is not None
    assert user.username == "newuser"
    assert user.email == "newuser@test.com"
    assert user.is_active is True


@pytest.mark.unit
@pytest.mark.critical
def test_password_hashing():
    """Test password hashing and verification"""
    password = "TestPassword123!"
    hashed = get_password_hash(password)
    
    assert hashed != password
    assert verify_password(password, hashed) is True
    assert verify_password("WrongPassword", hashed) is False


@pytest.mark.unit
def test_user_role_assignment(db_session):
    """Test user role assignment"""
    admin_user = User(
        username="admin",
        email="admin@test.com",
        password_hash=get_password_hash("admin123"),
        role="admin"
    )
    
    db_session.add(admin_user)
    db_session.commit()
    
    assert admin_user.role == "admin"


@pytest.mark.unit
def test_user_deactivation(db_session, test_regular_user):
    """Test user deactivation"""
    test_regular_user.is_active = False
    db_session.commit()
    
    assert test_regular_user.is_active is False
