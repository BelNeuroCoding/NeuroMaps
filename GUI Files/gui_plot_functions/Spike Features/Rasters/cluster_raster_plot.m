function cluster_raster_plot(data_to_raster,TimeStamps,ax)

clusters = [data_to_raster.clusters];
unique_clusters = unique([data_to_raster.clusters]);
nclust = length(unique_clusters);
colors = lines(length(unique_clusters));
all_unique_channels = unique([data_to_raster.channel]); % Across All Clusters
nallchs = length(all_unique_channels); % Across All Clusters
spacing = 1.5;
y_positions = (1:nallchs) * spacing; 
hold all;
for i = 1:nclust  
     plot_idx = find(clusters == unique_clusters(i));
     cluster_channels = [data_to_raster(plot_idx).channel]; % Channels belonging to cluster i
     unique_cluster_channels = unique(cluster_channels);
     n_cluster_Ch = length(unique_cluster_channels);
     cluster_data = data_to_raster(plot_idx); % Spike Timestamps belonging to cluster i 
    % spike_times = [data_to_raster(plot_idx).time_stamp];
    % spike_channels = [data_to_raster(plot_idx).channel];
    % yval = i * spacing;
    % cluster_handles(i) = scatter(spike_times+min(TimeStamps),  yval * ones(size(spike_times)),10, colors(i,:), '|', 'LineWidth', 1);
    for j = 1:n_cluster_Ch % Loop across unique cluster channels
        ch_plot_idx = find(cluster_channels == unique_cluster_channels(j));
        ypos_counter = find(all_unique_channels == unique_cluster_channels(j)); % Find ypos
        scatter([cluster_data(ch_plot_idx).time_stamp] + min(TimeStamps), ...
                y_positions(ypos_counter) * ones(size([cluster_data(ch_plot_idx).time_stamp])), ...
                10, colors(i,:), '|', 'LineWidth', 1);
    end
    hold on;
end
% Set ticks at the same spaced positions
max_ticks = 7;
tick_idx = round(linspace(1, length(all_unique_channels), min(max_ticks, length(all_unique_channels))));
yticks(y_positions(tick_idx));
yticklabels(string(all_unique_channels(tick_idx)));


ylabel('Channel');
xlabel('Time (s)');
xlim([min(TimeStamps) max(TimeStamps)]);
set(gca, 'Color', 'none');  % transparent background
hold off;
% 
% yticks((1:nclust) * spacing);
% yticklabels(string(unique_clusters));
% ylabel('Cluster');
% xlabel('Time (s)');
% ylim([0 length(unique_clusters)*1.5])
% 
% xlim([min(TimeStamps) max(TimeStamps)]); % Set x-axis limits based on time

colormap(ax,colors);  % colors = lines(length(unique_clusters))
cm = colorbar('southoutside');
cm.Ticks = linspace(0,1,length(unique_clusters));
cm.TickLabels = arrayfun(@(c) sprintf('Cluster %d', c), unique_clusters, 'UniformOutput', false);
cm.Label.String = 'Cluster';

% Final figure settings
hold on;
set(gca, 'Color', 'none');  % Make the background transparent



end
