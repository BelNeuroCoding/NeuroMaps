function cluster_raster_plot(data_to_raster,TimeStamps,ax)

clusters = [data_to_raster.clusters];
unique_clusters = unique([data_to_raster.clusters]);
colors = lines(length(unique_clusters));
nclust = length(unique_clusters);
spacing = 1;
hold all;
for i = 1:length(unique_clusters)    
    plot_idx = find(clusters == unique_clusters(i));
    spike_times = [data_to_raster(plot_idx).time_stamp];
    spike_channels = [data_to_raster(plot_idx).channel];
    yval = i * spacing;
    cluster_handles(i) = scatter(spike_times+min(TimeStamps),  yval * ones(size(spike_times)),10, colors(i,:), '|', 'LineWidth', 1);
    hold on;
end


yticks((1:nclust) * spacing);
yticklabels(string(unique_clusters));
ylabel('Cluster');
xlabel('Time (s)');
ylim([0 length(unique_clusters)*1.5])

xlim([min(TimeStamps) max(TimeStamps)]); % Set x-axis limits based on time

colormap(ax,colors);  % colors = lines(length(unique_clusters))
cm = colorbar('southoutside');
cm.Ticks = linspace(0,1,length(unique_clusters));
cm.TickLabels = arrayfun(@(c) sprintf('Cluster %d', c), unique_clusters, 'UniformOutput', false);
cm.Label.String = 'Cluster';

% Final figure settings
hold on;
set(gca, 'Color', 'none');  % Make the background transparent



end
