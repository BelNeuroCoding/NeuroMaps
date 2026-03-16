function analysedset = spike_feats_callback(h)
h = guidata(h.figure);
isi_threshold = str2double(get(h.burst_param(1),'String'));
min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
min_burst_duration = str2double(get(h.burst_param(3),'String'));
min_synch_spikes = str2double(get(h.burst_param(4),'String'));
% Get selected ports
idx = h.portList.Value;        % listbox indices
map = h.portList.UserData;     % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);
%  Handle multiple selections 

for i = 1:size(selected,1)
    expIdx = selected(i,1);
    selected_idx = selected(i,2);
    %  Load results 
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end    
    timestamps = results.timestamps;
    duration_sec = max(timestamps)-min(timestamps);
    waveforms_all = results.spike_results(selected_idx).waveforms_all;
    ptp  = [waveforms_all.ptp_amplitude]';
    fwhm = [waveforms_all.fwhm]';
    if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)

            r = h.spike_filter_ranges;
        
            idx_keep = ...
                ptp  >= r.amp(1)  & ptp  <= r.amp(2) & ...
                fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
        
            waveforms_all = waveforms_all(idx_keep);
    end
    
    
    analysedset = {};
    if ~isfield(waveforms_all,'clusters')
        [waveforms_all.clusters] = deal(1);
    end
    % Get clusters
    clusters = [waveforms_all.clusters];  % Assuming each spike has a 'cluster' field
    unique_clusters = unique(clusters);  % Get unique clusters
    
    chans = [waveforms_all.channel];
    unique_chans = unique(chans);
    
    max_spikes = 0;
    for k = 1:length(unique_chans)
        chan_indices = (chans == unique_chans(k));
        spike_rate_per_channel(k) = sum(chan_indices) /duration_sec;
            
    end
    if length(unique_chans)>min_synch_spikes
        % Step 2: Create spike matrix with NaN padding
        spikes = NaN(max(round(spike_rate_per_channel*duration_sec)), length(unique_chans));
        
        for chan = 1:length(unique_chans)
            current_channel = unique_chans(chan);
            spike_times = [waveforms_all([waveforms_all.channel] == current_channel).time_stamp]; % Extract spike timestamps
            
            % Fill the column with spike times and NaN-pad if necessary
            spikes(1:length(spike_times), chan) = spike_times;
        end
        [Synch,PREF] = SpikeContrast(spikes,duration_sec);
    else
        Synch = NaN;
    end
    % Initialize arrays to store per-cluster FWHM and ptp_amplitude
    fwhm_per_cluster = zeros(length(unique_clusters), 2);
    ptp_amplitude_per_cluster = zeros(length(unique_clusters), 2);
    
    % Initialize arrays for mean and std of FWHM and ptp_amplitude
    fwhm_all = [];
    ptp_amplitude_all = [];
    
    % Loop through each cluster and calculate FWHM and ptp_amplitude
    for j = 1:length(unique_clusters)
        % Find indices for current cluster
        cluster_indices = (clusters == unique_clusters(j));
        
        % Extract FWHM and ptp_amplitude for the current cluster
        cluster_fwhm = [waveforms_all(cluster_indices).fwhm];
        cluster_ptp_amplitude = [waveforms_all(cluster_indices).ptp_amplitude];
        active_cluster_chans = unique([waveforms_all(cluster_indices).channel]);
        % Store mean and std for FWHM and ptp_amplitude for the current cluster
        fwhm_per_cluster(j,:) = [nanmean(cluster_fwhm) nanstd(cluster_fwhm)];  % Mean FWHM for this cluster
        ptp_amplitude_per_cluster(j,:) = [nanmean(cluster_ptp_amplitude) nanstd(cluster_ptp_amplitude)];  % Mean ptp_amplitude for this cluster
    
        % Count spikes in the current cluster
        num_spikes_in_cluster = sum(cluster_indices); % Number of Spikes in Cluster
        
        % Calculate spike rate for the current cluster
        spike_rate_per_cluster(j) = num_spikes_in_cluster /(duration_sec*length(active_cluster_chans));
    
        % Optionally, store all values for later use (e.g., for plotting distributions)
        fwhm_all = [fwhm_all, cluster_fwhm];
        ptp_amplitude_all = [ptp_amplitude_all, cluster_ptp_amplitude];
    end
    spike_analysis = analyze_spikes(waveforms_all, isi_threshold, min_spikes_per_burst, min_burst_duration,duration_sec);
    analysedset.num_activechans = length(unique([waveforms_all.channel]));
    analysedset.synchronicity = Synch;
    analysedset.mean_bursts_rate = nanmean([spike_analysis.Mean_Burst_Freq]); % Mean Number of Bursts per Channels
    analysedset.std_bursts_rate = nanstd([spike_analysis.Mean_Burst_Freq]); % Mean Number of Bursts per Channels
    analysedset.mean_spike_rate = nanmean(spike_rate_per_channel(spike_rate_per_channel>0.0833)); % More than 5 spikes per min
    analysedset.std_spike_rate = nanstd(spike_rate_per_channel(spike_rate_per_channel>0.0833)); % More than 5 spikes per min
    analysedset.spike_rate_per_channel = spike_rate_per_channel;
    analysedset.channels = unique_chans;
    analysedset.spike_analysis = spike_analysis;
    % Store the per-cluster FWHM and ptp_amplitude in the analysedset structure
    analysedset.fwhm_per_cluster = fwhm_per_cluster;
    analysedset.ptp_amplitude_per_cluster = ptp_amplitude_per_cluster;
    analysedset.spike_rate_cluster = spike_rate_per_cluster;
    % Calculate mean and std across all clusters (optional summary)
    analysedset.mean_fwhm = nanmean(fwhm_all);
    analysedset.std_fwhm = nanstd(fwhm_all);
    analysedset.mean_ptp_amplitude = nanmean(ptp_amplitude_all);
    analysedset.std_ptp_amplitude = nanstd(ptp_amplitude_all);
    
    results.spike_results(selected_idx).set = analysedset;
    if iscell(h.figure.UserData)
        allresults = h.figure.UserData;
        allresults{expIdx} = results;
        set(h.figure, 'UserData', allresults);
    else
        set(h.figure, 'UserData', results);
    end
    guidata(h.figure,h);    
end

end
