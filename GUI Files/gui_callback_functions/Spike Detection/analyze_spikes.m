function spike_analysis = analyze_spikes(waveforms, isi_threshold, min_spikes_per_burst, min_burst_duration,duration, cluster_filter)
    % Main function to analyze spikes for ISI, burst, and interburst intervals
    % Optionally filter by cluster labels
    % 
    % Parameters:
    % waveforms - Structure array with spike data
    % isi_threshold - ISI threshold for burst detection
    % min_spikes_per_burst - Minimum spikes required for a burst
    % min_burst_duration - Minimum duration (in seconds) for a burst
    % cluster_filter - Optional vector of cluster labels to analyze. If empty, analyze all clusters.
    
    if nargin < 6
        cluster_filter = []; % If not provided, analyze all clusters
    end
    
    % Find unique channels
    unique_channels = unique([waveforms.channel]);
    
    % Initialize structure to hold spike analysis
    spike_analysis = struct();
    count=1;
    % Loop through each channel
    for ch = 1:length(unique_channels)
        current_channel = unique_channels(ch);
        
        % Extract spikes for the current channel
        channel_spikes = waveforms([waveforms.channel] == current_channel);
        
        % Check if cluster_filter is provided and filter spikes accordingly
        if ~isempty(cluster_filter)
            % Filter by clusters if cluster_filter is provided
            cluster_filter = cluster_filter(:); % Ensure it's a column vector
            clusters = [channel_spikes.cluster];
            valid_indices = ismember(clusters, cluster_filter);
            channel_spikes = channel_spikes(valid_indices);
        end
        
        % Extract timestamps
        spike_times = [channel_spikes.time_stamp];
        
        % Check if there are spikes to analyze
        if isempty(spike_times) || length(spike_times)<5
            continue; % Skip if no spikes after filtering
        end
        
        % Sort timestamps
        spike_times = sort(spike_times);
        
        % Compute ISI
        ISI_values = compute_isi(spike_times);
        
        % Detect bursts
        bursts = detect_bursts_mod(spike_times, isi_threshold, min_spikes_per_burst, min_burst_duration);
        
        % Compute inter-burst intervals (IBI)
        IBI_values = compute_interburst_interval(bursts);
        Mean_Burst_freq = 1/mean(IBI_values);

        % Store results in structure
        spike_analysis(count).channel = current_channel;
        spike_analysis(count).spike_rate = length(spike_times)/duration;
        spike_analysis(count).timestamps = spike_times;
        spike_analysis(count).ISI = ISI_values;
        spike_analysis(count).bursts = bursts;
        spike_analysis(count).IBI = IBI_values;
        spike_analysis(count).Mean_Burst_Freq = Mean_Burst_freq;
        spike_analysis(count).ptp_amplitude = [channel_spikes.ptp_amplitude];
        spike_analysis(count).fwhm = [channel_spikes.fwhm];
        spike_analysis(count).mean_fwhm = mean([channel_spikes.fwhm]);
        spike_analysis(count).mean_ptp = mean([channel_spikes.ptp_amplitude]);
        spike_analysis(count).mean_ISI = mean(ISI_values);
        spike_analysis(count).mean_IBI = mean(IBI_values);
      
        if ~isempty(bursts)
           spike_analysis(count).numspikes_per_burst = [bursts.num_spikes];
           spike_analysis(count).num_bursts = length(bursts);
        else
            spike_analysis(count).num_bursts = 0;
        end
        if numel(spike_analysis(count).bursts)>0
            spike_analysis(count).meanburstduration = mean([spike_analysis(count).bursts.duration]);
        end
        count = count+1;
    end
end
