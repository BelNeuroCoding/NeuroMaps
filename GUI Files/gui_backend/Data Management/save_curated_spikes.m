function save_curated_spikes(h)
    %SAVE_CURATED_SPIKES Pushes curated spike data from h.cumulative_spikes
    % back into res.spike_results(portIdx).waveforms_all for each experiment/port

    h = guidata(h.figure);
    cs = h.cumulative_spikes;
    results = h.figure.UserData;
    if ~isfield(cs,'all_waveforms') || isempty(cs.all_waveforms)
        errordlg('No curated spikes available to save.');
        return;
    end

    % Work through each experiment/port combination
    map = h.portList.UserData;   % Nx2 [expIdx, portIdx]
    allExp = unique(cs.spike_origin_e);

    for expIdx = allExp'
        results = h.figure.UserData{expIdx};

        portsInExp = unique(cs.spike_origin_p(cs.spike_origin_e == expIdx));
        for portIdx = portsInExp'

            % Mask for spikes belonging to this exp/port
            mask = (cs.spike_origin_e == expIdx) & (cs.spike_origin_p == portIdx);

            if ~any(mask)
                continue;
            end
            % Rebuild waveforms_all entries
            mask = (cs.spike_origin_e == expIdx) & (cs.spike_origin_p == portIdx);
            N = sum(mask);                   % number of spikes in this exp/port
            wf_mat = cs.all_waveforms(mask,:); % N x waveformLength
            
            % Convert each row of wf_mat to a cell
            wf_cells = mat2cell(wf_mat, ones(N,1), size(wf_mat,2));  % N x 1 cell
            
            ch_cells      = num2cell(cs.channels(mask));
            ts_cells      = num2cell(cs.spike_times(mask));
            ptp_cells     = num2cell(cs.ptp_amplitude(mask));
            fwhm_cells    = num2cell(cs.fwhm(mask));
            cluster_cells = num2cell(cs.cluster_idx(mask));
            
            % Preallocate struct array
            waveforms_all(N) = struct('channel',[],'spike_shape',[],'time_stamp',[],...
                                      'ptp_amplitude',[],'fwhm',[],'clusters',[]);
            
            % Assign fields
            [waveforms_all.spike_shape]   = wf_cells{:};
            [waveforms_all.channel]       = ch_cells{:};
            [waveforms_all.time_stamp]    = ts_cells{:};
            [waveforms_all.ptp_amplitude] = ptp_cells{:};
            [waveforms_all.fwhm]          = fwhm_cells{:};
            [waveforms_all.clusters]      = cluster_cells{:};
            % Save back into res
            results.spike_results(portIdx).waveforms_all = waveforms_all;
            end
         % Replace back into h.figure.UserData
            if iscell(h.figure.UserData)
                allresults = h.figure.UserData;
                allresults{expIdx} = results;
                set(h.figure, 'UserData', allresults);
            else
                set(h.figure, 'UserData', results);
            end
            guidata(h.figure,h);
            h=guidata(h.figure);    
end
    spike_feats_callback(h);
    h=guidata(h.figure);
    update_spike_summary_tab(h);

    m = msgbox('Curated spikes saved back into experiment structures.','Success');
    pause(2);
    if ishandle(m), close(m); end
end
