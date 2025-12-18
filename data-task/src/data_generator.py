import pandas as pd
import numpy as np

def generate_data(n_samples=100) -> pd.DataFrame:
    n_samples = n_samples
    X = np.random.rand(n_samples, 1) * 10
    y = 2 * X + 1 + np.random.randn(n_samples, 1)

    df = pd.DataFrame(np.hstack([X, y]), columns=['feature_x', 'target_y'])

    return df

if __name__ == '__main__':
   print(generate_data())
