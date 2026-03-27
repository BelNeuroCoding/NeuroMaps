function plot_all_clusters(h)
    h = guidata(h.figure);
    backgdcolor = [1, 1, 1];
    accentcolor = [0.1, 0.4, 0.6];

    if ~isfield(h.cumulative_spikes,'cluster_idx')
        warndlg('No cluster indices found. Nothing to plot.');
        return;
    end

    %  Load cluster plotting config 
    if exist('clust_config.mat','file')
        load('clust_config.mat');
    else
        cfg.ylim_1_mode = 'auto';
        cfg.ylim_2_mode = 'auto';
        cfg.ylim_3_mode = 'auto';        
        cfg.ylim_4_mode = 'auto';

        cfg.xlim_1_mode = 'auto';
        cfg.xlim_2_mode = 'auto';
        cfg.xlim_3_mode = 'auto';        
        cfg.xlim_4_mode = 'auto';
        cfg.pre_time  = 0.8; cfg.post_time = 0.8;
    end

    unique_clusters = unique(h.cumulative_spikes.cluster_idx);
    nClusters = length(unique_clusters);
    cluster_idx = h.cumulative_spikes.cluster_idx;
    cluster_labels = arrayfun(@(k) sprintf('Cluster %d', k), unique_clusters,'UniformOutput',false);

    % Delete existing axes
    existingAxes = findall(h.clustplot_panel,'Type','axes'); delete(existingAxes);
    if isfield(h,'cluster_axes') && ~isempty(h.cluster_axes)
        delete(h.cluster_axes(ishandle(h.cluster_axes)));
    end

    h.cluster_axes = gobjects(0);
    t = tiledlayout(h.clustplot_panel, 2, 2, 'TileSpacing','compact','Padding','compact');

    selectedIdx = get(h.cluster_listbox,'Value');
    selectedStrings = get(h.cluster_listbox,'String');
    selected_clusters = unique_clusters(selectedIdx);
    sel_mask = ismember(cluster_idx, selected_clusters);
    cluster_idx_sel = cluster_idx(sel_mask);

    %% PCA scatter (ax1)
    ax1 = nexttile(t); hold(ax1,'on');
    wf = h.cumulative_spikes.all_waveforms(sel_mask,:);
    fwhm_all = h.cumulative_spikes.fwhm(sel_mask);
    ptp_all = h.cumulative_spikes.ptp_amplitude(sel_mask);
    exp_all = h.cumulative_spikes.spike_origin_e(sel_mask);
    port_all = h.cumulative_spikes.spike_origin_p(sel_mask);
    chan_all = h.cumulative_spikes.channels(sel_mask);
    score = h.cumulative_spikes.score(sel_mask,:);

    if h.exp_pca_toggle.Value == 1
        expPort = [exp_all(:), port_all(:)];
        [~, ~, expPortGroups] = unique(expPort, 'rows');
        nGroups = max(expPortGroups);
        colors = lines(nGroups);
        for g = 1:nGroups
            scatter(ax1, score(expPortGroups==g,1), score(expPortGroups==g,2), ...
                    20, colors(g,:), 'filled', 'MarkerFaceAlpha',0.6, 'MarkerEdgeAlpha',0.6);
        end
        xlabel(ax1,'PC1'); ylabel(ax1,'PC2'); title(ax1,'PCA by Exp/Port');
        legend(ax1, arrayfun(@(g) sprintf('Exp %d Port %d', ...
                 exp_all(find(expPortGroups==g,1)), port_all(find(expPortGroups==g,1))), ...
                 1:nGroups,'UniformOutput',false), 'Location','northeastoutside');
    else
        colors = lines(nClusters);
        for k = 1:numel(selected_clusters)
            c = selected_clusters(k);
            scatter(ax1, score(cluster_idx_sel==c,1), score(cluster_idx_sel==c,2), ...
                    20, colors(c,:), 'filled', 'MarkerFaceAlpha',0.6, 'MarkerEdgeAlpha',0.6);
        end
        xlabel(ax1,'PC1'); ylabel(ax1,'PC2'); title(ax1,'PCA by Cluster');
        legend(ax1, arrayfun(@(k) sprintf('Cluster %d', k), 1:numel(selected_clusters),'UniformOutput',false), ...
               'Location','northeastoutside');
    end
    grid(ax1,'on'); axis(ax1,'tight'); hold(ax1,'off');
    if strcmp(cfg.ylim_1_mode,'manual') && ~isempty(cfg.ylim_1_mode)
        ylim(ax1,cfg.ylim_1);
    end
    if strcmp(cfg.xlim_1_mode,'manual') && ~isempty(cfg.xlim_1_mode)
        xlim(ax1,cfg.xlim_1);
    end
    h.cluster_axes = [h.cluster_axes ax1];

    %% Clustered waveforms (ax2)
    ax2 = nexttile(t); hold(ax2,'on');
    xaxis = linspace(-cfg.pre_time,cfg.post_time,size(wf,2));
    colors = lines(nClusters);
    for k = 1:numel(selected_clusters)
        idx_k = cluster_idx_sel == selected_clusters(k);
        mean_wf = mean(wf(idx_k,:),1);
        std_wf  = std(wf(idx_k,:),1);
        lineHandles(k) =plot(ax2, xaxis, mean_wf, 'Color', colors(k,:), 'LineWidth', 2);
        legend(ax2, arrayfun(@(k) sprintf('Cluster %d', k), 1:numel(selected_clusters),'UniformOutput',false), ...
        'Location','northeastoutside');
        fill(ax2, [xaxis fliplr(xaxis)], [mean_wf+std_wf fliplr(mean_wf-std_wf)], ...
         colors(k,:), 'FaceAlpha', 0.3, 'EdgeColor','none');        
    end
    legend(ax2,lineHandles, arrayfun(@(k) sprintf('Cluster %d', selected_clusters(k)), 1:numel(selected_clusters),'UniformOutput',false),'Location','northeastoutside');
    title(ax2,'Clustered Waveforms'); xlabel(ax2,'Normalized Time'); ylabel(ax2,'Amplitude');
    h.cluster_axes = [h.cluster_axes ax2];
    if strcmp(cfg.ylim_2_mode,'manual') && ~isempty(cfg.ylim_2_mode)
        ylim(ax2,cfg.ylim_2);
    end
    if strcmp(cfg.xlim_2_mode,'manual') && ~isempty(cfg.xlim_2_mode)
        xlim(ax2,cfg.xlim_2);
    end
    %% FWHM per cluster (ax3)
    ax3 = nexttile(t); hold(ax3,'on');
    group_fwhm = cell(1,numel(selected_clusters));
    for k = 1:numel(selected_clusters)
        idx_k = find(cluster_idx_sel==selected_clusters(k));
        keys = unique([exp_all(idx_k), port_all(idx_k), chan_all(idx_k)], 'rows');
        vals = nan(size(keys,1),1);
        for i = 1:size(keys,1)
            mask = exp_all==keys(i,1) & port_all==keys(i,2) & chan_all==keys(i,3) & cluster_idx_sel==selected_clusters(k);
            vals(i) = mean(fwhm_all(mask));
        end
        group_fwhm{selected_clusters(k)} = vals;
    end
    if strcmp(cfg.ylim_3_mode,'manual') && ~isempty(cfg.ylim_3_mode)
        ax_cfg.ylim = cfg.ylim_3;
    else
        ax_cfg.ylim = [];
    end

    ax_cfg.ylim_mode = cfg.ylim_3_mode;
    plot_box_per_cluster(ax3, group_fwhm, colors, 'FWHM (ms)', ax_cfg);
    h.cluster_axes = [h.cluster_axes ax3];
    %% PTP per cluster (ax4)
    ax4 = nexttile(t); hold(ax4,'on');
    group_ptp = cell(1,numel(selected_clusters));
    for k = 1:numel(selected_clusters)
        idx_k = find(cluster_idx_sel==selected_clusters(k));
        keys = unique([exp_all(idx_k), port_all(idx_k), chan_all(idx_k)], 'rows');
        vals = nan(size(keys,1),1);
        for i = 1:size(keys,1)
            mask = exp_all==keys(i,1) & port_all==keys(i,2) & chan_all==keys(i,3) & cluster_idx_sel==selected_clusters(k);
            vals(i) = mean(ptp_all(mask));
        end
        group_ptp{selected_clusters(k)} = vals;
    end

    if strcmp(cfg.ylim_4_mode,'manual') && ~isempty(cfg.ylim_4_mode)
        ax_cfg.ylim = cfg.ylim_4;
    else
        ax_cfg.ylim = [];
    end
    ax_cfg.ylim_mode = cfg.ylim_4_mode;
    plot_box_per_cluster(ax4, group_ptp, colors, 'Peak-to-Peak Amplitude', ax_cfg);
    h.cluster_axes = [h.cluster_axes ax4];
    guidata(h.figure,h);

    %% Nested boxplot function
    function plot_box_per_cluster(ax, group_data, colors, ylab, ax_cfg)
        hold(ax,'on');
        valid_ids = find(cellfun(@(x) ~isempty(x) && any(~isnan(x)), group_data));
        group_data = group_data(valid_ids);
        maxLen = max(cellfun(@numel, group_data));
        nClusters = numel(group_data);
        data_mat = nan(maxLen,nClusters);
        for k = 1:nClusters
            data_mat(1:numel(group_data{k}),k) = group_data{k};
        end

        boxplot(ax,data_mat, 'Symbol','o','MedianStyle','line');

        box_handles = findobj(ax,'Tag','Box');
        for i = 1:length(box_handles)
            patch(ax, get(box_handles(i),'XData'), get(box_handles(i),'YData'), colors(length(box_handles)-i+1,:), ...
                  'FaceAlpha', 0.6, 'EdgeColor','k', 'LineWidth', 1);
        end
        ylabel(ax,ylab); xlabel(ax,'Cluster'); title(ax,ylab); box(ax,'off');
        set(ax, 'XTick', 1:nClusters, 'XTickLabel', valid_ids);
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
        if strcmp(ax_cfg.ylim_mode,'manual') && isfield(ax_cfg,'ylim') && ~isempty(ax_cfg.ylim)
            ylim(ax, ax_cfg.ylim);
        end
        hold(ax,'off');
    end
end