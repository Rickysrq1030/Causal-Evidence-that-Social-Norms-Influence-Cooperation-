%% Figure 1 (Supplementary Material): Initial Population Distributions
% This script visualizes the four initial population types based on their 
% environmental expectation (ee) values. The distributions include:
% (a) Uniform, (b) Normal, (c) Right-Skewed, and (d) Left-Skewed.

clear; close all; clc;

% --- 1. PARAMETER DEFINITIONS ---
N = 100;           % Maximum possible ee value (population capacity)
pop_size = 100;   % Number of samples for smooth distribution visualization
binWidth = 5;      % Width of histogram bins
dist_type = [2, 3, 4, 1]; % Order: Uniform (2), Normal (3), Right (4), Left (1)

% --- 2. COLOR PALETTE (For Publication Quality) ---
colors_plot = [ ...
    0.05, 0.45, 0.65;  ...  % Panel (a): Deep Teal-Blue 
    0.80, 0.35, 0.10;  ...  % Panel (b): Burnt Orange 
    0.30, 0.60, 0.30;  ...  % Panel (c): Emerald Green 
    0.65, 0.15, 0.55   ...  % Panel (d): Deep Magenta
]; 

% --- 3. LABELS AND ANNOTATIONS ---
dist_labels = {'$\mathcal{U}(0, N)$', '$\mathcal{N}(\mu, \sigma^2)$', '$\gamma > 0$', '$\gamma < 0$'};
% panel_labels = {'a', 'b', 'c', 'd'}; 

% --- 4. PLOTTING LOOP ---
figure('Position', [200, 200, 1400, 1200], 'Color', 'w');

for i = 1:length(dist_type)
    current_dist = dist_type(i);
    
    % Call the distribution generator function
    samples = generate_pop_distribution(current_dist, N);
    
    subplot(2, 2, i);
    
    % Render Histogram as Probability Density
    h = histogram(samples, 'Normalization', 'probability', 'BinWidth', binWidth);
    h.FaceColor = colors_plot(i,:);
    h.EdgeColor = [0.1 0.1 0.1]; 
    h.LineWidth = 0.5;
    
    % Axis Constraints
    xlim([-2, 102]); 
    ylim([0, 0.25]); 
    
    % Visual Styling
    ax = gca;
    set(ax, 'LineWidth', 1.5, 'TickDir', 'out', 'Box', 'off', ...
            'XGrid', 'off', 'YGrid', 'on', 'GridColor', [0.9 0.9 0.9], ...
            'GridAlpha', 0.5, 'FontName', 'Helvetica', 'FontSize', 24, ...
            'XColor', [0 0 0], 'YColor', [0 0 0]);
    
    xlabel('$ee$ values', 'Interpreter', 'latex', 'FontSize', 28);
    
    % Ensure Y-axis labels only appear on the left panels
    if i == 1 || i == 3 
         ylabel('Probability', 'Interpreter', 'latex', 'FontSize', 28);
    else
         set(ax, 'YTickLabel', []);
    end
    
    % Panel Title
    % title_text = ['\textbf{', panel_labels{i}, '} ', dist_labels{i}];
    % title(title_text, 'Interpreter', 'latex', 'FontSize', 32, 'HorizontalAlignment', 'center');
end

% --- 5. GLOBAL FIGURE ANNOTATION ---
annotation('textbox', [0.15, 0.95, 0.7, 0.04], ... 
    'String', ['population size ($N=', num2str(N), '$)'], ... 
    'Interpreter', 'latex', ...
    'FontSize', 36, ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'Color', [0.1 0.1 0.1]);

%% --- SUPPORTING FUNCTION ---
% This function generates the specific population distributions.
% It is used across all simulation scripts to ensure consistency.
function samples = generate_pop_distribution(dist_type, N)
    mu = N / 2;
    sigma = N / 6;
    pop_size = N * 10; 
    
    switch dist_type
        case 1 % Left skew ($\gamma < 0$)
            m = log(mu^2 / sqrt(sigma^2 + mu^2));
            s = sqrt(log(1 + sigma^2 / mu^2));
            right_skew = lognrnd(m, s, 1, pop_size);
            samples = N - right_skew;
        case 2 % Uniform ($\mathcal{U}$)
            samples = rand(1, pop_size) * N;
        case 3 % Normal ($\mathcal{N}$)
            samples = normrnd(mu, sigma, 1, pop_size);
        case 4 % Right skew ($\gamma > 0$)
            m = log(mu^2 / sqrt(sigma^2 + mu^2));
            s = sqrt(log(1 + sigma^2 / mu^2));
            samples = lognrnd(m, s, 1, pop_size);
    end
    % Constraints to keep values within [0, N]
    samples = max(0, min(N, samples));
end