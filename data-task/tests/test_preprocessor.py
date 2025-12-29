"""Unit tests for Preprocessor module."""
import numpy as np
import pandas as pd
import pytest
from src.preprocessor import Preprocessor


@pytest.fixture
def preprocessor():
    """Create a Preprocessor instance for testing."""
    return Preprocessor()


@pytest.fixture
def sample_dataframe():
    """Create a sample DataFrame for testing."""
    return pd.DataFrame({
        "id": [1, 2, 3, 4, 5],
        "title": ["Movie A", "Movie B", "Movie C", "Movie D", "Movie E"],
        "vote_average": [7.5, 8.0, 6.5, 9.0, 7.8],
        "popularity": [100.0, 150.0, 75.0, 200.0, 120.0],
        "revenue": [1000000, 2000000, 500000, 3000000, 1500000],
        "budget": [100000, 200000, 50000, 300000, 150000],
        "genres": ["Action", "Comedy", "Drama", "Action", "Thriller"],
    })


class TestPreprocessor:
    """Test cases for Preprocessor."""

    def test_preprocessor_initialization(self, preprocessor):
        """Test Preprocessor initialization."""
        assert preprocessor is not None

    def test_transform_data_types(self, preprocessor, sample_dataframe):
        """Test that transform returns correct data types."""
        # Create a temporary CSV file
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_dataframe.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            df_processed = preprocessor.transform(temp_file)
            assert isinstance(df_processed, pd.DataFrame)
            assert len(df_processed) > 0
        finally:
            os.unlink(temp_file)

    def test_missing_values_handling(self, preprocessor):
        """Test handling of missing values."""
        df_with_missing = pd.DataFrame({
            "id": [1, 2, 3],
            "title": ["Movie A", None, "Movie C"],
            "vote_average": [7.5, 8.0, None],
        })

        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            df_with_missing.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            df_processed = preprocessor.transform(temp_file)
            # Check that rows with missing values are handled
            assert len(df_processed) <= len(df_with_missing)
        finally:
            os.unlink(temp_file)

    def test_feature_scaling(self, preprocessor, sample_dataframe):
        """Test that features are properly scaled."""
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_dataframe.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            df_processed = preprocessor.transform(temp_file)
            # Check that numeric columns are scaled (values should be in reasonable range)
            for col in df_processed.select_dtypes(include=[np.number]).columns:
                assert df_processed[col].min() >= -10
                assert df_processed[col].max() <= 10 or df_processed[col].max() is np.nan
        finally:
            os.unlink(temp_file)

    def test_save_processed_data(self, preprocessor, sample_dataframe):
        """Test saving processed data."""
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_dataframe.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            df_processed = preprocessor.transform(temp_file)
            file_path = preprocessor.save_processed_data(df_processed, "20230101")

            assert os.path.exists(file_path)
            assert "20230101" in file_path
            assert file_path.endswith(".csv")

            # Clean up saved file
            if os.path.exists(file_path):
                os.unlink(file_path)
        finally:
            os.unlink(temp_file)

    def test_empty_dataframe(self, preprocessor):
        """Test handling of empty DataFrame."""
        df_empty = pd.DataFrame()

        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            df_empty.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            # Should handle empty data gracefully
            with pytest.raises((ValueError, IndexError, KeyError, pd.errors.ParserError)):
                preprocessor.transform(temp_file)
        finally:
            os.unlink(temp_file)
