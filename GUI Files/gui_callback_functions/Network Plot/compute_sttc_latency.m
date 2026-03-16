function compute_sttc_latency(h, dtv)
    h = guidata(h.figure);
    %%  Get selected port 
    idx = h.portList.Value;              % positions in the listbox
    map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
    selected = map(idx,:);
    
    % Only allow one experiment & port
    if size(selected,1) > 1
        uniqueExpts = unique(selected(:,1));
        uniquePorts = unique(selected(:,2));
        if numel(uniqueExpts) > 1 || numel(uniquePorts) > 1
            errordlg('Please select only 1 experiment and 1 port for plotting traces.');
            return
        end
    end
    
    expIdx = selected(1,1);
    selected_idx = selected(1,2);      
    
    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    tstamps = results.timestamps;
    networkconndata = results.spike_results(selected_idx).waveforms_all;
    ptp  = [networkconndata.ptp_amplitude]';
    fwhm = [networkconndata.fwhm]';
    if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)

            r = h.spike_filter_ranges;
        
            idx_keep = ...
                ptp  >= r.amp(1)  & ptp  <= r.amp(2) & ...
                fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
        
            networkconndata = networkconndata(idx_keep);
    end

    if ~isfield(networkconndata,'clusters')
        [networkconndata.clusters] = deal(1);
    else
        selectedStrings = get(h.clusterListBox,'String');  % all strings in listbox
        selectedIdx     = get(h.clusterListBox,'Value');   % indices of selected strings
    if isfield(networkconndata,'clusters') && ~isempty(selectedIdx)
        selectedClusters = str2double(selectedStrings(selectedIdx));
        networkconndata = networkconndata(ismember([networkconndata.clusters], selectedClusters));
    end
    end

    %  Ask for dtv if missing
    if nargin < 2 || isempty(dtv)
        dtv = str2double(get(h.dt_window,'String'));
        if isempty(dtv), return; end
    end

    %  Extract spike trains
    [spikeMatrix, spike_times, unique_channels, time_vector] = ...
        build_spike_trains(networkconndata, tstamps);

    %  Run analysis if not cached
        [sttc_matrix, latency_matrix] = ...
            compute_sttc_and_latency(spikeMatrix, spike_times, unique_channels, time_vector, dtv);

        results.network_analysis(selected_idx).sttc = sttc_matrix;
        results.network_analysis(selected_idx).latency = latency_matrix;
        results.network_analysis(selected_idx).unique_chans = unique_channels;
    
        % Save updated results
        if iscell(h.figure.UserData)
            allresults = h.figure.UserData;
            allresults{expIdx} = results;
            set(h.figure, 'UserData', allresults);
        else
            set(h.figure, 'UserData', results);
        end

    %  Plot results
    plot_sttc_latency(h, sttc_matrix, latency_matrix, unique_channels);
end
