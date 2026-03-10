%% Figure 2 (Supplementary Material): Evolutionary Dynamics Across Population Types
% This script simulates the evolutionary transition of cooperation and 
% environmental expectation (ee) values under two different social payoff 
% intensities (pi_social = 0.9 and 1.0). 
% It compares how different initial distributions influence the steady state.

clear all; clc; close all;

%% --- 1. PARAMETERS & CONFIGURATION ---
gn = 3000;          % Number of generations per iteration
iterations = 500;   % Statistical samples for publication-quality error bars
pop_type_list  = [1, 2, 3, 4]; % Left-skewed, Uniform, Normal, Right-skewed
fixed_del_Pay_list = [0.9, 1.0]; % Social payoff values for panels (a) and (b)

% Formatting and Visuals
labels = {'$\gamma < 0$ ', '$\mathcal{U}(0, N)$', '$\mathcal{N}(\mu, \sigma^2)$ ', '$\gamma > 0$'};
c_coop = [49, 130, 189]/255;  % Blue: Cooperation level
c_ee   = [228, 26, 28]/255;   % Red: ee (threshold) values
figure('Color', 'w', 'Position', [50 100 1600 600]); 

%% --- 2. SIMULATION ENGINE ---
% Outer loop iterates through different social payoff scenarios
for p = 1:length(fixed_del_Pay_list)
    del_Pay = fixed_del_Pay_list(p);
    
    asymp_coop_mean = zeros(length(pop_type_list), 1);
    asymp_ee_mean   = zeros(length(pop_type_list), 1);
    coop_CI = zeros(length(pop_type_list), 1);
    ee_CI   = zeros(length(pop_type_list), 1);
    
    % Loop through each population distribution type
    for a = 1:length(pop_type_list)
        current_pop_type = pop_type_list(a);
        
        % Fixed simulation constants
        N = 100;              % Population size
        in_coop_fr = 0.52;    % Initial fraction of cooperators
        beeta = 2;            % Sigmoid intensity for decision making
        E = 10; h = 2; donation_cost = 1; % Payoff parameters
        switch_norm = 1;      % Toggle for social norm payoff
        mutation_rate = 0.01; % Probability of threshold mutation
        eta = 2;              % Selection pressure (imitation intensity)
        
        iter_results_coop = zeros(iterations, 1);
        iter_results_ee   = zeros(iterations, 1);
        
        for itr = 1:iterations
            % Initialize thresholds using the external function
            ee_init = round(generate_pop_distribution(current_pop_type, N));
            current_ee = ee_init(:); 
            
            % Initialize state
            current_nC = round(in_coop_fr * N);
            history_coop = zeros(gn, 1);
            history_ee   = zeros(gn, 1);
            
            for g = 1:gn
                % STAGE 1: Decision Phase
                q = 1 ./ (1 + exp(-beeta * (current_nC - current_ee))); 
                is_C = rand(N, 1) < q;
                actn = sum(is_C);
                
                % STAGE 2: Payoff Calculation
                benefit = (h * actn * donation_cost) / N;
                payoffs = zeros(N, 1);
                payoffs(is_C) = E - donation_cost + benefit;
                payoffs(~is_C) = E + benefit;
                
                if switch_norm > 0
                    if actn >= N/2 
                        payoffs(is_C) = payoffs(is_C) + del_Pay;
                    else
                        payoffs(~is_C) = payoffs(~is_C) + del_Pay;
                    end
                end
                
                % STAGE 3: Evolutionary Phase
                partner_idx = randi(N, N, 1);
                pay_diff = payoffs(partner_idx) - payoffs; 
                prob_imitate = 1 ./ (1 + exp(-eta * pay_diff));
                to_imitate = (pay_diff > 0) & (rand(N, 1) < prob_imitate);
                current_ee(to_imitate) = current_ee(partner_idx(to_imitate));
                
                % STAGE 4: Mutation
                mut_mask = rand(N, 1) < mutation_rate;
                if any(mut_mask)
                    current_ee(mut_mask) = current_ee(mut_mask) + randi([-5 5], sum(mut_mask), 1);
                    current_ee = max(min(current_ee, N), 0);
                end
                
                current_nC = actn;
                history_coop(g) = actn / N;
                history_ee(g)   = mean(current_ee);
            end 
            
            x_asym = max(1, ceil(gn - gn * 0.10)); 
            iter_results_coop(itr) = mean(history_coop(x_asym : gn));
            iter_results_ee(itr)   = mean(history_ee(x_asym : gn));
        end 
        
        asymp_coop_mean(a) = mean(iter_results_coop);
        asymp_ee_mean(a)   = mean(iter_results_ee);
        coop_CI(a) = 1.96 * (std(iter_results_coop) / sqrt(iterations));
        ee_CI(a)   = 1.96 * (std(iter_results_ee) / sqrt(iterations));
    end
    
    %% --- 3. PLOTTING RESULTS ---
   %% --- 3. PLOTTING RESULTS ---
    subplot(1, 2, p);
    ax = gca; hold on; box on;
    
    bw = 0.3; % Bar width
    x_pos = 1:length(pop_type_list);
    
    % Left Axis: Cooperation Levels
    yyaxis left
    bar(x_pos - bw/2, asymp_coop_mean, bw, 'FaceColor', c_coop, 'EdgeColor', 'none');
    errorbar(x_pos - bw/2, asymp_coop_mean, coop_CI, 'k.', 'linestyle', 'none', 'LineWidth', 1.2);
    ylabel('asymptotic cooperation', 'Interpreter', 'latex');
    ax.YAxis(1).Color = c_coop;
    ylim([0 1.05]); 
    
    % Right Axis: ee (Threshold) Values
    yyaxis right
    bar(x_pos + bw/2, asymp_ee_mean, bw, 'FaceColor', c_ee, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
    errorbar(x_pos + bw/2, asymp_ee_mean, ee_CI, 'k.', 'linestyle', 'none', 'LineWidth', 1.2);
    ylabel('asymptotic $ee$ value', 'Interpreter', 'latex');
    ax.YAxis(2).Color = c_ee;
    ylim([0 N]); 
    
    % --- THE OVERRIDE FIX ---
  
      % Force the X-axis and its tick labels to be a neutral dark gray.
    % We apply this at the very end to prevent yyaxis from switching it back to red.
    ax.XLabel.Color = [0.5 0.5 0.5];
    ax.XAxis.TickLabelColor = [0.5 0.5 0.5];
    % ------------------------

    
    xticks(x_pos);
    xticklabels(labels);
    set(ax, 'TickLabelInterpreter', 'latex', 'FontSize', 14);
    title(['$\pi^{social} = ', num2str(del_Pay), '$'], 'Interpreter', 'latex');

    
end