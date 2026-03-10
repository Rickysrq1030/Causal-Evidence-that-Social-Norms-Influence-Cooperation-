%% Main Paper: Figure 3 - Impact of Initial Cooperation Levels
% This script analyzes the robustness of the cooperative steady state 
% relative to the initial population state. By varying the starting 
% fraction of cooperators, we identify the threshold required for 
% social norms to successfully sustain cooperation.

clear all; clc; close all;

%% --- 1. PARAMETERS & CONFIGURATION ---
gn = 3000;              % Generations per run
iterations = 100;       % Independent iterations for statistical confidence
mutation_rate = 0.01;   % Threshold mutation probability
current_pop_type = 3;   % Fixed at Normal Distribution
beeta = 2;              % Selection intensity (Decision Stage)
eta = 2;                % Selection pressure (Evolutionary Stage)
pop_size = 100; N = pop_size;
E = 10; h = 2; donation_cost = 1; % Game constants
switch_norm = 1;        % Activate Social Norm

% Experimental Variables
in_coop_values = [0.45, 0.47, 0.49, 0.51, 0.53, 0.55]; % X-axis sweep
social_payoff_list = [0.9, 1];                         % Panel A vs Panel B

% Visual Aesthetics
c_coop = [49, 130, 189]/255;  % Blue: Cooperation
c_ee   = [228, 26, 28]/255;   % Red: ee values
figure('Color', 'w', 'Position', [100 100 1000 400]);

%% --- 2. SIMULATION ENGINE ---
for s = 1:length(social_payoff_list)
    fixed_del_Pay = social_payoff_list(s);
    
    n_points = length(in_coop_values);
    asymp_coop = zeros(n_points, 1);
    asymp_ee   = zeros(n_points, 1);
    coop_CI    = zeros(n_points, 1);
    ee_CI      = zeros(n_points, 1);
    
    for a = 1:n_points
        this_in_coop = in_coop_values(a);
        iter_res_coop = zeros(iterations, 1);
        iter_res_ee   = zeros(iterations, 1);
        
        for itr = 1:iterations
            % Initialize thresholds and state
            ee = round(generate_pop_distribution(current_pop_type, N));
            current_ee = ee(:);            
            current_nC = round(this_in_coop * N);
            
            % Buffers for steady-state recording
            h_coop_steady = zeros(300, 1);
            h_ee_steady   = zeros(300, 1);
            
            for g = 1:gn
                % STAGE 1: Decision Stage
                q = 1 ./ (1 + exp(-beeta * (current_nC - current_ee))); 
                is_C = rand(N, 1) < q;
                actn = sum(is_C);
                
                % STAGE 2: Payoff Stage
                benefit = (h * actn * donation_cost) / N;
                payoffs = zeros(N, 1);
                payoffs(is_C) = E - donation_cost + benefit;
                payoffs(~is_C) = E + benefit;
                
                if switch_norm > 0
                    if actn > N/2
                        payoffs(is_C) = payoffs(is_C) + fixed_del_Pay;
                    elseif actn < N/2
                        payoffs(~is_C) = payoffs(~is_C) + fixed_del_Pay;
                    end
                end
                
                % STAGE 3: Evolutionary Stage (Social Learning)
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
                
                % Record the final 10% of generations
                if g > (gn - 300)
                    h_coop_steady(g-(gn-300)) = actn / N;
                    h_ee_steady(g-(gn-300))   = mean(current_ee);
                end
            end 
            iter_res_coop(itr) = mean(h_coop_steady);
            iter_res_ee(itr)   = mean(h_ee_steady);
        end 
        
        % Statistical Aggregation (95% CI)
        asymp_coop(a) = mean(iter_res_coop);
        asymp_ee(a)   = mean(iter_res_ee);
        coop_CI(a) = 1.96 * (std(iter_res_coop) / sqrt(iterations));
        ee_CI(a)   = 1.96 * (std(iter_res_ee) / sqrt(iterations));
    end

%% --- 3. PANEL PLOTTING ---
    subplot(1, 2, s); 
    ax = gca; hold on; box on;
    
    % LEFT AXIS: Cooperation (Markers: Blue)
    yyaxis left
    p1 = errorbar(in_coop_values, asymp_coop, coop_CI, '-o', 'Color', c_coop, ...
        'LineWidth', 2, 'MarkerFaceColor', c_coop, 'MarkerSize', 6, 'CapSize', 0);
    ylabel('asymptotic cooperation', 'Interpreter', 'latex', 'FontSize', 18);
    ax.YAxis(1).Color = c_coop; 
    ylim([-0.05 1.05]); yticks(0:0.2:1);

    % RIGHT AXIS: ee Value (Markers: Red)
    yyaxis right
    p2 = errorbar(in_coop_values, asymp_ee, ee_CI, '-s', 'Color', c_ee, ...
        'LineWidth', 2, 'MarkerFaceColor', c_ee, 'MarkerSize', 6, 'CapSize', 0);
    ylabel('asymptotic $ee$ value', 'Interpreter', 'latex', 'FontSize', 18);
    ax.YAxis(2).Color = c_ee; 
    ylim([40 80]); yticks(40:10:80);

    % Formatting
    xlabel('initial cooperation', 'Interpreter', 'latex', 'FontSize', 18);
    title(['$\pi^{social} = ', num2str(fixed_del_Pay), '$'], 'Interpreter', 'latex', 'FontSize', 20);
    
    % Panel labels a and b
    panel_label = char(96 + s); 
    text(-0.15, 1.1, panel_label, 'Units', 'normalized', 'FontSize', 22, 'FontWeight', 'bold');
    
    set(ax, 'FontSize', 14, 'TickLabelInterpreter', 'latex');
end