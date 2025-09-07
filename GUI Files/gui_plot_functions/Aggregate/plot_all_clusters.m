function plot_all_clusters(h)
    h = guidata(h.figure);
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    unique_clusters = unique(h.cumulative_spikes.cluster_idx);
    nClusters = length(unique_clusters);
    colors = lines(nClusters);
    cluster_idx = h.cumulative_spikes.cluster_idx;
    % Delete previous axes in tab
    if isfield(h,'cluster_axes') && ~isempty(h.cluster_axes)
        delete(h.cluster_axes(ishandle(h.cluster_axes)));
    end
    plot_panel = uipanel('Parent', h.cluster_spike_groups, ...
        'Units','normalized', ...
        'Position',[0 0.1 1 0.9], ...
        'BackgroundColor', backgdcolor, ...
        'BorderType','none');
    % Layout
    h.cluster_axes = gobjects(0);
    % now put tiledlayout inside this panel
    t = tiledlayout(plot_panel, 2, 2, ...
        'TileSpacing','compact','Padding','compact');


    %  PCA scatter 
    ax1 = nexttile(t);
    hold(ax1,'on');

    wf = h.cumulative_spikes.all_waveforms;
    fwhm_all = h.cumulative_spikes.fwhm;       
    ptp_all = h.cumulative_spikes.ptp_amplitude;
    exp_all = h.cumulative_spikes.spike_origin_e;
    port_all = h.cumulative_spikes.spike_origin_p;
    chan_all = h.cumulative_spikes.channels;
    score = h.cumulative_spikes.score;
    if h.exp_pca_toggle.Value == 1
        %  Colour by experiment/port combination 
        expPort = [exp_all(:), port_all(:)];
        [~, ~, expPortGroups] = unique(expPort, 'rows');
        nGroups = max(expPortGroups);
        colors = lines(nGroups);

        for g = 1:nGroups
            scatter(ax1, score(expPortGroups==g,1), score(expPortGroups==g,2), ...
                20, colors(g,:), 'filled','MarkerFaceAlpha',0.6, 'MarkerEdgeAlpha',0.6);
        end
        xlabel(ax1,'PC1'); ylabel(ax1,'PC2'); title(ax1,'PCA by Exp/Port');
        results = h.figure.UserData;
        
        legend(ax1, arrayfun(@(g) sprintf('Exp %d Port %d', ...
            exp_all(find(expPortGroups==g,1)), results{exp_all(find(expPortGroups==g,1))}.ports(port_all(find(expPortGroups==g,1))).port_id), ...
            1:nGroups, 'UniformOutput', false), ...
            'Location','northeastoutside');

    else
        %  Default: colour by clusters 
        colors = lines(nClusters);
        for k = 1:nClusters
            scatter(ax1, score(cluster_idx==k,1), score(cluster_idx==k,2), ...
                20, colors(k,:), 'filled','MarkerFaceAlpha',0.6, 'MarkerEdgeAlpha',0.6);
        end
        xlabel(ax1,'PC1'); ylabel(ax1,'PC2'); title(ax1,'PCA by Cluster');
        legend(ax1, arrayfun(@(k) sprintf('Cluster %d', k), 1:nClusters, 'UniformOutput', false), ...
            'Location','northeastoutside');
    end

    grid(ax1,'on'); axis(ax1,'tight'); hold(ax1,'off');
    h.cluster_axes = [h.cluster_axes ax1];

    %  Clustered waveforms 
    ax2 = nexttile(t);
    hold(ax2,'on');
    if exist('spike_config.mat','file')
        cfg = load('spike_config.mat'); cfg = cfg.config;
        pre_time  = cfg.pre_time; 
        post_time = cfg.post_time;
    else
        pre_time  = 0.8;  
        post_time = 0.8;  
    end
    xaxis = linspace(-pre_time,post_time,size(wf,2));
    lineHandles = gobjects(nClusters,1);
    colors = lines(nClusters);
    for k = 1:nClusters
        idx_k = cluster_idx == k;
        mean_wf = mean(wf(idx_k,:),1);
        std_wf = std(wf(idx_k,:),1);
        lineHandles(k) = plot(ax2, xaxis, mean_wf, 'Color', colors(k,:), 'LineWidth', 2);
        fill(ax2, [xaxis fliplr(xaxis)], [mean_wf+std_wf fliplr(mean_wf-std_wf)], ...
             colors(k,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    end
    title(ax2,'Clustered Waveforms'); xlabel(ax2,'Normalized Time'); ylabel(ax2,'Amplitude');
    legend(ax2,lineHandles, arrayfun(@(k) sprintf('Cluster %d', k), 1:nClusters, 'UniformOutput', false),'Location','northeastoutside');
    hold(ax2,'off');
    h.cluster_axes = [h.cluster_axes ax2];

    %  FWHM per cluster (per channel per exp/port) 
    ax3 = nexttile(t);
    group_fwhm = cell(1,nClusters);
    for k = 1:nClusters
        idx_k = find(cluster_idx==k);
        keys = unique([exp_all(idx_k), port_all(idx_k), chan_all(idx_k)], 'rows');
        vals = nan(size(keys,1),1);
        for i = 1:size(keys,1)
            mask = exp_all==keys(i,1) & port_all==keys(i,2) & chan_all==keys(i,3) & cluster_idx==k;
            vals(i) = mean(fwhm_all(mask)); % one value per channel
        end
        group_fwhm{k} = vals;
    end
    plot_box_per_cluster(ax3, group_fwhm, colors, 'FWHM (ms)');
    h.cluster_axes = [h.cluster_axes ax3];

    %  PTP per cluster (per channel per exp/port) 
    ax4 = nexttile(t);
    group_ptp = cell(1,nClusters);
    for k = 1:nClusters
        idx_k = find(cluster_idx==k);
        keys = unique([exp_all(idx_k), port_all(idx_k), chan_all(idx_k)], 'rows');
        vals = nan(size(keys,1),1);
        for i = 1:size(keys,1)
            mask = exp_all==keys(i,1) & port_all==keys(i,2) & chan_all==keys(i,3) & cluster_idx==k;
            vals(i) = mean(ptp_all(mask));
        end
        group_ptp{k} = vals;
    end
    plot_box_per_cluster(ax4, group_ptp, colors, 'Peak-to-Peak Amplitude');
    h.cluster_axes = [h.cluster_axes ax4];
    end

    function plot_box_per_cluster(ax, group_data, colors, ylab)
    hold(ax,'on');
    maxLen = max(cellfun(@numel, group_data));
    nClusters = numel(group_data);
    data_mat = nan(maxLen,nClusters);
    for k = 1:nClusters
        data_mat(1:numel(group_data{k}),k) = group_data{k};
    end

    boxplot(ax, data_mat, 'Symbol','o','MedianStyle','line');
    % Recolor manually
    box_handles = findobj(ax,'Tag','Box');
    for i = 1:length(box_handles)
        patch(ax, get(box_handles(i),'XData'), get(box_handles(i),'YData'), colors(length(box_handles)-i+1,:), ...
              'FaceAlpha',0.6,'EdgeColor','k','LineWidth',1);
    end

    ylabel(ax,ylab); xlabel(ax,'Cluster'); title(ax,ylab); box(ax,'off');
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    hold(ax,'off');
end
