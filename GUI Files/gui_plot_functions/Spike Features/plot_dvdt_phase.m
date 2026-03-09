function plot_dvdt_phase(h)
    h = guidata(h.figure);  
    backgdcolor = [1 1 1];
    accentcolor = [0.1 0.4 0.6];

    % Get selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);            

    if isempty(selected)
        return;
    end

    numTiles = size(selected,1);
    data = struct();

    %  Gather waveform data per selected port 
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
            %  Filter selected clusters 
            selectedStrings = get(h.clusterListBox,'String');  % all strings in listbox
            selectedIdx     = get(h.clusterListBox,'Value');   % indices of selected strings
            if ~isempty(selectedIdx)
                if ~isfield(waveforms_all,'clusters')
                    [waveforms_all.clusters] = deal(1);
                else
                selectedClusters = str2double(selectedStrings(selectedIdx));
                waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
                end
            end
        end

        data(i).waveforms_all = waveforms_all;
        data(i).results = results;
        data(i).expIdx = expIdx;
        data(i).portIdx = port_idx;
    end

    %  Create/adjust plot panel 
    togglePos = get(h.feats_mode_toggle,'Position'); 
    panelBottom = togglePos(2) + togglePos(4) + 0.01;

    if isfield(h,'dvdtPanel') && isvalid(h.dvdtPanel)
        delete(h.dvdtPanel);
    end

    h.dvdtPanel = uipanel('Parent', h.ph_tab, 'Units','normalized', ...
                          'Position',[0, panelBottom, 1, 1-panelBottom], ...
                          'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);

    % Clear old axes
    existingAxes = findall(h.dvdtPanel,'Type','axes');
    delete(existingAxes);

    tlo = tiledlayout(h.dvdtPanel, 'flow', 'TileSpacing', 'Compact', 'Padding', 'Compact');

    %  Loop over selected ports 
    for i = 1:numTiles
        waveforms_all = data(i).waveforms_all;
        results = data(i).results;

        fs = results.fs;

        % Determine grouping based on toggles
        if h.feats_mode_toggle.Value  % Global
            if h.feats_clust_mode_toggl.Value
                groupingIDs = [waveforms_all.clusters];
                uniqueIDs = unique(groupingIDs);
                labelType = 'Cluster';
            else
                channels = [waveforms_all.channel];
                groupingIDs = channels;
                uniqueIDs = unique(groupingIDs);
                labelType = 'Channel';
            end
        else  % Single channel
            SeriesNumber = round(get(h.series_slider, 'Value'));
            all_chans = results.channels(port_idx).id;
            mask = true(1,numel(all_chans));
            if get(h.excl_imp_toggle,'Value')
                mask = mask & ~results.channels(port_idx).bad_impedance;
            end
            if get(h.excl_high_STD_toggle,'Value')
                noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
                mask = mask & ~noisy;
            end
            all_chans = all_chans(mask);
            selectedChMask = [waveforms_all.channel] == all_chans(SeriesNumber);
            waveforms_all = waveforms_all(selectedChMask);
            if h.feats_clust_mode_toggl.Value
                groupingIDs = [waveforms_all.clusters];
                uniqueIDs = unique(groupingIDs);
                labelType = 'Cluster';
            else
                groupingIDs = [waveforms_all.channel];
                uniqueIDs = unique(groupingIDs);
                labelType = 'Channel';
            end
        end

        colors = lines(numel(uniqueIDs));

        % Flatten waveforms
        all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');

        ax = nexttile(tlo);
        cla(ax,'reset');
        hold(ax,'on'); grid(ax,'on');

        lineHandles = gobjects(numel(uniqueIDs),1);
        legendEntries = cell(numel(uniqueIDs),1);

        %  Plot per group 
        for idxUID = 1:numel(uniqueIDs)
            thisID = uniqueIDs(idxUID);
            mask = (groupingIDs == thisID);

            wf = cat(2, all_waveforms(mask,:)'); % [nSamples x nSpikes]
            mask = max(wf,[],1) < abs(min(wf,[],1));
            wf(:,mask) = -wf(:,mask);
            if isempty(wf)
                continue;
            end
            mean_wf = mean(wf,2);

            % Compute dV/dt
            dVdt = diff(mean_wf) * fs;

            % Normalize
            mean_norm = normalize_waveform(mean_wf);
            dVdt_norm = normalize_waveform(dVdt);
            pts = [mean_norm(1:end-1), dVdt_norm];
            k = convhull(pts(:,1), pts(:,2));

            tagName = sprintf('PhaseID%d', uniqueIDs(idxUID));
            lineHandles(idxUID) = plot(ax, pts(:,1), pts(:,2), 'Color', colors(idxUID,:), ...
                                       'LineWidth', 2, 'Tag', tagName);
            plot(ax, pts(k,1), pts(k,2), 'k-.', 'LineWidth', 1, 'Tag', tagName);
            legendEntries{idxUID} = sprintf('%s %d',labelType,  thisID);
        end

        xlabel(ax, 'V^*', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(ax, '(dV/dt)^*', 'FontSize', 12, 'FontWeight', 'bold');
        title(ax, sprintf('Exp %d, Port %d %s', data(i).expIdx, data(i).portIdx));
        axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});

        %  Interactive legend 
        hLeg = gobjects(numel(uniqueIDs),1);
        for k = 1:numel(uniqueIDs)
            tagName = sprintf('PhaseID%d', uniqueIDs(k));
            hLeg(k) = plot(NaN, NaN, 'Color', colors(k,:), 'LineWidth', 2, 'Tag', tagName, 'HandleVisibility','off');
        end
        lgd = legend(ax, hLeg, legendEntries, 'Location','northeastoutside');
        lgd.ItemHitFcn = @(src, evt) toggleVisibility(evt, ax);
        hold(ax,'off');
    end

    guidata(h.figure,h);

    %  Nested functions 
    function toggleVisibility(evt, ax)
        tag = evt.Peer.Tag;
        objs = findobj(ax, 'Tag', tag);
        if any(strcmp({objs.Visible}, 'on'))
            set(objs, 'Visible', 'off');
        else
            set(objs, 'Visible', 'on');
        end
    end

    function norm_waveform = normalize_waveform(waveform)
        max_abs_val = max(abs(waveform));
        if max_abs_val > 0
            norm_waveform = waveform / max_abs_val;
        else
            norm_waveform = zeros(size(waveform));
        end
    end
end
