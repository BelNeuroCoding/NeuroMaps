function plot_cluster_callback(h)
    h = guidata(h.figure);  
    % Get selected ports
    idx = h.portList.Value;        
    map = h.portList.UserData;     
    selected = map(idx,:);            

    % Handle multiple selections
    if size(selected,1) > 1
        choicesStr = cell(size(selected,1),1);
        for i = 1:size(selected,1)
            expIdxTmp = selected(i,1);
            portIdxTmp = selected(i,2);
            if iscell(h.figure.UserData)
                resultsTmp = h.figure.UserData{expIdxTmp};
            else
                resultsTmp = h.figure.UserData;
            end
            portID = resultsTmp.ports(portIdxTmp).port_id;
            choicesStr{i} = sprintf('Exp %d, Port %d', expIdxTmp, portID);
        end

        sel = listdlg('PromptString','Multiple experiments/ports selected. Choose one:', ...
                      'SelectionMode','single', 'ListString', choicesStr);
        if isempty(sel), return; end
        expIdx = selected(sel,1);
        selected_idx = selected(sel,2);
    else
        expIdx = selected(1,1);
        selected_idx = selected(1,2);
    end


    % Load results

    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    selectedport = results.ports(selected_idx).port_id;
    waveforms_all = results.spike_results(selected_idx).waveforms_all;

    if ~isfield(waveforms_all,'clusters')
        clusters = clusters_callback(h);
        detected_clusters = unique(clusters);
        waveforms_all = results.spike_results(selected_idx).waveforms_all;
    else
        clusters = [waveforms_all.clusters]';
        detected_clusters = unique(clusters);
    end

    all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
    channels     = cell2mat(arrayfun(@(x) x.channel, waveforms_all, 'UniformOutput', false)');

    fs = results.fs;
    if exist('spike_config.mat','file')
        cfg = load('spike_config.mat'); cfg = cfg.config;
        pre_time  = cfg.pre_time; 
        post_time = cfg.post_time;
    else
        pre_time  = 0.8;  
        post_time = 0.8;  
    end

    N_samples = size(all_waveforms, 2);
    time_vector = linspace(-pre_time, post_time, N_samples);



    % Clear old plots
    delete(findall(h.clusters_tab, 'Type', 'axes'));
    % Colors
    colors = parula(numel(detected_clusters));
    % Determine layout: channels or clusters

    if get(h.clust_plot_toggle, 'Value')  % Cluster View ON
        tileIDs = detected_clusters;
        tile_label = 'Cluster';
    else  % Channel view
        tileIDs = unique(channels);
        tile_label = 'Ch';
    end

    nTiles = numel(tileIDs);
    nRows = ceil(sqrt(nTiles));
    nCols = ceil(nTiles/nRows);

    lineHandles = gobjects(numel(detected_clusters),1);

    marginX = 0.05;   % left/right
    marginY_top = 0.1;    % space at top
    marginY_bottom = 0.25; % reserve space at bottom for toggles
    gapX = 0.04;      % horizontal gap
    gapY = 0.1;      % vertical gap
    
    tileWidth  = (1 - 2*marginX - (nCols-1)*gapX) / nCols;
    tileHeight = (1 - marginY_top - marginY_bottom - (nRows-1)*gapY) / nRows;
    
    for ti = 1:nTiles
        row = ceil(ti / nCols);
        col = mod(ti-1, nCols) + 1;
    
        left   = marginX + (col-1)*(tileWidth+gapX);
        bottom = 1 - marginY_top - row*tileHeight - (row-1)*gapY;
    
        % only use axes(), not subplot()
        ax = axes('Parent', h.clusters_tab, ...
                  'Position', [left bottom tileWidth tileHeight]);
        hold(ax,'on')
    
        currentID = tileIDs(ti);
    
        for k = 1:numel(detected_clusters)
            clus = detected_clusters(k);
    
            if get(h.clust_plot_toggle, 'Value')  % Cluster view: show all channels in this cluster
                inds = find(clusters == currentID & clusters==clus);
            else  % Channel view: show all clusters in this channel
                inds = find(channels == currentID & clusters==clus);
            end
    
            if isempty(inds), continue; end
    
            wf = all_waveforms(inds,:);
            mean_wf = mean(wf,1);
            std_wf  = std(wf,[],1);
    
            % Shaded std
            fill(ax, [time_vector fliplr(time_vector)], ...
                     [mean_wf+std_wf fliplr(mean_wf-std_wf)], ...
                     colors(k,:), 'FaceAlpha',0.2, 'EdgeColor','none');
    
            hLine = plot(ax, time_vector, mean_wf, ...
                         'Color', colors(k,:), 'LineWidth',2);
            lineHandles(k) = hLine;
        end
    
        title(ax, sprintf('%s %d', tile_label, currentID));
        %ylim(ax, [-100 100]);
        %axis(ax,'off');
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    end

    % Legend

    legendEntries = arrayfun(@(c) sprintf('Cluster %d', c), detected_clusters, 'UniformOutput', false);
    lgd = legend(lineHandles, legendEntries, 'NumColumns', 4, 'Position',[0.4 0.09 0.1 0.1],'Parent', h.clusters_tab);

    sgtitle(['Port: ' num2str(selectedport)])
    set(h.clusterListBox,'String',cellstr(num2str(detected_clusters)));
end
