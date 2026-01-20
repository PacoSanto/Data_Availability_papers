%% ========================================================================
%  ISRU Lunar Site Suitability Analysis - MCDA Framework
%  ========================================================================
%
%  DESCRIPTION:
%    Multi-Criteria Decision Analysis (MCDA) for lunar In-Situ Resource 
%    Utilization (ISRU) site selection. Integrates compositional and 
%    environmental parameters to produce normalized suitability scores for:
%      1. Oxygen extraction from ilmenite and volcanic glass
%      2. Volatile harvesting from solar wind-implanted regolith
%
%  AUTHOR: Francesco Santoro De Vico
%  DATE: September 2025 - January 2026
%  VERSION: 1.0
%
%  INPUTS (5 TXT files required in input_folder):
%    - FeO.txt    : Iron oxide abundance (wt%)
%    - TiO2.txt   : Titanium oxide abundance (wt%)
%    - Glass.txt  : Volcanic glass index (dimensionless)
%    - OMAT.txt   : Optical maturity index (0-1)
%    - OH.txt     : Hydroxyl/water absorption depth
%
%  OUTPUTS (saved in output_folder):
%    - S_O2_score.txt        : Oxygen extraction suitability (0-10 scale)
%    - S_volatiles_score.txt : Volatile extraction suitability (0-10 scale)
%    - S_combined_score.txt  : Combined ISRU suitability (0-10 scale)
%    - Normalized parameter functions (f_oxides, f_glass, etc.)
%    - MCDA_Analysis_Report.txt : Summary statistics and top sites
%    - Visualization plots (PNG/FIG)
%
%  USAGE:
%    1. Place 5 input TXT files in 'input_folder' (see CONFIGURATION below)
%    2. Set 'input_folder' and 'output_folder' paths
%    3. Run script: >> MCDA_ISRU_analysis
%
%  REQUIREMENTS:
%    - MATLAB R2020a or later
%    - No additional toolboxes required
%
%  LICENSE: MIT License (see repository LICENSE file)
%
%% ========================================================================

clear; clc; close all;

%% ========================================================================
% CONFIGURATION SECTION
% ========================================================================

% -------------------------------------------------------------------------
% Path Configuration
% -------------------------------------------------------------------------
% MODIFY THESE PATHS for your system:

% Input folder containing the 5 required TXT files
input_folder = '../data/input/';  % Relative path from src/ directory
% Windows example: 'C:\Users\YourName\MCDA\data\input\'
% Linux example:   '/home/username/MCDA/data/input/'

% Output folder where results will be saved
output_folder = '../data/output/';

% Create output folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% -------------------------------------------------------------------------
% Input File Names (must match exactly)
% -------------------------------------------------------------------------
files = struct(...
    'FeO', 'FeO.txt', ...
    'Glass', 'Glass.txt', ...
    'OH', 'OH.txt', ...
    'OMAT', 'OMAT.txt', ...
    'TiO2', 'TiO2.txt' ...
);

%% ========================================================================
% NODATA CONFIGURATION
% ========================================================================

% NoData threshold - values below this are considered invalid
% Typical GIS NoData values:
%   -3.4028e+38 (float32 minimum)
%   -9999
%   -99999
NODATA_THRESHOLD = -1e+30;

%% ========================================================================
% NORMALIZATION CONSTANTS
% ========================================================================
% These constants are based on lunar regolith literature

% For f_oxides function: reference values from high-Ti mare basalts
TiO2_ref = 15;  % wt% - upper limit for high-Ti mare (Papike et al., 1998)
FeO_ref = 25;   % wt% - upper limit for high-Ti mare

%% ========================================================================
% WEIGHT COEFFICIENTS FOR MCDA
% ========================================================================
% Weights reflect mission-critical priorities for ISRU operations
% See docs/methodology.md for detailed justification

% -------------------------------------------------------------------------
% Weights for Oxygen Extraction Score (S_O2)
% -------------------------------------------------------------------------
w_O2_oxides = 0.55;  % Weight for combined TiO2+FeO oxide term
w_O2_glass = 0.25;   % Weight for glass content

% Note: These weights sum to 0.80, will be normalized to 1.0 in calculation
% Normalized weights become: 0.69 (oxides) and 0.31 (glass)

% -------------------------------------------------------------------------
% Weights for Volatile Extraction Score (S_volatiles)
% -------------------------------------------------------------------------
w_vol_glass = 0.45;  % Glass (solar wind implantation host)
w_vol_OMAT = 0.35;   % Optical maturity (exposure age proxy)
w_vol_OH = 0.10;     % Hydroxyl/water signature
w_vol_Fe = 0.10;     % FeO (nanophase Fe indicator)

% Verify weights sum to 1.0
assert(abs((w_vol_glass + w_vol_OMAT + w_vol_OH + w_vol_Fe) - 1.0) < 0.001, ...
    'Volatile weights must sum to 1.0!');

%% ========================================================================
% MAIN ANALYSIS PIPELINE
% ========================================================================

fprintf('\n');
fprintf('==============================================================\n');
fprintf(' ISRU LUNAR SITE SUITABILITY ANALYSIS - MCDA FRAMEWORK\n');
fprintf('==============================================================\n\n');

%% ------------------------------------------------------------------------
% STEP 1: Load Input Data Files
% -------------------------------------------------------------------------
fprintf('STEP 1: Loading input data files...\n');

try
    data_FeO = read_txt_data(fullfile(input_folder, files.FeO));
    data_Glass = read_txt_data(fullfile(input_folder, files.Glass));
    data_OH = read_txt_data(fullfile(input_folder, files.OH));
    data_OMAT = read_txt_data(fullfile(input_folder, files.OMAT));
    data_TiO2 = read_txt_data(fullfile(input_folder, files.TiO2));
catch ME
    error('Error loading files: %s\nCheck that all files exist in: %s', ...
        ME.message, input_folder);
end

fprintf('  All files loaded successfully.\n\n');

%% ------------------------------------------------------------------------
% STEP 2: Verify Spatial Alignment
% -------------------------------------------------------------------------
fprintf('STEP 2: Verifying coordinate alignment...\n');

% Use FeO as reference grid
ref_X = data_FeO.X;
ref_Y = data_FeO.Y;
n_pixels = length(ref_X);

% Check if all files have same coordinates
tol = 1e-6;  % Tolerance: ~0.03 m at lunar equator
aligned = true;

datasets = {data_Glass, data_OH, data_OMAT, data_TiO2};
dataset_names = {'Glass', 'OH', 'OMAT', 'TiO2'};

for i = 1:length(datasets)
    if length(datasets{i}.X) ~= n_pixels
        warning('%s has different number of points (%d vs %d)', ...
            dataset_names{i}, length(datasets{i}.X), n_pixels);
        aligned = false;
    elseif any(abs(datasets{i}.X - ref_X) > tol) || ...
           any(abs(datasets{i}.Y - ref_Y) > tol)
        warning('%s coordinates do not match reference (FeO)', dataset_names{i});
        aligned = false;
    end
end

if aligned
    fprintf('  All datasets are spatially aligned (%d pixels).\n\n', n_pixels);
else
    fprintf('  WARNING: Datasets may not be aligned. Consider interpolation.\n\n');
end

%% ------------------------------------------------------------------------
% STEP 3: Extract Value Arrays
% -------------------------------------------------------------------------
fprintf('STEP 3: Extracting parameter values...\n');

V_FeO = data_FeO.Value;
V_Glass = data_Glass.Value;
V_OH = data_OH.Value;
V_OMAT = data_OMAT.Value;
V_TiO2 = data_TiO2.Value;

%% ------------------------------------------------------------------------
% STEP 3b: Handle NoData Values
% -------------------------------------------------------------------------
fprintf('\nSTEP 3b: Detecting and masking NoData values...\n');
fprintf('  NoData threshold: values < %.2e\n', NODATA_THRESHOLD);

% Create validity masks for each parameter
valid_FeO = V_FeO > NODATA_THRESHOLD;
valid_Glass = V_Glass > NODATA_THRESHOLD;
valid_OH = V_OH > NODATA_THRESHOLD;
valid_OMAT = V_OMAT > NODATA_THRESHOLD;
valid_TiO2 = V_TiO2 > NODATA_THRESHOLD;

% Report NoData counts
fprintf('  NoData pixels detected:\n');
fprintf('    FeO:   %d (%.2f%%)\n', sum(~valid_FeO), 100*sum(~valid_FeO)/n_pixels);
fprintf('    Glass: %d (%.2f%%)\n', sum(~valid_Glass), 100*sum(~valid_Glass)/n_pixels);
fprintf('    OH:    %d (%.2f%%)\n', sum(~valid_OH), 100*sum(~valid_OH)/n_pixels);
fprintf('    OMAT:  %d (%.2f%%)\n', sum(~valid_OMAT), 100*sum(~valid_OMAT)/n_pixels);
fprintf('    TiO2:  %d (%.2f%%)\n', sum(~valid_TiO2), 100*sum(~valid_TiO2)/n_pixels);

% Combined validity mask: pixel valid only if ALL parameters are valid
valid_mask = valid_FeO & valid_Glass & valid_OH & valid_OMAT & valid_TiO2;
n_valid = sum(valid_mask);
n_nodata = sum(~valid_mask);

fprintf('\n  Combined mask results:\n');
fprintf('    Valid pixels:  %d (%.2f%%)\n', n_valid, 100*n_valid/n_pixels);
fprintf('    NoData pixels: %d (%.2f%%)\n\n', n_nodata, 100*n_nodata/n_pixels);

% Replace NoData with NaN for clean calculations
V_FeO(~valid_FeO) = NaN;
V_Glass(~valid_Glass) = NaN;
V_OH(~valid_OH) = NaN;
V_OMAT(~valid_OMAT) = NaN;
V_TiO2(~valid_TiO2) = NaN;

% Display statistics (only valid data)
fprintf('  Parameter Statistics (valid data only):\n');
fprintf('    %-10s Min: %10.4f Max: %10.4f Mean: %10.4f\n', ...
    'FeO', nanmin(V_FeO), nanmax(V_FeO), nanmean(V_FeO));
fprintf('    %-10s Min: %10.4f Max: %10.4f Mean: %10.4f\n', ...
    'Glass', nanmin(V_Glass), nanmax(V_Glass), nanmean(V_Glass));
fprintf('    %-10s Min: %10.4f Max: %10.4f Mean: %10.4f\n', ...
    'OH', nanmin(V_OH), nanmax(V_OH), nanmean(V_OH));
fprintf('    %-10s Min: %10.4f Max: %10.4f Mean: %10.4f\n', ...
    'OMAT', nanmin(V_OMAT), nanmax(V_OMAT), nanmean(V_OMAT));
fprintf('    %-10s Min: %10.4f Max: %10.4f Mean: %10.4f\n\n', ...
    'TiO2', nanmin(V_TiO2), nanmax(V_TiO2), nanmean(V_TiO2));

%% ------------------------------------------------------------------------
% STEP 4: Compute Normalized Parameter Functions
% -------------------------------------------------------------------------
fprintf('STEP 4: Computing normalized parameter functions...\n');

% f_oxides: Combined TiO2 + FeO function (literature-based normalization)
% Uses absolute reference values, not min-max
f_ox = f_oxides(V_TiO2, V_FeO, TiO2_ref, FeO_ref);

% f_glass: MIN-MAX normalized to 0-10 (ignoring NaN)
f_glass = normalize_minmax_nan(V_Glass, 10);

% f_OMAT: MIN-MAX normalized to 0-10 (ignoring NaN)
f_OMAT = normalize_minmax_nan(V_OMAT, 10);

% f_OH: MIN-MAX normalized to 0-10 (ignoring NaN)
f_OH = normalize_minmax_nan(V_OH, 10);

% f_Fe: MIN-MAX normalized to 0-10 (for volatile score, different from f_oxides)
f_Fe = normalize_minmax_nan(V_FeO, 10);

fprintf('  Normalization complete.\n\n');

%% ------------------------------------------------------------------------
% STEP 5: Calculate MCDA Domain Scores
% -------------------------------------------------------------------------
fprintf('STEP 5: Calculating MCDA domain scores...\n');

% -------------------------------------------------------------------------
% S_O2: Oxygen Extraction Potential Score
% -------------------------------------------------------------------------
S_O2 = w_O2_oxides .* f_ox + w_O2_glass .* f_glass;

% Rescale to 0-10 because weights don't sum to 1.0
current_weight_sum_O2 = w_O2_oxides + w_O2_glass;
S_O2 = S_O2 / current_weight_sum_O2;

% -------------------------------------------------------------------------
% S_volatiles: Volatile Extraction Potential Score
% -------------------------------------------------------------------------
S_volatiles = w_vol_glass .* f_glass + ...
              w_vol_OMAT .* f_OMAT + ...
              w_vol_OH .* f_OH + ...
              w_vol_Fe .* f_Fe;

% Verify weight sum (should already be 1.0 from earlier assertion)
weight_sum_vol = w_vol_glass + w_vol_OMAT + w_vol_OH + w_vol_Fe;
if abs(weight_sum_vol - 1.0) > 0.001
    warning('Volatile weights sum to %.3f, not 1.0. Normalizing...', weight_sum_vol);
    S_volatiles = S_volatiles / weight_sum_vol;
end

% -------------------------------------------------------------------------
% S_combined: Combined Suitability Score
% -------------------------------------------------------------------------
w_O2_combined = 0.5;
w_vol_combined = 0.5;
S_combined = w_O2_combined .* S_O2 + w_vol_combined .* S_volatiles;

fprintf('  Score calculation complete.\n\n');

%% ------------------------------------------------------------------------
% STEP 6: Display Score Statistics
% -------------------------------------------------------------------------
fprintf('STEP 6: Score Statistics (valid pixels only):\n\n');

fprintf('  %-20s Min: %6.3f Max: %6.3f Mean: %6.3f Std: %6.3f\n', ...
    'S_O2', nanmin(S_O2), nanmax(S_O2), nanmean(S_O2), nanstd(S_O2));
fprintf('  %-20s Min: %6.3f Max: %6.3f Mean: %6.3f Std: %6.3f\n', ...
    'S_volatiles', nanmin(S_volatiles), nanmax(S_volatiles), nanmean(S_volatiles), nanstd(S_volatiles));
fprintf('  %-20s Min: %6.3f Max: %6.3f Mean: %6.3f Std: %6.3f\n\n', ...
    'S_combined', nanmin(S_combined), nanmax(S_combined), nanmean(S_combined), nanstd(S_combined));

%% ------------------------------------------------------------------------
% STEP 7: Save Output Files
% -------------------------------------------------------------------------
fprintf('STEP 7: Saving output files...\n');

% Save suitability scores
write_txt_output(fullfile(output_folder, 'S_O2_score.txt'), S_O2, ref_X, ref_Y);
write_txt_output(fullfile(output_folder, 'S_volatiles_score.txt'), S_volatiles, ref_X, ref_Y);
write_txt_output(fullfile(output_folder, 'S_combined_score.txt'), S_combined, ref_X, ref_Y);

% Save normalized parameter functions (for QA/QC)
write_txt_output(fullfile(output_folder, 'f_oxides_norm.txt'), f_ox, ref_X, ref_Y);
write_txt_output(fullfile(output_folder, 'f_glass_norm.txt'), f_glass, ref_X, ref_Y);
write_txt_output(fullfile(output_folder, 'f_OMAT_norm.txt'), f_OMAT, ref_X, ref_Y);
write_txt_output(fullfile(output_folder, 'f_OH_norm.txt'), f_OH, ref_X, ref_Y);
write_txt_output(fullfile(output_folder, 'f_Fe_norm.txt'), f_Fe, ref_X, ref_Y);

% Save validity mask
write_txt_output(fullfile(output_folder, 'valid_mask.txt'), double(valid_mask), ref_X, ref_Y);

fprintf('  Output files saved to: %s\n\n', output_folder);

%% ------------------------------------------------------------------------
% STEP 8: Generate Analysis Report
% -------------------------------------------------------------------------
fprintf('STEP 8: Generating analysis report...\n');

report_file = fullfile(output_folder, 'MCDA_Analysis_Report.txt');
fid = fopen(report_file, 'w');

fprintf(fid, '==============================================================\n');
fprintf(fid, ' ISRU LUNAR SITE SUITABILITY ANALYSIS - MCDA REPORT\n');
fprintf(fid, '==============================================================\n\n');
fprintf(fid, 'Analysis Date: %s\n', datestr(now));
fprintf(fid, 'Total Pixels: %d\n', n_pixels);
fprintf(fid, 'Valid Pixels: %d (%.2f%%)\n', n_valid, 100*n_valid/n_pixels);
fprintf(fid, 'NoData Pixels: %d (%.2f%%)\n\n', n_nodata, 100*n_nodata/n_pixels);

fprintf(fid, '--------------------------------------------------------------\n');
fprintf(fid, ' NODATA HANDLING\n');
fprintf(fid, '--------------------------------------------------------------\n\n');
fprintf(fid, 'NoData threshold: values < %.2e\n', NODATA_THRESHOLD);
fprintf(fid, 'NoData pixels per parameter:\n');
fprintf(fid, '  FeO:   %d (%.2f%%)\n', sum(~valid_FeO), 100*sum(~valid_FeO)/n_pixels);
fprintf(fid, '  Glass: %d (%.2f%%)\n', sum(~valid_Glass), 100*sum(~valid_Glass)/n_pixels);
fprintf(fid, '  OH:    %d (%.2f%%)\n', sum(~valid_OH), 100*sum(~valid_OH)/n_pixels);
fprintf(fid, '  OMAT:  %d (%.2f%%)\n', sum(~valid_OMAT), 100*sum(~valid_OMAT)/n_pixels);
fprintf(fid, '  TiO2:  %d (%.2f%%)\n\n', sum(~valid_TiO2), 100*sum(~valid_TiO2)/n_pixels);

fprintf(fid, '--------------------------------------------------------------\n');
fprintf(fid, ' WEIGHT CONFIGURATION\n');
fprintf(fid, '--------------------------------------------------------------\n\n');
fprintf(fid, 'Oxygen Extraction Score (S_O2):\n');
fprintf(fid, '  w_oxides (TiO2+FeO): %.2f (normalized to %.2f)\n', ...
    w_O2_oxides, w_O2_oxides/current_weight_sum_O2);
fprintf(fid, '  w_glass: %.2f (normalized to %.2f)\n\n', ...
    w_O2_glass, w_O2_glass/current_weight_sum_O2);

fprintf(fid, 'Volatile Extraction Score (S_volatiles):\n');
fprintf(fid, '  w_glass: %.2f\n', w_vol_glass);
fprintf(fid, '  w_OMAT:  %.2f\n', w_vol_OMAT);
fprintf(fid, '  w_OH:    %.2f\n', w_vol_OH);
fprintf(fid, '  w_Fe:    %.2f\n', w_vol_Fe);
fprintf(fid, '  Sum:     %.2f\n\n', weight_sum_vol);

fprintf(fid, '--------------------------------------------------------------\n');
fprintf(fid, ' INPUT PARAMETER STATISTICS (valid data only)\n');
fprintf(fid, '--------------------------------------------------------------\n\n');
fprintf(fid, '%-10s %12s %12s %12s\n', 'Parameter', 'Min', 'Max', 'Mean');
fprintf(fid, '%-10s %12.4f %12.4f %12.4f\n', 'FeO', nanmin(V_FeO), nanmax(V_FeO), nanmean(V_FeO));
fprintf(fid, '%-10s %12.4f %12.4f %12.4f\n', 'Glass', nanmin(V_Glass), nanmax(V_Glass), nanmean(V_Glass));
fprintf(fid, '%-10s %12.4f %12.4f %12.4f\n', 'OH', nanmin(V_OH), nanmax(V_OH), nanmean(V_OH));
fprintf(fid, '%-10s %12.4f %12.4f %12.4f\n', 'OMAT', nanmin(V_OMAT), nanmax(V_OMAT), nanmean(V_OMAT));
fprintf(fid, '%-10s %12.4f %12.4f %12.4f\n\n', 'TiO2', nanmin(V_TiO2), nanmax(V_TiO2), nanmean(V_TiO2));

fprintf(fid, '--------------------------------------------------------------\n');
fprintf(fid, ' OUTPUT SCORE STATISTICS (valid data only)\n');
fprintf(fid, '--------------------------------------------------------------\n\n');
fprintf(fid, '%-20s %8s %8s %8s %8s\n', 'Score', 'Min', 'Max', 'Mean', 'Std');
fprintf(fid, '%-20s %8.3f %8.3f %8.3f %8.3f\n', ...
    'S_O2', nanmin(S_O2), nanmax(S_O2), nanmean(S_O2), nanstd(S_O2));
fprintf(fid, '%-20s %8.3f %8.3f %8.3f %8.3f\n', ...
    'S_volatiles', nanmin(S_volatiles), nanmax(S_volatiles), nanmean(S_volatiles), nanstd(S_volatiles));
fprintf(fid, '%-20s %8.3f %8.3f %8.3f %8.3f\n\n', ...
    'S_combined', nanmin(S_combined), nanmax(S_combined), nanmean(S_combined), nanstd(S_combined));

fprintf(fid, '--------------------------------------------------------------\n');
fprintf(fid, ' TOP 10 HIGHEST SCORING LOCATIONS (valid pixels only)\n');
fprintf(fid, '--------------------------------------------------------------\n\n');

% Find top 10 for S_combined (excluding NaN)
S_combined_valid = S_combined;
S_combined_valid(~valid_mask) = -Inf;
[~, sort_idx] = sort(S_combined_valid, 'descend');

fprintf(fid, '%-5s %12s %12s %10s %10s %10s\n', 'Rank', 'X', 'Y', 'S_O2', 'S_vol', 'S_comb');
for i = 1:min(10, n_valid)
    idx = sort_idx(i);
    fprintf(fid, '%-5d %12.4f %12.4f %10.3f %10.3f %10.3f\n', ...
        i, ref_X(idx), ref_Y(idx), S_O2(idx), S_volatiles(idx), S_combined(idx));
end

fprintf(fid, '\n==============================================================\n');
fprintf(fid, ' END OF REPORT\n');
fprintf(fid, '==============================================================\n');
fclose(fid);

fprintf('  Report saved to: %s\n\n', report_file);

%% ------------------------------------------------------------------------
% STEP 9: Generate Visualizations
% -------------------------------------------------------------------------
fprintf('STEP 9: Generating visualizations...\n');

try
    % Figure 1: Fixed 0-10 scale
    figure('Position', [100, 100, 1400, 500]);
    
    subplot(1, 3, 1);
    scatter(ref_X(valid_mask), ref_Y(valid_mask), 5, S_O2(valid_mask), 'filled');
    colorbar; colormap(jet); caxis([0 10]);
    xlabel('X (Longitude)'); ylabel('Y (Latitude)');
    title('S_{O2} - Oxygen Extraction Potential');
    axis equal; grid on;
    
    subplot(1, 3, 2);
    scatter(ref_X(valid_mask), ref_Y(valid_mask), 5, S_volatiles(valid_mask), 'filled');
    colorbar; colormap(jet); caxis([0 10]);
    xlabel('X (Longitude)'); ylabel('Y (Latitude)');
    title('S_{volatiles} - Volatile Extraction Potential');
    axis equal; grid on;
    
    subplot(1, 3, 3);
    scatter(ref_X(valid_mask), ref_Y(valid_mask), 5, S_combined(valid_mask), 'filled');
    colorbar; colormap(jet); caxis([0 10]);
    xlabel('X (Longitude)'); ylabel('Y (Latitude)');
    title('S_{combined} - Overall ISRU Suitability');
    axis equal; grid on;
    
    saveas(gcf, fullfile(output_folder, 'MCDA_Visualization.png'));
    saveas(gcf, fullfile(output_folder, 'MCDA_Visualization.fig'));
    
    % Figure 2: Auto-scaled
    figure('Position', [100, 100, 1400, 500]);
    sgtitle('MCDA Scores - Scaled to Actual Data Range', 'FontSize', 14, 'FontWeight', 'bold');
    
    subplot(1, 3, 1);
    scatter(ref_X(valid_mask), ref_Y(valid_mask), 5, S_O2(valid_mask), 'filled');
    cb1 = colorbar; colormap(jet); caxis([nanmin(S_O2) nanmax(S_O2)]);
    ylabel(cb1, 'Score');
    xlabel('X (Longitude)'); ylabel('Y (Latitude)');
    title(sprintf('S_{O2} [%.2f - %.2f]', nanmin(S_O2), nanmax(S_O2)));
    axis equal; grid on;
    
    subplot(1, 3, 2);
    scatter(ref_X(valid_mask), ref_Y(valid_mask), 5, S_volatiles(valid_mask), 'filled');
    cb2 = colorbar; colormap(jet); caxis([nanmin(S_volatiles) nanmax(S_volatiles)]);
    ylabel(cb2, 'Score');
    xlabel('X (Longitude)'); ylabel('Y (Latitude)');
    title(sprintf('S_{volatiles} [%.2f - %.2f]', nanmin(S_volatiles), nanmax(S_volatiles)));
    axis equal; grid on;
    
    subplot(1, 3, 3);
    scatter(ref_X(valid_mask), ref_Y(valid_mask), 5, S_combined(valid_mask), 'filled');
    cb3 = colorbar; colormap(jet); caxis([nanmin(S_combined) nanmax(S_combined)]);
    ylabel(cb3, 'Score');
    xlabel('X (Longitude)'); ylabel('Y (Latitude)');
    title(sprintf('S_{combined} [%.2f - %.2f]', nanmin(S_combined), nanmax(S_combined)));
    axis equal; grid on;
    
    saveas(gcf, fullfile(output_folder, 'MCDA_Visualization_AutoScale.png'));
    saveas(gcf, fullfile(output_folder, 'MCDA_Visualization_AutoScale.fig'));
    
    fprintf('  Visualizations saved.\n\n');
catch ME
    fprintf('  Note: Visualization skipped. Error: %s\n\n', ME.message);
end

%% ------------------------------------------------------------------------
% ANALYSIS COMPLETE
% -------------------------------------------------------------------------
fprintf('==============================================================\n');
fprintf(' ANALYSIS COMPLETE\n');
fprintf('==============================================================\n\n');

fprintf('Output files generated:\n');
fprintf('  - S_O2_score.txt\n');
fprintf('  - S_volatiles_score.txt\n');
fprintf('  - S_combined_score.txt\n');
fprintf('  - f_oxides_norm.txt\n');
fprintf('  - f_glass_norm.txt\n');
fprintf('  - f_OMAT_norm.txt\n');
fprintf('  - f_OH_norm.txt\n');
fprintf('  - f_Fe_norm.txt\n');
fprintf('  - valid_mask.txt\n');
fprintf('  - MCDA_Analysis_Report.txt\n');
fprintf('  - MCDA_Visualization.png/.fig\n\n');

%% ========================================================================
% HELPER FUNCTIONS
% ========================================================================

%% ------------------------------------------------------------------------
% FUNCTION: Read TXT file with Value, X, Y columns
% -------------------------------------------------------------------------
function [data] = read_txt_data(filepath)
    % Reads TXT file with header "Value X Y"
    % Returns structure with fields: Value, X, Y
    
    try
        % Try reading as table first
        raw = readtable(filepath, 'FileType', 'text', 'Delimiter', '\t');
        if width(raw) ~= 3
            raw = readtable(filepath, 'FileType', 'text', 'Delimiter', ' ');
        end
        data.Value = raw{:, 1};
        data.X = raw{:, 2};
        data.Y = raw{:, 3};
    catch
        % Fallback: manual parsing
        fid = fopen(filepath, 'r');
        header = fgetl(fid);  % Skip header
        rawData = textscan(fid, '%f %f %f');
        fclose(fid);
        
        data.Value = rawData{1};
        data.X = rawData{2};
        data.Y = rawData{3};
    end
    
    data.n = length(data.Value);
    fprintf('  Loaded %d points from %s\n', data.n, filepath);
end

%% ------------------------------------------------------------------------
% FUNCTION: MIN-MAX Normalization (NaN-aware)
% -------------------------------------------------------------------------
function [normalized] = normalize_minmax_nan(values, scale_max)
    % Normalizes values to 0-scale_max using MIN-MAX method
    % NaN values are preserved (not included in min/max calculation)
    
    if nargin < 2
        scale_max = 10;
    end
    
    v_min = nanmin(values);
    v_max = nanmax(values);
    
    if v_max == v_min
        % Constant values: assign middle score
        normalized = ones(size(values)) * scale_max / 2;
        normalized(isnan(values)) = NaN;
    else
        normalized = scale_max * (values - v_min) / (v_max - v_min);
        % NaN propagates automatically
    end
end

%% ------------------------------------------------------------------------
% FUNCTION: f_oxides - Combined TiO2+FeO function
% -------------------------------------------------------------------------
function [f_ox] = f_oxides(TiO2, FeO, TiO2_ref, FeO_ref)
    % Combined oxide function for oxygen yield prediction
    % f_oxides = 10 * [(TiO2/TiO2_ref)*0.4 + (FeO/FeO_ref)*0.6]
    % NaN values propagate through calculation
    
    f_ox = 10 .* ((TiO2 / TiO2_ref) .* 0.4 + (FeO / FeO_ref) .* 0.6);
    f_ox = min(f_ox, 10);  % Cap at maximum score
    f_ox = max(f_ox, 0);   % Ensure non-negative
end

%% ------------------------------------------------------------------------
% FUNCTION: Write output TXT file
% -------------------------------------------------------------------------
function write_txt_output(filepath, values, X, Y)
    fid = fopen(filepath, 'w');
    fprintf(fid, 'Value\tX\tY\n');
    
    for i = 1:length(values)
        if isnan(values(i))
            fprintf(fid, 'NaN\t%.6f\t%.6f\n', X(i), Y(i));
        else
            fprintf(fid, '%.6f\t%.6f\t%.6f\n', values(i), X(i), Y(i));
        end
    end
    
    fclose(fid);
    fprintf('  Saved: %s\n', filepath);
end

%% ------------------------------------------------------------------------
% NaN-aware statistical functions
% -------------------------------------------------------------------------
function m = nanmin(x)
    m = min(x(~isnan(x)));
end

function m = nanmax(x)
    m = max(x(~isnan(x)));
end

function m = nanmean(x)
    m = mean(x(~isnan(x)));
end

function s = nanstd(x)
    s = std(x(~isnan(x)));
end
