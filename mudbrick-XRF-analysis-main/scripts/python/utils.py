import numpy as np
import scipy.stats as stats

def get_confidence_ellipse(x, y, confidence=0.955):
    """
    Calculate parameters for plotting confidence ellipse.
    
    Parameters:
    -----------
    x, y : array-like
        Coordinates for which to compute the ellipse
    confidence : float, optional (default=0.955)
        Confidence level for the ellipse
        
    Returns:
    --------
    width : float
        Width of the ellipse
    height : float
        Height of the ellipse
    angle : float
        Rotation angle in degrees
    """
    cov = np.cov(x, y)
    pearson = cov[0, 1]/np.sqrt(cov[0, 0] * cov[1, 1])
    
    chi2_val = stats.chi2.ppf(confidence, 2)
    
    eigenvals, eigenvecs = np.linalg.eig(cov)
    sort_indices = np.argsort(eigenvals)[::-1]
    eigenvals = eigenvals[sort_indices]
    eigenvecs = eigenvecs[:, sort_indices]
    
    angle = np.degrees(np.arctan2(eigenvecs[1, 0], eigenvecs[0, 0]))
    width, height = 2 * np.sqrt(chi2_val * eigenvals)
    
    return width, height, angle

def save_results(pca, feature_names, output_path):
    """
    Save PCA results to text file.
    
    Parameters:
    -----------
    pca : sklearn.decomposition.PCA
        Fitted PCA object
    feature_names : list
        Names of the features
    output_path : str
        Path where to save the results
    """
    with open(output_path, 'w') as f:
        # Write explained variance
        f.write("Explained variance ratios:\n")
        for i, var in enumerate(pca.explained_variance_ratio_):
            f.write(f"PC{i+1}: {var:.3f}\n")
        
        # Write loadings
        f.write("\nLoadings:\n")
        for i, feature in enumerate(feature_names):
            f.write(f"{feature}:")
            for j in range(2):  # First two components
                f.write(f" PC{j+1}={pca.components_[j,i]:.3f}")
            f.write("\n")
