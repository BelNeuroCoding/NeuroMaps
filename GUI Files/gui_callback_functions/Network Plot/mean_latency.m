function [mean_latency, std_latency] = mean_latency(spike_times_1, spike_times_2)
    % Compute the latency between spike times of two electrodes efficiently
    
    % Precompute all pairwise latency differences
    num_spikes_1 = length(spike_times_1);
    num_spikes_2 = length(spike_times_2);
    
    % Create a matrix of all pairwise latencies (num_spikes_1 x num_spikes_2)
    latency_matrix = bsxfun(@minus, spike_times_2', spike_times_1);  % Subtract each spike time in 1 from each in 2
    
    % Flatten the matrix to get all latency differences as a single vector
    latency_ij = latency_matrix(:);
    
    % Compute mean and standard deviation of latency
    mean_latency = mean(latency_ij);
    std_latency = std(latency_ij);
end
