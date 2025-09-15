import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler

def load_xrf_data(filepath):
    """
    Load and preprocess XRF data from CSV file.
    
    Parameters:
    -----------
    filepath : str
        Path to the CSV file containing XRF data
        
    Returns:
    --------
    df : pandas.DataFrame
        Raw data
    X_scaled : numpy.ndarray
        Scaled features (without Sample column)
    feature_names : list
        Names of the chemical compounds
    """
    # Read data
    df = pd.DataFrame(pd.read_csv(filepath))
    
    # Separate features from sample IDs
    X = df.drop('Sample', axis=1)
    feature_names = X.columns
    
    # Scale features
    X_scaled = StandardScaler().fit_transform(X)
    
    return df, X_scaled, feature_names

def calculate_summary_statistics(df):
    """
    Calculate basic statistics for each chemical compound.
    
    Parameters:
    -----------
    df : pandas.DataFrame
        Raw data including all measurements
        
    Returns:
    --------
    stats_df : pandas.DataFrame
        Summary statistics for each compound
    """
    # Remove Sample column for statistics
    data_cols = df.drop('Sample', axis=1)
    
    # Calculate statistics
    stats = {
        'Mean': data_cols.mean(),
        'Std': data_cols.std(),
        'Min': data_cols.min(),
        'Max': data_cols.max(),
        'Median': data_cols.median()
    }
    
    return pd.DataFrame(stats)
