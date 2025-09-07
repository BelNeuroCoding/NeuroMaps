function plot_isi_callback(h)
    h = guidata(h.figure);  
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    % Get selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);            

    if isempty(selected)
        return;
    end

    numTiles = size(selected,1);

    % Precompute ISI data
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

        % Gather ISIs per channel
        ISI_ms = cell(length(chansToPlot),1);
        for c = 1:length(chansToPlot)
            ch = chansToPlot(c);
            idxCh = find([waveforms_all.channel] == ch);
            if ~isempty(idxCh)
                ISI_vals = compute_isi([waveforms_all(idxCh).time_stamp]);
                ISI_ms{c} = [ISI_vals]*1000;  
            else
                ISI_ms{c} = [];
            end
        end

        data(i).expIdx = expIdx;
        data(i).portIdx = port_idx;
        data(i).channels = chansToPlot;
        data(i).ISI_ms = ISI_ms;
    end

    % Create / adjust plot panel
    togglePos = get(h.feats_mode_toggle,'Position'); 
    panelBottom = togglePos(2) + togglePos(4) + 0.01; % leave 1% padding

    % Clear previous panel if exists
    if isfield(h,'isiPanel') && isvalid(h.isiPanel)
        delete(h.isiPanel);
    end

    h.isiPanel = uipanel('Parent', h.isi_tab, 'Units','normalized', ...
                         'Position',[0, panelBottom, 1, 1-panelBottom],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor);

    % Clear old axes in panel
    existingAxes = findall(h.isiPanel,'Type','axes');
    delete(existingAxes);

    % Plotting
    % Plotting
    tlo = tiledlayout(h.isiPanel, 'flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');
    colors = lines(32);  % 32 unique colors
    
    allHandles = [];   % store histogram handles
    allLabels  = {};   % store labels
    
    for i = 1:numTiles
        ax = nexttile(tlo);
        hold(ax,'on');
    
        if h.feats_mode_toggle.Value  % cumulative/global
            for c = 1:length(data(i).channels)
                hHist = histogram(ax, data(i).ISI_ms{c}, 'BinWidth', 1, ...
                    'FaceColor', colors(mod(c-1,32)+1,:), ...
                    'DisplayName', sprintf('Ch %d', data(i).channels(c)));
                allHandles(end+1) = hHist; %#ok<AGROW>
                allLabels{end+1} = hHist.DisplayName; %#ok<AGROW>
            end
            titleStr = sprintf('Exp %d, Port %d (Global)', data(i).expIdx, data(i).portIdx);
        else  % single channel
            hHist = histogram(ax, data(i).ISI_ms{1}, 'BinWidth', 1, 'FaceColor', 'k', ...
                'DisplayName', sprintf('Ch %d', data(i).channels(1)));
            allHandles(end+1) = hHist;
            allLabels{end+1}  = hHist.DisplayName;
            titleStr = sprintf('Exp %d, Port %d, Ch %d', data(i).expIdx, data(i).portIdx, data(i).channels(1));
        end
    
        xlabel(ax, 'Inter-spike Interval (ms)');
        ylabel(ax, 'Count');
        title(ax, titleStr);
        set(ax, 'Box', 'off', 'Color', 'none');
        xlim(ax, [0 100]);
        axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});
    end
    

end
