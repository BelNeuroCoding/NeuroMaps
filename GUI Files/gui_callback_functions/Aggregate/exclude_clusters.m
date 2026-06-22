function exclude_clusters(h)
    h = guidata(h.figure);

    if ~isfield(h.cumulative_spikes,'cluster_idx') || isempty(h.cumulative_spikes.cluster_idx)
        errordlg('No cluster data available. Run clustering first.');
        return;
    end

    cs = h.cumulative_spikes;
    cluster_idx = cs.cluster_idx(:);

    cluster_ids = unique(cluster_idx);
    cluster_labels = arrayfun(@(k) sprintf('Cluster %d', k), cluster_ids, ...
                              'UniformOutput', false);

    selectedIdx = listdlg('PromptString','Select clusters to exclude:', ...
                          'SelectionMode','multiple', ...
                          'ListString', cluster_labels);

    if isempty(selectedIdx)
        return;
    end

    clustersToRemove = cluster_ids(selectedIdx);
    mask_keep = ~ismember(cluster_idx, clustersToRemove);

    spikeFields = {'all_waveforms','fwhm','ptp_amplitude','channels', ...
                   'spike_origin_p','spike_origin_e','cluster_idx', ...
                   'rec_time','spike_times'};

    for f = 1:numel(spikeFields)
        field = spikeFields{f};

        if isfield(cs, field) && ~isempty(cs.(field))
            if size(cs.(field),1) == numel(mask_keep)
                cs.(field) = cs.(field)(mask_keep,:);
            else
                warning('Skipping %s: first dimension does not match number of spikes.', field);
            end
        end
    end

    if isfield(cs, 'channels') && isfield(cs, 'spec_chans') && ~isempty(cs.spec_chans)
        remaining_chans = unique(cs.channels);
        chan_mask = ismember(cs.spec_chans, remaining_chans);

        chanFields = {'impedance','capacitance','offset','exponent','spec_chans','spec_e','spec_p'};

        for f = 1:numel(chanFields)
            field = chanFields{f};

            if isfield(cs, field) && ~isempty(cs.(field))
                if size(cs.(field),1) == numel(chan_mask)
                    cs.(field) = cs.(field)(chan_mask,:);
                else
                    warning('Skipping %s: row count does not match spec_chans.', field);
                end
            end
        end
    end

    h.cumulative_spikes = cs;

    cluster_ids = unique(cs.cluster_idx);
    cluster_labels = arrayfun(@(k) sprintf('Cluster %d', k), cluster_ids, ...
                              'UniformOutput', false);

    if isfield(h,'cluster_listbox') && ishandle(h.cluster_listbox)
        delete(h.cluster_listbox)
    end

    h.cluster_listbox = uicontrol('Parent', h.clustplot_panel, ...
                                  'Style','listbox', ...
                                  'String', cluster_labels, ...
                                  'Max',10, ...
                                  'Min',1, ...
                                  'Units','normalized', ...
                                  'Position',[0.85 0.2 0.15 0.2], ...
                                  'BackgroundColor',[1 1 1]);

    guidata(h.figure,h);
    plot_all_clusters(h);
end
