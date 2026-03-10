function samples = generate_pop_distribution(dist_type, N)
    mu = N / 2;
    sigma = N / 6;
    pop_size = N;      
    switch dist_type
        case 1 % Left skew
            m = log(mu^2 / sqrt(sigma^2 + mu^2));
            s = sqrt(log(1 + sigma^2 / mu^2));
            right_skew = lognrnd(m, s, 1, pop_size);
            samples = N - right_skew;
        case 2 % Uniform
            samples = rand(1, pop_size) * N;
        case 3 % Normal
            samples = normrnd(mu, sigma, 1, pop_size);
        case 4 % Right skew
            m = log(mu^2 / sqrt(sigma^2 + mu^2));
            s = sqrt(log(1 + sigma^2 / mu^2));
            samples = lognrnd(m, s, 1, pop_size);
    end
    samples = max(0, min(N, samples));
end