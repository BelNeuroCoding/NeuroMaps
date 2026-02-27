function bursts = detect_bursts_mod(spike_times, isi_threshold, min_spikes_per_burst, min_burst_duration)
    % Detect bursts based on ISI threshold, minimum spikes per burst, and minimum burst duration
    % Initialize burst detection
    bursts = struct('start', {}, 'end', {});  % Preallocate as empty structure array
    num_spikes = length(spike_times);
    if num_spikes < min_spikes_per_burst
        return;  % Not enough spikes to form a burst
    end
    
    % Variables for tracking bursts
    spike_counts = 0;
    current_burst = [];
    burst_index = 0;
    
    % Loop through spike times to detect bursts
    for i = 1:num_spikes-1
        isi = spike_times(i+1) - spike_times(i);
        
        if isi < isi_threshold
            % Spike is part of a burst
            spike_counts = spike_counts + 1;
            if isempty(current_burst)
                current_burst = [spike_times(i), spike_times(i+1)];
            else
                current_burst(2) = spike_times(i+1);
            end
        else
            % End of a burst
            if spike_counts >= min_spikes_per_burst
                burst_index = burst_index + 1;
                bursts(burst_index).start = current_burst(1);
                bursts(burst_index).end = current_burst(2);
                bursts(burst_index).duration = current_burst(2)-current_burst(1);
                bursts(burst_index).num_spikes = spike_counts;
            end
            % Reset burst detection
            current_burst = [];
            spike_counts = 0;
        end
    end
    
    % Check the last burst
    if ~isempty(current_burst) && spike_counts >= min_spikes_per_burst
        burst_index = burst_index + 1;
        bursts(burst_index).start = current_burst(1);
        bursts(burst_index).end = current_burst(2);
        bursts(burst_index).duration = current_burst(2)-current_burst(1);
        bursts(burst_index).num_spikes = spike_counts;
    end
    
    % Filter bursts based on duration
    bursts = bursts(arrayfun(@(x) (x.end - x.start) >= min_burst_duration, bursts));
end
