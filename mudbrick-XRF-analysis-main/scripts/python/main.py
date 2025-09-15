import os
from data_loader import load_xrf_data, calculate_summary_statistics
from pca_analysis import perform_pca_analysis
from utils import save_results

def main():
    # Create necessary directories if they don't exist
    os.makedirs('results/figures', exist_ok=True)
    os.makedirs('results/stats', exist_ok=True)
    
    # Load and preprocess data
    df, X_scaled, feature_names = load_xrf_data('data/raw/xrf_data.csv')
    
    # Calculate and save basic statistics
    stats_df = calculate_summary_statistics(df)
    stats_df.to_csv('results/stats/summary_statistics.csv')
    
    # Perform PCA analysis
    pca, X_pca = perform_pca_analysis(X_scaled, df, feature_names)
    
    # Save results
    save_results(pca, feature_names, 'results/stats/pca_results.txt')
    
    print("Analysis completed successfully!")
    print("Results saved in 'results' directory")

if __name__ == "__main__":
    main()
