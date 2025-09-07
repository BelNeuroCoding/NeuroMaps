function plot_fwhm_callback(h)
    h = guidata(h.figure);  
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB

    
    % Get selected ports
    
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);            
    if isempty(selected), return; end

    numTiles = size(selected,1);

    
    % Precompute FWHM data
    
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

        % Gather FWHM per channel
        fwhm_data = cell(length(chansToPlot),1);
        for c = 1:length(chansToPlot)
            ch = chansToPlot(c);
            idxCh = find([waveforms_all.channel]  == ch);
            if ~isempty(idxCh)
                fwhm_data{c} = [waveforms_all(idxCh).fwhm];
            else
                fwhm_data{c} = [];
            end
        end

        data(i).expIdx = expIdx;
        data(i).portIdx = port_idx;
        data(i).channels = chansToPlot;
        data(i).fwhm_data = fwhm_data;
    end

    
    % Create / adjust plot panel
    
    togglePos = get(h.feats_mode_toggle,'Position'); 
    panelBottom = togglePos(2) + togglePos(4) + 0.01; % leave 1% padding

    if isfield(h,'fwhmPanel') && isvalid(h.fwhmPanel)
        delete(h.fwhmPanel);
    end

    h.fwhmPanel = uipanel('Parent', h.fwhm_tab, 'Units','normalized', ...
                          'Position',[0, panelBottom, 1, 1-panelBottom], ...
                          'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);

    % Clear old axes in panel
    existingAxes = findall(h.fwhmPanel,'Type','axes');
    delete(existingAxes);

    
    % Plotting
    
    tlo = tiledlayout(h.fwhmPanel, 'flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');
    colors = lines(32);

    for i = 1:numTiles
        ax = nexttile(tlo);
        hold(ax,'on');

        if h.feats_mode_toggle.Value  % cumulative/global
            for c = 1:length(data(i).channels)
                histogram(ax, data(i).fwhm_data{c}, 'BinWidth', 0.01, ...
                    'FaceColor', colors(mod(c-1,32)+1,:), ...
                    'DisplayName', sprintf('Ch %d', data(i).channels(c)));
            end
           % legend(ax,'show','Location','northeast');
            titleStr = sprintf('Exp %d, Port %d (Global)', data(i).expIdx, data(i).portIdx);
        else  % single channel
            histogram(ax, data(i).fwhm_data{1}, 'BinWidth', 0.01, 'FaceColor', 'k');
            titleStr = sprintf('Exp %d, Port %d, Ch %d', ...
                               data(i).expIdx, data(i).portIdx, data(i).channels(1));
        end

        xlabel(ax, 'FWHM (ms)');
        ylabel(ax, 'Count');
        title(ax, titleStr);
        set(ax, 'Box', 'off', 'Color', 'none');
        xlim(ax, [0 1]);
        axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});
    end
end
