"""Conftest for pytest configuration and fixtures."""
import os

import pytest


@pytest.fixture(scope="session")
def test_env_setup():
    """Set up test environment variables."""
    os.environ["TMDB_API_KEY"] = "test_key"
    os.environ["AWS_ACCESS_KEY_ID"] = "test_access_key"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "test_secret_key"
    os.environ["AWS_REGION"] = "us-east-1"
    os.environ["S3_BUCKET"] = "test-bucket"

    yield

    # Cleanup
    for key in ["TMDB_API_KEY", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_REGION", "S3_BUCKET"]:
        if key in os.environ:
            del os.environ[key]


def pytest_configure(config):
    """Configure pytest with custom markers."""
    config.addinivalue_line(
        "markers", "unit: mark test as a unit test"
    )
    config.addinivalue_line(
        "markers", "integration: mark test as an integration test"
    )
    config.addinivalue_line(
        "markers", "slow: mark test as slow running"
    )
    config.addinivalue_line(
        "markers", "api: mark test as requiring API calls"
    )
