function analysedset = spike_feats_callback(h)

h = guidata(h.figure);

isi_threshold         = str2double(get(h.burst_param(1),'String'));
min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
min_burst_duration   = str2double(get(h.burst_param(3),'String'));
min_synch_spikes     = str2double(get(h.burst_param(4),'String'));

active_rate_threshold = 5/60;   % 5 spikes/min = 0.0833 Hz

% Default output
analysedset = struct();

% Get selected ports
idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

for i = 1:size(selected,1)

    expIdx = selected(i,1);
    selected_idx = selected(i,2);

    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    timestamps = results.timestamps;

    if isempty(timestamps) || max(timestamps) <= min(timestamps)
        warning('Skipping experiment %d port %d because timestamps are invalid.', expIdx, selected_idx);
        analysedset = make_empty_analysedset();
        results.spike_results(selected_idx).set = analysedset;
        save_results_back(h, results, expIdx);
        continue;
    end

    duration_sec = max(timestamps) - min(timestamps);

    waveforms_all = results.spike_results(selected_idx).waveforms_all;

    if isempty(waveforms_all)
        analysedset = make_empty_analysedset();
        results.spike_results(selected_idx).set = analysedset;
        save_results_back(h, results, expIdx);
        continue;
    end

    % Optional spike filtering by amplitude/FWHM
    ptp  = [waveforms_all.ptp_amplitude]';
    fwhm = [waveforms_all.fwhm]';

    if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)

        r = h.spike_filter_ranges;

        idx_keep = ...
            ptp  >= r.amp(1)  & ptp  <= r.amp(2) & ...
            fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);

        waveforms_all = waveforms_all(idx_keep);
    end

    % If filtering removed everything, save an empty summary safely
    if isempty(waveforms_all)
        analysedset = make_empty_analysedset();
        results.spike_results(selected_idx).set = analysedset;
        save_results_back(h, results, expIdx);
        continue;
    end

    % Ensure cluster field exists
    if ~isfield(waveforms_all,'clusters')
        [waveforms_all.clusters] = deal(1);
    end

    % Get clusters/channels
    clusters = [waveforms_all.clusters];
    unique_clusters = unique(clusters);

    chans = [waveforms_all.channel];
    unique_chans = unique(chans);

    % Spike rate per channel
    spike_rate_per_channel = zeros(1, numel(unique_chans));
    spike_count_per_channel = zeros(1, numel(unique_chans));

    for k = 1:numel(unique_chans)
        chan_indices = chans == unique_chans(k);
        spike_count_per_channel(k) = sum(chan_indices);
        spike_rate_per_channel(k) = spike_count_per_channel(k) / duration_sec;
    end

    active_mask = spike_rate_per_channel > active_rate_threshold;

    % Synchrony
    if numel(unique_chans) >= min_synch_spikes && max(spike_count_per_channel) > 0

        spikes = NaN(max(spike_count_per_channel), numel(unique_chans));

        for chan = 1:numel(unique_chans)

            current_channel = unique_chans(chan);

            spike_times = [waveforms_all([waveforms_all.channel] == current_channel).time_stamp];

            spikes(1:numel(spike_times), chan) = spike_times;
        end

        [Synch, ~] = SpikeContrast(spikes, duration_sec);

    else
        Synch = NaN;
    end

    % 
    % Per-cluster stats
    % 
    fwhm_per_cluster = zeros(numel(unique_clusters), 2);
    ptp_amplitude_per_cluster = zeros(numel(unique_clusters), 2);
    spike_rate_per_cluster = zeros(1, numel(unique_clusters));

    fwhm_all = [];
    ptp_amplitude_all = [];

    for j = 1:numel(unique_clusters)

        cluster_indices = clusters == unique_clusters(j);

        cluster_fwhm = [waveforms_all(cluster_indices).fwhm];
        cluster_ptp_amplitude = [waveforms_all(cluster_indices).ptp_amplitude];
        active_cluster_chans = unique([waveforms_all(cluster_indices).channel]);

        fwhm_per_cluster(j,:) = [nanmean(cluster_fwhm), nanstd(cluster_fwhm)];
        ptp_amplitude_per_cluster(j,:) = [nanmean(cluster_ptp_amplitude), nanstd(cluster_ptp_amplitude)];

        num_spikes_in_cluster = sum(cluster_indices);

        spike_rate_per_cluster(j) = num_spikes_in_cluster / ...
            (duration_sec * numel(active_cluster_chans));

        fwhm_all = [fwhm_all, cluster_fwhm]; %#ok<AGROW>
        ptp_amplitude_all = [ptp_amplitude_all, cluster_ptp_amplitude]; %#ok<AGROW>
    end

    % 
    % Burst analysis
    % 
    spike_analysis = analyze_spikes( ...
        waveforms_all, ...
        isi_threshold, ...
        min_spikes_per_burst, ...
        min_burst_duration, ...
        duration_sec);

    % 
    % Build analysedset
    % 
    analysedset = struct();

    analysedset.num_activechans = sum(active_mask);
    analysedset.synchronicity = Synch;

    analysedset.mean_bursts_rate = nanmean([spike_analysis.Mean_Burst_Freq]);
    analysedset.std_bursts_rate  = nanstd([spike_analysis.Mean_Burst_Freq]);

    if any(active_mask)
        analysedset.mean_spike_rate = nanmean(spike_rate_per_channel(active_mask));
        analysedset.std_spike_rate  = nanstd(spike_rate_per_channel(active_mask));
    else
        analysedset.mean_spike_rate = NaN;
        analysedset.std_spike_rate  = NaN;
    end

    analysedset.spike_rate_per_channel = spike_rate_per_channel;
    analysedset.channels = unique_chans;
    analysedset.spike_analysis = spike_analysis;

    analysedset.fwhm_per_cluster = fwhm_per_cluster;
    analysedset.ptp_amplitude_per_cluster = ptp_amplitude_per_cluster;
    analysedset.spike_rate_cluster = spike_rate_per_cluster;

    analysedset.mean_fwhm = nanmean(fwhm_all);
    analysedset.std_fwhm  = nanstd(fwhm_all);

    analysedset.mean_ptp_amplitude = nanmean(ptp_amplitude_all);
    analysedset.std_ptp_amplitude  = nanstd(ptp_amplitude_all);

    % Save back into results
    results.spike_results(selected_idx).set = analysedset;

    save_results_back(h, results, expIdx);

    h = guidata(h.figure);
end

end


function analysedset = make_empty_analysedset()

analysedset = struct();

analysedset.num_activechans = 0;
analysedset.synchronicity = NaN;

analysedset.mean_bursts_rate = NaN;
analysedset.std_bursts_rate = NaN;

analysedset.mean_spike_rate = NaN;
analysedset.std_spike_rate = NaN;

analysedset.spike_rate_per_channel = [];
analysedset.channels = [];
analysedset.spike_analysis = [];

analysedset.fwhm_per_cluster = [];
analysedset.ptp_amplitude_per_cluster = [];
analysedset.spike_rate_cluster = [];

analysedset.mean_fwhm = NaN;
analysedset.std_fwhm = NaN;

analysedset.mean_ptp_amplitude = NaN;
analysedset.std_ptp_amplitude = NaN;

end


function save_results_back(h, results, expIdx)

if iscell(h.figure.UserData)
    allresults = h.figure.UserData;
    allresults{expIdx} = results;
    set(h.figure, 'UserData', allresults);
else
    set(h.figure, 'UserData', results);
end

guidata(h.figure, h);

end