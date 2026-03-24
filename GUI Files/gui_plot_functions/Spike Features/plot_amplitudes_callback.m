function plot_amplitudes_callback(h)
    h = guidata(h.figure);  
    set_status(h.figure,"loading","Plotting Amplitudes...");

    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB

    % Get selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);            
    if isempty(selected), return; end
    numTiles = size(selected,1);

    % Precompute amplitude data
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
        clusterStr = 'All Clusters';
        if isfield(h,'clusterListBox')
           selectedStrings = get(h.clusterListBox,'String');  % all strings in listbox
            selectedIdx     = get(h.clusterListBox,'Value');   % indices of selected strings
            if ~isempty(selectedIdx) && ~isempty(selectedStrings)
                if ~isfield(waveforms_all,'clusters')
                    [waveforms_all.clusters] = deal(1);
                else
                selectedClusters = str2double(selectedStrings(selectedIdx));
                waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
                clusterStr = sprintf('Clusters: [%s]', strjoin(selectedStrings(selectedIdx), ','));
                end
            end
        end

        analysed_chans = unique([waveforms_all.channel]);

        % Determine channels to plot
        if h.feats_mode_toggle.Value  % global/cumulative
            chansToPlot = analysed_chans;  
        else
            % Exclude bad/noisy channels if toggles exist
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
                mask = mask & ~noisy;
            end
            channels = channels(mask);

            SeriesNumber = round(get(h.series_slider, 'Value'));
            chansToPlot = channels(SeriesNumber);  % only selected channel
        end

        % Gather amplitudes per channel
        amp_data = cell(length(chansToPlot),1);
        for c = 1:length(chansToPlot)
            ch = chansToPlot(c);
            idxCh = find([waveforms_all.channel]  == ch);
            if ~isempty(idxCh)
                amp_data{c} = [waveforms_all(idxCh).ptp_amplitude];
            else
                amp_data{c} = [];
            end
        end

        data(i).expIdx = expIdx;
        data(i).portIdx = port_idx;
        data(i).channels = chansToPlot;
        data(i).amp_data = amp_data;
    end

    % Create / adjust plot panel
    togglePos = get(h.feats_mode_toggle,'Position'); 
    panelBottom = togglePos(2) + togglePos(4) + 0.01; % leave 1% padding

    if isfield(h,'ampsPanel') && isvalid(h.ampsPanel)
        delete(h.ampsPanel);
    end

    h.ampsPanel = uipanel('Parent', h.amplitudes_tab, 'Units','normalized', ...
                          'Position',[0, panelBottom, 1, 1-panelBottom], ...
                          'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);

    % Clear old axes in panel
    existingAxes = findall(h.ampsPanel,'Type','axes');
    delete(existingAxes);

    % Plotting
    tlo = tiledlayout(h.ampsPanel, 'flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');
    colors = lines(32);
    % ---- Compute global axis limits ----
    allAmps = [];
    
    for i = 1:numTiles
        allAmps = [allAmps, horzcat(data(i).amp_data{:})];
    end
    
    if isempty(allAmps)
        return
    end
       
    if ~isfield(h,'hist_settings') || ~isfield(h.hist_settings,'amp')
        h.hist_settings.amp.binWidth = 1;
        h.hist_settings.amp.xmin = min(allAmps);
        h.hist_settings.amp.xmax = max(allAmps);
        h.hist_settings.amp.ymax = [];
    end
    globalXLim = [h.hist_settings.amp.xmin,h.hist_settings.amp.xmax];

    edges = globalXLim(1): h.hist_settings.amp.binWidth :globalXLim(2);
    maxCount = 0;
    
    for i = 1:numTiles
        amps = horzcat(data(i).amp_data{:});
        if ~isempty(amps)
            counts = histcounts(amps, edges);
            maxCount = max(maxCount, max(counts));
        end
    end
    if isempty(h.hist_settings.amp.ymax)
         h.hist_settings.amp.ymax = maxCount;
    end

    globalYLim = [0 h.hist_settings.amp.ymax];
    for i = 1:numTiles
        ax = nexttile(tlo);
        hold(ax,'on');

        if h.feats_mode_toggle.Value  % cumulative/global
            allamps = horzcat(data(i).amp_data{:});  
             histogram(ax, allamps, 'BinEdges', edges, ...
                          'FaceColor', colors(mod(i-1,32)+1,:), ...
                          'DisplayName', sprintf('Exp %d, Port %d', data(i).expIdx, data(i).portIdx));
            titleStr = sprintf('Exp %d, Port %d (Global)\n%s\n', data(i).expIdx, data(i).portIdx,clusterStr);

        else  % single channel
            histogram(ax, data(i).amp_data{1}, 'BinEdges', edges, 'FaceColor', 'k');
            titleStr = sprintf('Exp %d, Port %d, Ch %d\n%s\n', ...
                               data(i).expIdx, data(i).portIdx, data(i).channels(1),clusterStr);
        end

        xlabel(ax, 'Amplitude (\muV)');
        ylabel(ax, 'Count');
        title(ax, titleStr);
        set(ax, 'Box', 'off', 'Color', 'none','TickDir','out');
        axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});
    
        xlim(ax, globalXLim);
        ylim(ax, globalYLim);
    end
    set_status(h.figure,"ready","Amplitude Plot Complete...");

end
