
clear all; clc; close all;

%% ================================================================
%  Long-run equilibrium-selection analysis under persistent mutation
%
%  Purpose:
%  This script runs the full stochastic evolutionary model for a long
%  horizon and measures how often the system occupies the cooperative
%  basin after burn-in.
%
%  The cooperative basin is defined as rho > 0.8, where rho is the
%  fraction of cooperators in the population.
%
%  This analysis addresses the long-run behavior of the perturbed
%  evolutionary process, rather than only finite-time convergence.
%% ================================================================

%% --- Core simulation parameters ---

gn = 100000;                 % Number of generations per simulation run
iterations = 100;            % Number of independent stochastic realizations
burn_in = 20000;             % Initial generations discarded before measurement

pop_type_list  = 3;          % Initial ee distribution type: 3 = normal distribution

mutation_rate_list = [0.01 0.005 0.001];      % Mutation rates to compare
fixed_del_Pay_list = [1.0 1.05 1.1 1.2 1.5];  % Social reward values pi_social

% Label for the initial ee distribution used in this script
labels = {'$\mathcal{N}(\mu, \sigma^2)$'};

% Colors retained from previous plotting scripts
c_coop = [49, 130, 189]/255;  
c_ee   = [228, 26, 28]/255;   

%% --- Storage objects ---

% coop_basin(m,p) stores the fraction of post-burn-in time spent
% in the cooperative basin for mutation rate m and social reward p.
coop_basin = zeros(length(mutation_rate_list), length(fixed_del_Pay_list));

% results stores one row per parameter condition:
% [mutation_rate, pi_social, mean_cooperation, time_high_coop, time_low_coop]
results = [];
row = 1;

%% ================================================================
%  Outer loop over mutation rates
%
%  For each mutation rate, the same set of social reward values is tested.
%  Lower mutation rates correspond to rarer perturbations.
%% ================================================================

for m = 1:length(mutation_rate_list)

    mutation_rate = mutation_rate_list(m);
    
    %% ------------------------------------------------------------
    %  Middle loop over social reward values pi_social
    %
    %  pi_social is the reward for matching the current majority action.
    %  The main theoretical threshold is pi_social = c, where c = 1.
    %% ------------------------------------------------------------

    for p = 1:length(fixed_del_Pay_list)

        del_Pay = fixed_del_Pay_list(p);
        
        % Storage for population-type-level statistics.
        % Here pop_type_list contains only one type, but these arrays keep
        % the code compatible with multiple initial distributions.
        asymp_coop_mean = zeros(length(pop_type_list), 1);
        asymp_ee_mean   = zeros(length(pop_type_list), 1);
        coop_CI = zeros(length(pop_type_list), 1);
        ee_CI   = zeros(length(pop_type_list), 1);
        
        % For each independent realization, record the fraction of
        % post-burn-in time spent in high-cooperation and low-cooperation states.
        time_high_coop = zeros(iterations, 1);   % fraction of time with rho > 0.8
        time_low_coop  = zeros(iterations, 1);   % fraction of time with rho < 0.2
        
        %% --------------------------------------------------------
        %  Loop over initial ee distribution types
        %
        %  In this script, current_pop_type = 3, corresponding to the
        %  normal initial distribution used in the main paper.
        %% --------------------------------------------------------

        for a = 1:length(pop_type_list)

            current_pop_type = pop_type_list(a);

            %% --- Model parameters ---

            in_coop_fr = 0.52;       % Initial cooperation fraction
            beeta = 2;               % Decision sensitivity to social signal
            N = 100;                 % Population size
            E = 10;                  % Endowment
            h = 2;                   % Public-goods enhancement factor
            donation_cost = 1;       % Cost of cooperation, c
            switch_norm = 1;         % If 1, majority-based social reward is active
            eta = 2;                 % Selection intensity in imitation rule
            
            % One value per independent realization
            iter_results_coop = zeros(iterations, 1);
            iter_results_ee   = zeros(iterations, 1);
            
            %% ----------------------------------------------------
            %  Independent stochastic realizations
            %
            %  Each realization uses the same parameter values but a new
            %  random initial ee distribution, random decisions, random
            %  imitation partners, and random mutations.
            %% ----------------------------------------------------

            for itr = 1:iterations

                %% --- Initial state ---

                % Draw initial empirical-expectation thresholds ee_i.
                % The helper function must be available on the MATLAB path.
                ee = round(generate_pop_distribution(current_pop_type, N));

                % Store ee as a column vector for vectorized operations.
                current_ee = ee(:);

                % Initial number of cooperators before the first update.
                current_nC = round(in_coop_fr * N);
                
                % Store the full time series for this realization.
                history_coop = zeros(gn, 1);    % rho_t = cooperation fraction
                history_ee   = zeros(gn, 1);    % average ee threshold
                
                %% ------------------------------------------------
                %  Generational dynamics
                %% ------------------------------------------------

                for g = 1:gn

                    %% 1. Decision stage

                    % Each agent cooperates with probability increasing in
                    % current_nC - current_ee.
                    %
                    % If current_nC exceeds an agent's threshold, cooperation
                    % is likely. If current_nC is below the threshold,
                    % free riding is likely.
                    q = 1 ./ (1 + exp(-beeta * (current_nC - current_ee)));

                    % Realized cooperation decisions
                    is_C = rand(N, 1) < q;

                    % Number of cooperators in this generation
                    actn = sum(is_C);
                    
                    %% 2. Payoff stage

                    % Public-goods benefit received equally by all agents
                    benefit = (h * actn * donation_cost) / N;

                    % Material payoff from the public goods game
                    payoffs = zeros(N, 1);
                    payoffs(is_C)  = E - donation_cost + benefit;
                    payoffs(~is_C) = E + benefit;
                    
                    % Majority-based social reward:
                    % If cooperators are the majority, cooperators receive pi_social.
                    % If free riders are the majority, free riders receive pi_social.
                    % If exactly tied, no side receives the social reward.
                    if switch_norm > 0
                        if actn > N/2
                            payoffs(is_C) = payoffs(is_C) + del_Pay;
                        elseif actn < N/2
                            payoffs(~is_C) = payoffs(~is_C) + del_Pay;
                        end
                    end
                    
                    %% 3. Evolutionary imitation stage

                    % Each agent samples a random comparison partner.
                    partner_idx = randi(N, N, 1);

                    % Positive payoff_diff means the sampled partner earned more.
                    pay_diff = payoffs(partner_idx) - payoffs;

                    % Probability of imitation increases with payoff advantage.
                    prob_imitate = 1 ./ (1 + exp(-eta * pay_diff));

                    % Imitation occurs only when the partner performed better
                    % and the stochastic imitation draw succeeds.
                    to_imitate = (pay_diff > 0) & (rand(N, 1) < prob_imitate);

                    % Agents who imitate copy the partner's ee threshold.
                    current_ee(to_imitate) = current_ee(partner_idx(to_imitate));
                    
                    %% 4. Mutation stage

                    % With probability mutation_rate, an agent's ee threshold
                    % is randomly perturbed by an integer in [-5, 5].
                    mut_mask = rand(N, 1) < mutation_rate;

                    if any(mut_mask)
                        current_ee(mut_mask) = current_ee(mut_mask) + ...
                            randi([-5 5], sum(mut_mask), 1);

                        % Keep thresholds within the feasible range [0, N].
                        current_ee = max(min(current_ee, N), 0);
                    end
                    
                    %% 5. Record state variables

                    % Current cooperation level becomes the social signal
                    % for the next generation.
                    current_nC = actn;

                    % Store cooperation fraction and mean ee threshold.
                    history_coop(g) = actn / N;
                    history_ee(g)   = mean(current_ee);
                end
                
                %% --- Post-burn-in statistics for this realization ---

                post_burn = burn_in:gn;

                % Mean cooperation and mean ee after burn-in
                iter_results_coop(itr) = mean(history_coop(post_burn));
                iter_results_ee(itr)   = mean(history_ee(post_burn));

                % Basin occupancy measures:
                % high cooperation basin: rho > 0.8
                % low cooperation basin:  rho < 0.2
                time_high_coop(itr) = mean(history_coop(post_burn) > 0.8);
                time_low_coop(itr)  = mean(history_coop(post_burn) < 0.2);
            end
            
            %% --- Aggregate statistics across independent realizations ---

            mean_time_high_coop = mean(time_high_coop);
            mean_time_low_coop  = mean(time_low_coop);
            
            fprintf('Mutation = %.3f, pi_social = %.2f, pop_type = %d\n', ...
                mutation_rate, del_Pay, current_pop_type);
            fprintf('Mean post-burn cooperation = %.3f\n', mean(iter_results_coop));
            fprintf('Mean time rho > 0.8 = %.3f\n', mean_time_high_coop);
            fprintf('Mean time rho < 0.2 = %.3f\n\n', mean_time_low_coop);
         
            % Mean post-burn outcomes
            asymp_coop_mean(a) = mean(iter_results_coop);
            asymp_ee_mean(a)   = mean(iter_results_ee);

            % 95% confidence intervals across independent realizations
            coop_CI(a) = 1.96 * (std(iter_results_coop) / sqrt(iterations));
            ee_CI(a)   = 1.96 * (std(iter_results_ee) / sqrt(iterations));
        end
        
        %% --- Store one row for this parameter condition ---

        results(row,:) = [ ...
            mutation_rate, ...
            del_Pay, ...
            mean(iter_results_coop), ...
            mean_time_high_coop, ...
            mean_time_low_coop];

        row = row + 1;
        
        % Store cooperative-basin occupancy for the summary plot.
        coop_basin(m,p) = mean_time_high_coop;
    end
end

%% ================================================================
%  Display summary table
%% ================================================================

ResultsTable = array2table(results, ...
    'VariableNames', ...
    {'MutationRate', ...
     'PiSocial', ...
     'MeanCooperation', ...
     'TimeHighCoop', ...
     'TimeLowCoop'});

disp(ResultsTable)

%% ================================================================
%  Plot cooperative-basin occupancy
%
%  x-axis: social reward pi_social
%  y-axis: fraction of post-burn-in time with rho > 0.8
%  one curve per mutation rate
%% ================================================================

figure('Color', 'w'); 
hold on; box on;

for m = 1:length(mutation_rate_list)
    plot(fixed_del_Pay_list, ...
         coop_basin(m,:), ...
         '-o', ...
         'LineWidth', 2, ...
         'MarkerSize', 8);
end

xlabel('$\pi^{social}$', 'Interpreter', 'latex');
ylabel('cooperative basin occupancy', 'Interpreter', 'latex');

legend({'$\mu=0.01$', ...
        '$\mu=0.005$', ...
        '$\mu=0.001$'}, ...
        'Interpreter', 'latex', ...
        'Location', 'best');

ylim([0 1]);

% Mark the theoretical cost threshold c = 1.
% The figure tests whether long-run cooperation becomes dominant
% below, at, or above this threshold.
xline(1, '--k', '$\pi^{\text{social}}=c$', ...
    'Interpreter', 'latex', ...
    'LabelVerticalAlignment', 'bottom', ...
    'LineWidth', 2, ...
    'FontSize', 14);




