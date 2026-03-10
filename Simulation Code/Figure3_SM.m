%% Figure 3 (Supplementary Material): Sensitivity Analysis of Beta (Decision Intensity)
% This script investigates the role of the selection intensity parameter (beta) 
% on the emergence of cooperation. It sweeps beta from 0 (random choice) to 
% 2 (highly deterministic choice) across two fixed social payoff values.

clear all; clc; close all;

%% --- 1. PARAMETERS & INITIALIZATION ---
gn = 3000;              % Number of generations
iterations = 500;       % Statistical samples for publication-quality error bars
mutation_rate = 0.01;   % Threshold mutation probability
fixed_in_coop = 0.52;   % Initial cooperation fraction
current_pop_type = 3;   % Fixed at Normal Distribution for this analysis
eta = 2;                % Selection pressure (imitation intensity)
pop_size = 100; N = pop_size;
E = 10; h = 2; donation_cost = 1; % Game payoff constants
switch_norm = 1;        % Toggle for social norm payoffs

% Sweep Range and Comparisons
beeta_list = 0:0.2:2;           % Range of decision intensities (x-axis)
social_payoff_loop = [0.9, 1];  % Comparison values for panels (a) and (b)

% Plotting Aesthetics
c_coop = [49, 130, 189]/255;  % Blue for cooperation
c_ee   = [228, 26, 28]/255;   % Red for ee values
figure('Color', 'w', 'Position', [100 100 1200 500]);

%% --- 2. SIMULATION ENGINE ---
for p = 1:length(social_payoff_loop)
    fixed_del_Pay = social_payoff_loop(p);
    
    % Storage for results over the beta sweep
    asymp_coop = zeros(length(beeta_list), 1);
    asymp_ee   = zeros(length(beeta_list), 1);
    coop_CI    = zeros(length(beeta_list), 1);
    ee_CI      = zeros(length(beeta_list), 1);
    
    for b_idx = 1:length(beeta_list)
        beeta = beeta_list(b_idx);
        
        iter_res_coop = zeros(iterations, 1);
        iter_res_ee   = zeros(iterations, 1);
        
        for itr = 1:iterations
            % Initialize environmental expectations and initial state
            ee = round(generate_pop_distribution(current_pop_type, N));
            current_ee = ee(:);            
            current_nC = round(fixed_in_coop * N);
            
            % Buffers for steady-state recording
            h_coop_steady = zeros(300, 1);
            h_ee_steady   = zeros(300, 1);
            
            for g = 1:gn
                % STAGE 1: Decision Stage
                % Probabilistic cooperation governed by beta
                q = 1 ./ (1 + exp(-beeta * (current_nC - current_ee))); 
                is_C = rand(N, 1) < q;
                actn = sum(is_C);
                
                % STAGE 2: Payoff Stage
                benefit = (h * actn * donation_cost) / N;
                payoffs = zeros(N, 1);
                payoffs(is_C) = E - donation_cost + benefit;
                payoffs(~is_C) = E + benefit;
                
                % Social Payoff Logic
                if switch_norm > 0
                    if actn > N/2
                        payoffs(is_C) = payoffs(is_C) + fixed_del_Pay;
                    elseif actn < N/2
                        payoffs(~is_C) = payoffs(~is_C) + fixed_del_Pay;
                    end
                end
                
                % STAGE 3: Evolutionary Stage (Imitation)
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
                
                % Record the final 300 generations for steady-state analysis
                if g > (gn - 300)
                    h_coop_steady(g-(gn-300)) = actn / N;
                    h_ee_steady(g-(gn-300))   = mean(current_ee);
                end
            end 
            iter_res_coop(itr) = mean(h_coop_steady);
            iter_res_ee(itr)   = mean(h_ee_steady);
        end 
        
        % Statistical Aggregation (95% Confidence Intervals)
        asymp_coop(b_idx) = mean(iter_res_coop);
        asymp_ee(b_idx)   = mean(iter_res_ee);
        coop_CI(b_idx) = 1.96 * (std(iter_res_coop) / sqrt(iterations));
        ee_CI(b_idx)   = 1.96 * (std(iter_res_ee) / sqrt(iterations));
    end

    %% --- 3. PANEL PLOTTING ---
    subplot(1, 2, p);
    ax = gca; hold on; box on;
    
    % LEFT AXIS: Cooperation (Markers: Blue Circles)
    yyaxis left
    p1 = errorbar(beeta_list, asymp_coop, coop_CI, '-o', 'Color', c_coop, ...
        'LineWidth', 2, 'MarkerFaceColor', c_coop, 'MarkerSize', 6, 'CapSize', 0);
    ylabel('asymptotic cooperation', 'Interpreter', 'latex', 'FontSize', 14);
    ax.YAxis(1).Color = c_coop;
    ylim([-0.05 1.05]); yticks(0:0.2:1); 

    % RIGHT AXIS: ee value (Markers: Red Squares)
    yyaxis right
    p2 = errorbar(beeta_list, asymp_ee, ee_CI, '-s', 'Color', c_ee, ...
        'LineWidth', 2, 'MarkerFaceColor', c_ee, 'MarkerSize', 6, 'CapSize', 0);
    ylabel('asymptotic $ee$ value', 'Interpreter', 'latex', 'FontSize', 14);
    ax.YAxis(2).Color = c_ee;
    ylim([40 80]); yticks(40:10:80); 

    % General Formatting
    xlabel('$\beta$', 'Interpreter', 'latex', 'FontSize', 18);
    title(['$\pi^{social} = ', num2str(fixed_del_Pay), '$'], 'Interpreter', 'latex', 'FontSize', 16); 
    set(ax, 'FontSize', 12, 'TickLabelInterpreter', 'latex');
    
    % Panel labels (a, b)
    if p == 1, text(-0.15, 1.1, 'a', 'Units', 'normalized', 'FontSize', 20, 'FontWeight', 'bold'); end
    if p == 2, text(-0.15, 1.1, 'b', 'Units', 'normalized', 'FontSize', 20, 'FontWeight', 'bold'); end
end