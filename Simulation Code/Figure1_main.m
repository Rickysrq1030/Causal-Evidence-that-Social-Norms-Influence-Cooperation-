%% Main Paper: Figure 1 - Baseline Evolutionary Dynamics
% This script investigates the impact of varying social payoff intensities 
% (pi_social) on the emergence of cooperation and the evolution of 
% environmental expectation (ee) values. 
%
% Parameters are set for a Normal distribution (Type 3) with a sweep 
% across the social payoff range from 0 to 1.5.

clear all; clc; close all;

%% --- 1. PARAMETERS & CONFIGURATION ---
gn = 3000;              % Total generations per simulation run
iterations = 500;       % Number of independent iterations for statistical robustness
mutation_rate = 0.01;   % Probability of threshold mutation
fixed_in_coop = 0.52;   % Initial fraction of cooperators (starting state)
current_pop_type = 3;   % Population distribution: Normal Distribution
beeta = 2;              % Selection intensity (Decision Stage)
eta = 2;                % Selection pressure (Evolutionary Stage)
pop_size = 100; N = pop_size;

% Game Payoff Values
E = 10; h = 2; donation_cost = 1;
switch_norm = 1;        % Activate Social Norm Payoffs

% Sweep Range: Social Payoff Intensity
del_Pay_list = 0:0.1:1.5; 

% Visual Identity
c_coop = [49, 130, 189]/255;  % Blue: Cooperation
c_ee   = [228, 26, 28]/255;   % Red: ee value

%% --- 2. SIMULATION LOOP ---
asymp_coop = zeros(length(del_Pay_list), 1);
asymp_ee   = zeros(length(del_Pay_list), 1);
coop_CI    = zeros(length(del_Pay_list), 1);
ee_CI      = zeros(length(del_Pay_list), 1);

for p = 1:length(del_Pay_list)
    fixed_del_Pay = del_Pay_list(p);
    
    iter_res_coop = zeros(iterations, 1);
    iter_res_ee   = zeros(iterations, 1);
    
    for itr = 1:iterations
        % Population initialization (Calling external distribution function)
        ee = round(generate_pop_distribution(current_pop_type, N));
        current_ee = ee(:);            
        current_nC = round(fixed_in_coop * N);
        
        % Buffers for averaging steady-state values
        h_coop_steady = zeros(300, 1);
        h_ee_steady   = zeros(300, 1);
        
        for g = 1:gn
            % STAGE 1: Decision Stage
            % Individuals cooperate if current cooperation exceeds their threshold (current_ee)
            q = 1 ./ (1 + exp(-beeta * (current_nC - current_ee))); 
            is_C = rand(N, 1) < q;
            actn = sum(is_C);
            
            % STAGE 2: Payoff Stage
            % Calculation of Public Goods benefit and Social Norm bonuses
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
            % Individuals update their threshold values based on success of others
            partner_idx = randi(N, N, 1);
            pay_diff = payoffs(partner_idx) - payoffs; 
            prob_imitate = 1 ./ (1 + exp(-eta * pay_diff));
            to_imitate = (pay_diff > 0) & (rand(N, 1) < prob_imitate);
            current_ee(to_imitate) = current_ee(partner_idx(to_imitate));
            
            % STAGE 4: Mutation Stage
            % Small random fluctuations in individual thresholds
            mut_mask = rand(N, 1) < mutation_rate;
            if any(mut_mask)
                current_ee(mut_mask) = current_ee(mut_mask) + randi([-5 5], sum(mut_mask), 1);
                current_ee = max(min(current_ee, N), 0);
            end
            current_nC = actn;
            
            % Record data for steady-state average (last 10% of generations)
            if g > (gn - 300)
                h_coop_steady(g-(gn-300)) = actn / N;
                h_ee_steady(g-(gn-300))   = mean(current_ee);
            end
        end 
        iter_res_coop(itr) = mean(h_coop_steady);
        iter_res_ee(itr)   = mean(h_ee_steady);
    end 
    
    % --- 3. STATISTICAL AGGREGATION ---
    asymp_coop(p) = mean(iter_res_coop);
    asymp_ee(p)   = mean(iter_res_ee);
    coop_CI(p) = 1.96 * (std(iter_res_coop) / sqrt(iterations));
    ee_CI(p)   = 1.96 * (std(iter_res_ee) / sqrt(iterations));
end

%% --- 4. PLOTTING ---
figure('Color', 'w', 'Position', [100 100 800 500]);
ax = gca; hold on; box on;

% LEFT AXIS: Cooperation (Markers: Circles)
yyaxis left
p1 = errorbar(del_Pay_list, asymp_coop, coop_CI, '-o', 'Color', c_coop, ...
    'LineWidth', 2, 'MarkerFaceColor', c_coop, 'MarkerSize', 6, 'CapSize', 0);
ylabel('asymptotic cooperation', 'Interpreter', 'latex', 'FontSize', 18);
ax.YAxis(1).Color = c_coop;
ylim([-0.05 1.05]); yticks(0:0.2:1);

% RIGHT AXIS: ee (Threshold) value (Markers: Squares)
yyaxis right
p2 = errorbar(del_Pay_list, asymp_ee, ee_CI, '-s', 'Color', c_ee, ...
    'LineWidth', 2, 'MarkerFaceColor', c_ee, 'MarkerSize', 6, 'CapSize', 0);
ylabel('asymptotic $ee$ value', 'Interpreter', 'latex', 'FontSize', 18);
ax.YAxis(2).Color = c_ee;
ylim([0 100]); yticks(0:20:100);

% Axis and Label Formatting
xlabel('$\pi^{social}$', 'Interpreter', 'latex', 'FontSize', 20); 
xticks(0:0.5:1.5);
set(ax, 'FontSize', 14, 'TickLabelInterpreter', 'latex');
legend([p1, p2], {'cooperation', '$ee$ value'}, 'Location', 'best', 'Interpreter', 'latex');