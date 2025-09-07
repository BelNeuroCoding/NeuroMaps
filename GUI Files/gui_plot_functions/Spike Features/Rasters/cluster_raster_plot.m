function cluster_raster_plot(data_to_raster,TimeStamps,ax)

clusters = [data_to_raster.clusters];
unique_clusters = unique([data_to_raster.clusters]);
colors = lines(length(unique_clusters));
unique_channels = unique([data_to_raster.channel]);
hold all;
for i = 1:length(unique_clusters)    
    plot_idx = find(clusters == unique_clusters(i));
    spike_times = [data_to_raster(plot_idx).time_stamp];
    spike_channels = [data_to_raster(plot_idx).channel];
    cluster_handles(i) = plot(spike_times+min(TimeStamps), spike_channels, '|', 'Color', colors(i,:), 'LineWidth', 1);

    hold on;
end

yticks(unique_channels);          % put ticks exactly at channel numbers
yticklabels(string(unique_channels)); % show the channel numbers
ylabel('Channel');
xlabel('Time (s)');

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
