function [sttc_matrix, latency_matrix] = compute_sttc_and_latency(spikeMatrix, spike_times, unique_channels, time_vector, dtv)
    num_channels = length(unique_channels);
    combins = nchoosek(1:num_channels, 2);
    sttc_matrix = zeros(num_channels);
    latency_matrix = zeros(num_channels);

    for i = 1:length(combins)
        i1 = combins(i,1); i2 = combins(i,2);
        electrode_1 = spikeMatrix(:, i2); 
        electrode_2 = spikeMatrix(:, i1);
        N1v = sum(electrode_1);
        N2v = sum(electrode_2);

        spikes1 = double(spike_times{i2});
        spikes2 = double(spike_times{i1});

        [latency_ij, ~] = mean_latency(spikes1, spikes2);
        latency_matrix(i1,i2) = latency_ij;

        Time = double([min(time_vector), max(time_vector)]);
        sttc_matrix(i1,i2) = sttc(N1v, N2v, double(dtv/1000), Time, spikes1, spikes2);
    end
end
