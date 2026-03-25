function plot_cluster_callback(h,delta)
    h = guidata(h.figure);  
    set_status(h.figure,"loading","Plotting Clusters...");

    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    if nargin<2
        delta = 0;
    end

    %  Get selected ports 
    idx = h.portList.Value;        
    map = h.portList.UserData;     
    selected = map(idx,:);            

    % Handle multiple selections
    % if size(selected,1) > 1
    %     choicesStr = cell(size(selected,1),1);
    %     for i = 1:size(selected,1)
    %         expIdxTmp = selected(i,1);
    %         portIdxTmp = selected(i,2);
    %         if iscell(h.figure.UserData)
    %             resultsTmp = h.figure.UserData{expIdxTmp};
    %         else
    %             resultsTmp = h.figure.UserData;
    %         end
    %         portID = resultsTmp.ports(portIdxTmp).port_id;
    %         choicesStr{i} = sprintf('Exp %d, Port %d', expIdxTmp, portID);
    %     end
    %     sel = listdlg('PromptString','Multiple experiments/ports selected. Choose one:', ...
    %                   'SelectionMode','single', 'ListString', choicesStr);
    %     if isempty(sel), return; end
    %     expIdx = selected(sel,1);
    %     selected_idx = selected(sel,2);
    % else
        expIdx = selected(1,1);
        selected_idx = selected(1,2);
    %end    
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    selectedport = results.ports(selected_idx).port_id;
    waveforms_all = results.spike_results(selected_idx).waveforms_all;

    % if ~isfield(waveforms_all,'clusters')
    %     clusters = clusters_callback(h);
    %     waveforms_all = results.spike_results(selected_idx).waveforms_all;
    % else
    %     clusters = [waveforms_all.clusters]';
    % end
    if isfield(h,'clusterListBox')
            %  Filter selected clusters 
        selectedStrings = get(h.clusterListBox,'String');  % all strings in listbox
        selectedIdx     = get(h.clusterListBox,'Value');   % indices of selected strings
        if ~isempty(selectedIdx) && ~isempty(selectedStrings)
            if ~isfield(waveforms_all,'clusters')
                clusters_callback(h,1);
                h = guidata(h.figure);
                if iscell(h.figure.UserData)
                    results = h.figure.UserData{expIdx};
                else
                    results = h.figure.UserData;
                end
                waveforms_all = results.spike_results(selected_idx).waveforms_all;
            end
        end
    end


    detected_clusters = str2double(selectedStrings(selectedIdx));
    clusters = [waveforms_all.clusters]';
    all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
    channels     = cell2mat(arrayfun(@(x) x.channel, waveforms_all, 'UniformOutput', false)');

    %  Timing 
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

    %  Clear old content 
    delete(findall(h.clusters_tab, 'Type', 'uipanel'));
    if ~isfield(h, 'clustPanel') || ~isvalid(h.clustPanel)
        h.clustPanel = uipanel(h.clusters_tab, ...
            'Position', [0 0.15 1 0.8], ...
            'BackgroundColor', backgdcolor, ...
            'ForegroundColor', accentcolor);
    end
    delete(findall(h.clustPanel, 'Type', 'axes'));       % remove old plots
    delete(findall(h.clustPanel, 'Tag','pagingButton')); % remove old Prev/Next buttons


    %  Tiledlayout for plots 
    tiled = tiledlayout(h.clustPanel, 'flow', ...
        'TileSpacing','compact','Padding','compact');
    tiled.Units = 'normalized';
    tiled.Position = [0.08 0.18 0.84 0.7]; % slightly more margin for labels

    %  Colors 
    nC = numel(unique(clusters));
    colors = jet(nC);


    %  Layout choice 
    if get(h.clust_plot_toggle, 'Value')
        tileIDs = detected_clusters;
        tile_label = 'Cluster';
    else
        tileIDs = unique(channels);
        tile_label = 'Ch';
    end

    %nTiles = numel(tileIDs);
    %  Paging setup 
    nTilesPerPage = 12;
    nPages = ceil(numel(tileIDs)/nTilesPerPage);
    
    % Initialize currentPage if missing
    if ~isfield(h,'currentPage') || isempty(h.currentPage)
        h.currentPage = 1;
    end
    
    % Update page with delta (Prev/Next)
    h.currentPage = h.currentPage + delta;
    h.currentPage = max(1, min(nPages, h.currentPage));  % clamp
    
    % Store updated h before plotting
    guidata(h.figure,h);
    
    startIdx = (h.currentPage-1)*nTilesPerPage + 1;
    endIdx   = min(h.currentPage*nTilesPerPage, numel(tileIDs));
    tileIDsPage = tileIDs(startIdx:endIdx);

    %nTiles = min(numel(tileIDs),12);
    lineHandles = gobjects(numel(detected_clusters),1);

    %  Style settings 
    lw.main = 1.5;
    fnt.labels = 8;   % bump font size for clarity
    fnt.ticks  = 8;

    %  Plotting 
    for ti = 1:numel(tileIDsPage)
        ax = nexttile(tiled, ti);
        hold(ax,'on')

        currentID = tileIDsPage(ti);

        for k = 1:numel(detected_clusters)
            clus = detected_clusters(k);
            if get(h.clust_plot_toggle, 'Value')
                inds = find(clusters == currentID & clusters==clus);
            else
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
                         'Color', colors(k,:), 'LineWidth', lw.main);
            lineHandles(k) = hLine;
        end

        title(ax, sprintf('%s %d', tile_label, currentID), ...
              'FontSize', fnt.labels, 'FontWeight','bold');
        xlabel(ax,'Time (ms)');
        ylabel(ax,'Voltage (\muV)');
        set_pubstyle(ax,fnt);
    end
    if nPages > 1
        h.btnPrev = uicontrol('Parent', h.clustPanel,'Style','pushbutton','String','Prev',...
                              'Units','normalized','Position',[0.2 0.01 0.1 0.05],...
                              'Tag','pagingButton','Callback',@(src,evt) plot_cluster_callback(h,-1));
        h.btnNext = uicontrol('Parent', h.clustPanel,'Style','pushbutton','String','Next',...
                              'Units','normalized','Position',[0.7 0.01 0.1 0.05],...
                              'Tag','pagingButton','Callback',@(src,evt) plot_cluster_callback(h,1));
    end
    %  Single toolbar 
    axtoolbar(tiled, {'save','zoomin','zoomout','restoreview','pan'});
    %  Clean old legend panel 
    delete(findall(h.clusters_tab, 'Tag','legendPanel'));
    
    
    legendPanel = uipanel('Parent', h.clusters_tab, ...
            'Units','normalized', ...
            'Position',[0 0.05 0.8 0.1], ... 
            'BorderType','none', ...
            'BackgroundColor',backgdcolor, ...
            'Tag','legendPanel');
        
    axL = axes('Parent', legendPanel, ...
        'Position',[0.05 0.15 0.9 0.8], ...
        'Visible','off'); 
    hold(axL,'on');
    
    %  Create proxy lines 
    proxy = gobjects(numel(detected_clusters),1);
    for k = 1:numel(detected_clusters)
        proxy(k) = plot(axL, nan, nan, ...
            'LineWidth', lw.main, ...
            'Color', colors(k,:), ...
            'DisplayName', sprintf('Cluster %d', detected_clusters(k)));
    end
    
    %  
    maxPerRow = 6; 
    nCols = min(numel(detected_clusters), maxPerRow);
    
    lgd = legend(axL, proxy, ...
        'Orientation','horizontal', ...
        'Box','off', ...
        'FontSize', fnt.ticks, ...
        'Location','north');
    
    lgd.NumColumns = nCols;
    
    %  Compact spacing (fits more cleanly) 
    lgd.ItemTokenSize = [12,10];
    
    %  Force legend to fill panel properly 
    lgd.Units = 'normalized';
    lgd.Position = [0 0 1 1];

    % % Legend in reserved panel bottom (same parent as plots)
    % legendPanel = uipanel('Parent', h.clusters_tab, 'Units','normalized', ...
    %                       'Position',[0.05 0.07 0.8 0.07], ...
    %                       'BorderType','etchedin','BackgroundColor',backgdcolor);
    % 
    % axL = axes('Parent', legendPanel, 'Visible','off'); hold(axL,'on');
    % 
    % % Create proxy lines for legend (one parent, no data)
    % proxy = gobjects(numel(detected_clusters),1);
    % for k = 1:numel(detected_clusters)
    %     proxy(k) = plot(axL, nan, nan, 'LineWidth', lw.main, ...
    %         'Color', colors(k,:), ...
    %         'DisplayName', sprintf('Cluster %d', detected_clusters(k)));
    % end
    % 
    % lgd = legend(axL, proxy, ...
    %     'Orientation','horizontal', 'Box','off', ...
    %     'FontSize', fnt.ticks, 'Location','southoutside');
    % % Force 2 rows
    % lgd.NumColumns = ceil(numel(detected_clusters)/2);
    % 
    % % Position at bottom center
    % lgd.Units = 'normalized';
    % lgd.Position = [0.1 0.1 0.8 1];
    %  Super title 
    sgtitle(tiled, sprintf('Exp %d Port: %d',expIdx, selectedport), ...
        'FontSize', fnt.labels+2, 'FontWeight','bold');

    %  Update cluster list 
    set_status(h.figure,"ready","Cluster Plot Complete...");

end

%  Helper: Publication style 
function set_pubstyle(ax,fnt)
    set(ax,'Box','off','TickDir','out','LineWidth',0.75, ...
        'FontSize',fnt.ticks,'FontName','Arial');
end
