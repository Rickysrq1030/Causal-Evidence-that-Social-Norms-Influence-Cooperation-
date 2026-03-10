%% Main Paper: Figure 2 - Evolutionary Trajectories and Convergence
% This script visualizes the time-series (generation-by-generation) 
% evolution of the system. It highlights the individual stochastic 
% trajectories of multiple iterations and their collective mean, 
% demonstrating how the population reaches a cooperative equilibrium 
% under specific social payoffs.

clear all; clc; close all;

%% --- 1. PARAMETERS & CONFIGURATION ---
del_Pay_list = [1.0];   % Social payoff intensity
current_pop_type = 3;   % Normal distribution baseline
gn = 10;                % Generations per iteration (set to 10 as per user logic)
iterations = 100;       % Number of independent simulation runs
in_coop_fr = 0.52;      % Initial cooperation fraction
beeta = 2;              % Selection intensity (Decision Stage)
N = 100;                % Population size
E = 10; h = 2; donation_cost = 1; % Game payoffs
switch_norm = 1;        % Activate social norm
mutation_rate = 0.01;   % Threshold mutation rate
eta = 2;                % Selection pressure (Evolutionary Stage)

% Visual Identity
c_coop = [215, 25, 28]/255;   % High-contrast Red for Cooperation
c_ee   = [44, 123, 182]/255;  % High-contrast Blue for ee values
c_traj = [150, 150, 150]/255; % Muted Grey for individual trajectories

% Initialize Figure
fig_main = figure('Color', 'w', 'Units', 'pixels', 'Position', [100 100 1500 600]);

%% --- 2. SIMULATION ENGINE ---
for a = 1:length(del_Pay_list)
    current_pi_social = del_Pay_list(a);
    
    % Data storage for trajectories
    ee_list = [];
    cooperation_levels = zeros(gn + 1, iterations);
    avg_strategy_rec = zeros(gn + 1, iterations); 
    
    for itr = 1:iterations
        % Initialize population thresholds
        current_ee = round(generate_pop_distribution(current_pop_type, N));
        current_ee = current_ee(:); 
        
        current_nC = round(in_coop_fr * N);
        
        % Record initial state
        cooperation_levels(1, itr) = current_nC;
        avg_strategy_rec(1, itr) = mean(current_ee);
        ee_list(itr,:) = current_ee;
        
        for g = 1:gn
            % STAGE 1: Decision Stage
            % Probability of cooperating based on current threshold (ee)
            q = 1 ./ (1 + exp(-beeta * (current_nC - current_ee))); 
            is_cooperator = rand(N, 1) < q;
            actn = sum(is_cooperator);
            
            % STAGE 2: Payoff Stage
            % Combining PGG benefits with Social Norm bonuses
            payoffs = zeros(N, 1) + (h * actn * donation_cost) / N;
            payoffs(is_cooperator) = payoffs(is_cooperator) + E - donation_cost;
            payoffs(~is_cooperator) = payoffs(~is_cooperator) + E;
            
            if switch_norm > 0
                if actn > N/2
                    payoffs(is_cooperator) = payoffs(is_cooperator) + current_pi_social;
                elseif actn < N/2
                    payoffs(~is_cooperator) = payoffs(~is_cooperator) + current_pi_social;
                end
            end
            
            % STAGE 3: Evolutionary Stage (Imitation)
            % Social learning via pairwise payoff comparison
            partner_indices = randi(N, N, 1);
            payoff_diff = payoffs(partner_indices) - payoffs;
            prob_imitate = 1 ./ (1 + exp(-eta * payoff_diff));
            to_imitate = (payoff_diff > 0) & (rand(N, 1) < prob_imitate);
            current_ee(to_imitate) = current_ee(partner_indices(to_imitate));
            
            % STAGE 4: Mutation Stage
            mutate_mask = rand(N, 1) < mutation_rate;
            if any(mutate_mask)
                current_ee(mutate_mask) = max(min(current_ee(mutate_mask) + randi([-5, 5], sum(mutate_mask), 1), N), 0);
            end
            
            % Update population state for next generation
            current_nC = actn;
            cooperation_levels(g+1, itr) = actn;
            avg_strategy_rec(g+1, itr) = mean(current_ee);
        end 
    end 
    
    %% --- 3. PLOTTING TRAJECTORIES ---
    x_vals = 0:gn;
    
    % Panel: Cooperation Rate over Generations
    subplot(2, 3, a); hold on; box on;
    
    % Plot individual grey trajectories (iterations)
    plot(x_vals, cooperation_levels/N, 'Color', [c_traj 0.3], 'HandleVisibility', 'off');
    
    % Plot the bold mean trajectory
    plot(x_vals, mean(cooperation_levels, 2)/N, 'Color', c_coop, 'LineWidth', 3);
    
    % Formatting
    title(['$\pi^{social} = ', num2str(current_pi_social), '$'], 'Interpreter', 'latex', 'FontSize', 18);
    if a == 1; ylabel('cooperation rate $\rho$', 'Interpreter', 'latex', 'FontSize', 18); end
    ylim([-0.03 1.03]); 
    set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 18);
    xlabel('generation', 'Interpreter', 'latex', 'FontSize', 18);
end