"""Unit tests for ModelTrainer module."""
import os

import numpy as np
import pandas as pd
import pytest
from src.train import ModelTrainer


@pytest.fixture
def model_trainer():
    """Create a ModelTrainer instance for testing."""
    return ModelTrainer(target_column="vote_average")


@pytest.fixture
def sample_training_data():
    """Create sample training data."""
    np.random.seed(42)
    n_samples = 100

    return pd.DataFrame({
        "vote_average": np.random.uniform(5, 10, n_samples),
        "popularity": np.random.uniform(50, 500, n_samples),
        "budget": np.random.uniform(1000000, 300000000, n_samples),
        "revenue": np.random.uniform(1000000, 3000000000, n_samples),
        "runtime": np.random.uniform(80, 180, n_samples),
        "genre_action": np.random.randint(0, 2, n_samples),
        "genre_comedy": np.random.randint(0, 2, n_samples),
        "genre_drama": np.random.randint(0, 2, n_samples),
    })


class TestModelTrainer:
    """Test cases for ModelTrainer."""

    def test_trainer_initialization(self, model_trainer):
        """Test ModelTrainer initialization."""
        assert model_trainer.target_column == "vote_average"
        assert model_trainer.model is None

    def test_train_model(self, model_trainer, sample_training_data):
        """Test model training."""
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_training_data.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            metrics = model_trainer.train(temp_file)

            assert metrics is not None
            assert "mse" in metrics or "rmse" in metrics or "r2" in metrics
            assert model_trainer.model is not None
        finally:
            os.unlink(temp_file)

    def test_model_prediction(self, model_trainer, sample_training_data):
        """Test model prediction."""
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_training_data.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            model_trainer.train(temp_file)

            # Create test data
            test_data = sample_training_data.drop("vote_average", axis=1).iloc[:10]
            predictions = model_trainer.model.predict(test_data)

            assert predictions is not None
            assert len(predictions) == len(test_data)
            assert all(isinstance(p, (int, float, np.number)) for p in predictions)
        finally:
            os.unlink(temp_file)

    def test_save_model(self, model_trainer, sample_training_data):
        """Test saving model."""
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_training_data.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            metrics = model_trainer.train(temp_file)

            temp_dir = tempfile.mkdtemp()
            try:
                model_trainer.save_model(temp_dir, metrics)

                # Check if model files are created
                assert os.path.exists(os.path.join(temp_dir, "model.pkl"))
                assert os.path.exists(os.path.join(temp_dir, "metrics.json"))
            finally:
                # Clean up temp directory
                import shutil
                shutil.rmtree(temp_dir, ignore_errors=True)
        finally:
            os.unlink(temp_file)

    def test_insufficient_data(self, model_trainer):
        """Test handling of insufficient training data."""
        small_data = pd.DataFrame({
            "vote_average": [7.5, 8.0],
            "popularity": [100.0, 150.0],
        })

        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            small_data.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            # Should either train with small data or raise an error
            try:
                metrics = model_trainer.train(temp_file)
                # If it trains, that's fine
                assert metrics is not None
            except (ValueError, IndexError):
                # If it raises an error, that's also acceptable
                pass
        finally:
            os.unlink(temp_file)

    def test_metrics_format(self, model_trainer, sample_training_data):
        """Test that metrics are in correct format."""
        import os
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as f:
            sample_training_data.to_csv(f.name, index=False)
            temp_file = f.name

        try:
            metrics = model_trainer.train(temp_file)

            assert isinstance(metrics, dict)
            # Check for common metric keys
            metric_keys = set(metrics.keys())
            expected_keys = {"mse", "rmse", "r2"}
            assert len(metric_keys & expected_keys) > 0, "No common metrics found"
        finally:
            os.unlink(temp_file)
