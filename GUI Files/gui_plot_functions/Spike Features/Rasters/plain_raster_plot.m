function plain_raster_plot(data_to_raster, TimeStamps)

channels = [data_to_raster.channel];
unique_channels = unique(channels);
nCh = length(unique_channels);

hold on;

spacing = 1.5;
y_positions = (1:nCh) * spacing;  % actual y-values for each channel

for i = 1:nCh
    plot_idx = find(channels == unique_channels(i));
    spike_times = [data_to_raster(plot_idx).time_stamp];
    scatter(spike_times + min(TimeStamps), ...
            y_positions(i) * ones(size(spike_times)), ...
            10, 'k', '|', 'LineWidth', 1);
end

% Set ticks at the same spaced positions
max_ticks = 7;
tick_idx = round(linspace(1, nCh, min(max_ticks, nCh)));
yticks(y_positions(tick_idx));
yticklabels(string(unique_channels(tick_idx)));


ylabel('Channel');
xlabel('Time (s)');
xlim([min(TimeStamps) max(TimeStamps)]);
set(gca, 'Color', 'none');  % transparent background
hold off;

end
