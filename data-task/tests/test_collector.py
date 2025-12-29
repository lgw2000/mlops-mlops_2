"""Unit tests for TMDB Collector module."""
from unittest.mock import MagicMock, Mock, patch

import pandas as pd
import pytest
from src.collector import TMDBCollector


@pytest.fixture
def tmdb_collector():
    """Create a TMDBCollector instance for testing."""
    return TMDBCollector(api_key="test_api_key")


@pytest.fixture
def sample_movie_data():
    """Provide sample movie data for testing."""
    return {
        "results": [
            {
                "id": 1,
                "title": "Test Movie 1",
                "vote_average": 7.5,
                "popularity": 100,
                "release_date": "2023-01-01",
                "genre_ids": [28, 12],
                "overview": "Test overview",
            },
            {
                "id": 2,
                "title": "Test Movie 2",
                "vote_average": 8.0,
                "popularity": 150,
                "release_date": "2023-06-01",
                "genre_ids": [35],
                "overview": "Another test",
            },
        ]
    }


class TestTMDBCollector:
    """Test cases for TMDBCollector."""

    def test_collector_initialization(self, tmdb_collector):
        """Test TMDBCollector initialization."""
        assert tmdb_collector.api_key == "test_api_key"
        assert tmdb_collector.base_url == "https://api.themoviedb.org/3"

    @patch("src.collector.requests.get")
    def test_fetch_popular_movies(self, mock_get, tmdb_collector, sample_movie_data):
        """Test fetching popular movies from TMDB API."""
        mock_response = Mock()
        mock_response.json.return_value = sample_movie_data
        mock_response.status_code = 200
        mock_get.return_value = mock_response

        df = tmdb_collector.fetch_popular_movies(page_limit=1)

        assert isinstance(df, pd.DataFrame)
        assert len(df) == 2
        assert "title" in df.columns
        assert "vote_average" in df.columns
        mock_get.assert_called()

    @patch("src.collector.requests.get")
    def test_fetch_popular_movies_api_error(self, mock_get, tmdb_collector):
        """Test handling of API errors."""
        mock_response = Mock()
        mock_response.status_code = 401
        mock_response.json.return_value = {"status_message": "Invalid API key"}
        mock_get.return_value = mock_response

        with pytest.raises(Exception):
            tmdb_collector.fetch_popular_movies(page_limit=1)

    @patch("builtins.open", create=True)
    @patch("os.makedirs")
    def test_save_raw_data(self, mock_makedirs, mock_open, tmdb_collector):
        """Test saving raw data to CSV."""
        df = pd.DataFrame({
            "id": [1, 2],
            "title": ["Movie 1", "Movie 2"],
            "vote_average": [7.5, 8.0]
        })

        with patch("pandas.DataFrame.to_csv"):
            file_path = tmdb_collector.save_raw_data(df, "20230101")
            assert "20230101" in file_path
            assert file_path.endswith(".csv")

    def test_fetch_popular_movies_empty_result(self, tmdb_collector):
        """Test handling of empty results."""
        with patch("src.collector.requests.get") as mock_get:
            mock_response = Mock()
            mock_response.json.return_value = {"results": []}
            mock_response.status_code = 200
            mock_get.return_value = mock_response

            df = tmdb_collector.fetch_popular_movies(page_limit=1)
            assert isinstance(df, pd.DataFrame)
            assert len(df) == 0


class TestTMDBCollectorIntegration:
    """Integration tests for TMDBCollector (marked as integration tests)."""

    @pytest.mark.integration
    @pytest.mark.slow
    def test_fetch_popular_movies_integration(self, tmdb_collector):
        """Test actual API call (requires valid API key)."""
        pytest.skip("Skipping integration test - requires valid API key")
