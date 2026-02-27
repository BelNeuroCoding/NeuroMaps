function plot_box_per_group(ax, group_data, colors, ylab)
    hold(ax,'on');
    nClusters = numel(group_data);
    maxLen = max(cellfun(@numel, group_data));
    data_mat = nan(maxLen, nClusters);
    for k = 1:nClusters
        data_mat(1:numel(group_data{k}), k) = group_data{k};
    end

    if size(data_mat,1) < 2
        means = cellfun(@mean, group_data);
        b = bar(ax, 1:numel(group_data), means, 'FaceColor','flat','EdgeColor','k','LineWidth',1.5);
        for k = 1:numel(group_data), b.CData(k,:)=colors(k,:); end
        b.FaceAlpha = 0.6;
    else
        boxplot(ax,data_mat,'Colors',colors(1,:),'Symbol','o','MedianStyle','line');
        box_handles = findobj(ax,'Tag','Box'); reversed_colors = flipud(colors);
        for i = 1:length(box_handles)
            patch(get(box_handles(i),'XData'), get(box_handles(i),'YData'), reversed_colors(i,:), 'FaceAlpha',0.6,'EdgeColor','k','LineWidth',1,'Parent',ax);
        end
    end

    for k = 1:nClusters
        valid_points = ~isnan(data_mat(:,k));
        x = k * ones(1,sum(valid_points));
        scatter(ax,x,data_mat(valid_points,k),10,'k','filled','MarkerFaceAlpha',0.5);
    end
    ylabel(ax,ylab); box(ax,'off'); hold(ax,'off');
end