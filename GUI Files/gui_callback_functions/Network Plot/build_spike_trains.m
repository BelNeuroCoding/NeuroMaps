function [spikeMatrix, spike_times, unique_channels, time_vector] = ...
            build_spike_trains(networkconndata, tstamps)

    unique_channels = unique([networkconndata.channel]);
    num_channels = length(unique_channels);
    num_samples = length(tstamps);
    time_vector = double(tstamps);

    spikeMatrix = zeros(num_samples, num_channels);
    spike_times = cell(num_channels, 1);

    for i = 1:num_channels
        idx = [networkconndata.channel] == unique_channels(i);
        spikes = double([networkconndata(idx).time_stamp]) + min(time_vector);
        spike_indices = find(ismember(time_vector, spikes));
        spike_times{i} = time_vector(spike_indices);
        spikeMatrix(spike_indices, i) = 1;
    end
end
