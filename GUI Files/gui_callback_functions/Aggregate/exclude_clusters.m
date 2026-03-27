function exclude_clusters(h)
    h = guidata(h.figure);

    % Check if clustering has been done
    if ~isfield(h.cumulative_spikes,'cluster_idx') || isempty(h.cumulative_spikes.cluster_idx)
        errordlg('No cluster data available. Run clustering first.');
        return;
    end

    cs = h.cumulative_spikes;
    score = h.cumulative_spikes.score;
    cluster_idx = cs.cluster_idx;
    nClusters   = numel(unique(cluster_idx));

    % Let user select clusters to exclude
    clusterToRemove = listdlg('PromptString','Select clusters to exclude:',...
                              'SelectionMode','multiple',...
                              'ListString', arrayfun(@(k) sprintf('Cluster %d',k),1:nClusters,'UniformOutput',false));

    if isempty(clusterToRemove)
        return; % User cancelled
    end

    % Spike-level mask
    mask_keep = ~ismember(cluster_idx, clusterToRemove);

    % - Update spike-level fields -
    spikeFields = {'all_waveforms','fwhm','ptp_amplitude','channels',...
                   'spike_origin_p','spike_origin_e','cluster_idx',...
                   'rec_time','spike_times'};
    for f = 1:numel(spikeFields)
        if isfield(cs, spikeFields{f})
            cs.(spikeFields{f}) = cs.(spikeFields{f})(mask_keep,:);
        end
    end

    % - Update channel-level fields -
    % Keep only channels still present after exclusion
    remaining_chans = unique(cs.channels);

    chanFields = {'impedance','capacitance','offset','exponent','spec_chans','spec_e','spec_p'};
    for f = 1:numel(chanFields)
        if isfield(cs, chanFields{f})
            chan_mask = ismember(cs.spec_chans, remaining_chans);
            if ~isempty(cs.(chanFields{f}))
            cs.(chanFields{f}) = cs.(chanFields{f})(chan_mask,:);
            end
        end
    end

    % Save back
    h.cumulative_spikes = cs;
    cluster_idx = cs.cluster_idx;

    cluster_labels = arrayfun(@(k) sprintf('Cluster %d', k), unique(cluster_idx),'UniformOutput',false);
    if isfield(h,'cluster_listbox') && ishandle(h.cluster_listbox)
        delete(h.cluster_listbox)
    end
    h.cluster_listbox = uicontrol('Parent', h.clustplot_panel, ...
                              'Style','listbox', ...
                              'String', cluster_labels, ...
                              'Max',10, ...
                              'Min',1,... % allow multi-select
                              'Units','normalized', ...
                              'Position',[0.85 0.2 0.15 0.2], ...
                              'BackgroundColor',[1 1 1]); 
    guidata(h.figure,h);
    plot_all_clusters(h);
end
