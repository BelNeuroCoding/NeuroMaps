function plot_ibi_callback(h)
    h = guidata(h.figure);  
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    isi_threshold = str2double(get(h.burst_param(1),'String'));
    min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
    min_burst_duration = str2double(get(h.burst_param(3),'String'));
    % Get selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);            
    if isempty(selected), return; end

    numTiles = size(selected,1);

    % Precompute IBI data
    data = struct();
    for i = 1:numTiles
        expIdx = selected(i,1);
        port_idx = selected(i,2);

        % Load results
        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end
        waveforms_all = results.spike_results(port_idx).waveforms_all;
        ptp  = [waveforms_all.ptp_amplitude]';
        fwhm = [waveforms_all.fwhm]';
        if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)
    
                r = h.spike_filter_ranges;
            
                idx_keep = ...
                    ptp  >= r.amp(1)  & ptp  <= r.amp(2) & ...
                    fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
            
                waveforms_all = waveforms_all(idx_keep);
        end
        % Filter selected clusters if clusterListBox exists
        if isfield(h,'clusterListBox')
            selectedClusters = get(h.clusterListBox,'Value');
            if ~isempty(selectedClusters)
                if ~isfield(waveforms_all,'clusters')
                    [waveforms_all.clusters] = deal(1);
                end
                waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
            end
        end
        analysed_chans = unique([waveforms_all.channel]);
        
        % Determine channels to plot
        if h.feats_mode_toggle.Value  % global/cumulative
            chansToPlot = analysed_chans;  
        else
             % Check if the user wants to analyze only good channels
            exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
            exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
            channels = [results.channels(port_idx).id];
            mask = true(1,numel(channels));
        
            if exclude_impedance_chans_toggle
                bad_impedance = results.channels(port_idx).bad_impedance;
                mask = mask & ~bad_impedance;
            end
            if exclude_noisy_chans_toggle
                noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
                mask =mask & ~noisy;
            end
            channels = channels(mask);
            SeriesNumber = round(get(h.series_slider, 'Value'));
            chansToPlot = channels(SeriesNumber);  % only selected channel
        end

        % Gather IBI and burst count per channel
        IBI_data = cell(length(chansToPlot),1);
        numBursts = zeros(length(chansToPlot),1);
        for c = 1:length(chansToPlot)
            ch = chansToPlot(c);
            idxCh = find([waveforms_all.channel] == ch);
            if ~isempty(idxCh)
                bursts = detect_bursts_mod([waveforms_all(idxCh).time_stamp], isi_threshold, min_spikes_per_burst, min_burst_duration);
                % Compute inter-burst intervals (IBI)
                IBI_data{c} = compute_interburst_interval(bursts);
                numBursts(c) = numel(bursts);
            else
                IBI_data{c} = [];
                numBursts(c) = 0;
            end
        end

        data(i).expIdx = expIdx;
        data(i).portIdx = port_idx;
        data(i).channels = chansToPlot;
        data(i).IBI_data = IBI_data;
        data(i).numBursts = numBursts;
    end

    % Create / adjust plot panel
    togglePos = get(h.feats_mode_toggle,'Position'); 
    panelBottom = togglePos(2) + togglePos(4) + 0.01; % leave 1% padding

    if isfield(h,'ibiPanel') && isvalid(h.ibiPanel)
        delete(h.ibiPanel);
    end

    h.ibiPanel = uipanel('Parent', h.ibi_tab, 'Units','normalized', ...
                         'Position',[0, panelBottom, 1, 1-panelBottom], ...
                         'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);

    % Clear old axes in panel
    existingAxes = findall(h.ibiPanel,'Type','axes');
    delete(existingAxes);

    % Plotting
    tlo = tiledlayout(h.ibiPanel, 'flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');
    colors = lines(32);
    allibi = [];
    
    for i = 1:numTiles
        allibi = [allibi, horzcat(data(i).IBI_data{:})];
    end
    
    if isempty(allibi)
        warndlg('No bursts to display for the selected channels/time window.', 'No Bursts');
        return
    end
    
    globalXLim = [min(allibi),20];
    binWidth = 0.1;   % binwidth

    edges = globalXLim(1):binWidth:globalXLim(2);
    maxCount = 0;
    
    for i = 1:numTiles
        ibi = horzcat(data(i).IBI_data{:});
        if ~isempty(ibi)
            counts = histcounts(ibi, edges);
            maxCount = max(maxCount, max(counts));
        end
    end
    
    globalYLim = [0 maxCount];
    for i = 1:numTiles
        ax = nexttile(tlo);
        hold(ax,'on');

        if h.feats_mode_toggle.Value  % cumulative/global
             allIBI = horzcat(data(i).IBI_data{:});  
             histogram(ax, allIBI, 'BinEdges', edges, ...
                          'FaceColor', colors(mod(i-1,32)+1,:), ...
                          'DisplayName', sprintf('Exp %d, Port %d', data(i).expIdx, data(i).portIdx));

           % legend(ax,'show','Location','northeast');
            titleStr = sprintf('Exp %d, Port %d (Global) - %d Bursts', ...
                               data(i).expIdx, data(i).portIdx, sum(data(i).numBursts));
        else  % single channel
            histogram(ax, data(i).IBI_data{1}, 'BinEdges', edges,'FaceColor', 'k');
            titleStr = sprintf('Exp %d, Port %d, Ch %d - %d Bursts', ...
                               data(i).expIdx, data(i).portIdx, data(i).channels(1), data(i).numBursts(1));
        end

        xlabel(ax, 'Inter-Burst Interval (s)');
        ylabel(ax, 'Count');
        title(ax, titleStr);
        set(ax, 'Box', 'off', 'Color', 'none');
        xlim(ax, globalXLim);
        ylim(ax, globalYLim);
        axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});
    end
end
