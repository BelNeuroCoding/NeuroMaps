function amplitude_raster_plot_fast(data_to_raster, TimeStamps)

channels = [data_to_raster.channel];
unique_channels = unique(channels);
ptp_amplitudes = [data_to_raster.ptp_amplitude];

%  Amplitude limits and colormap 
amp_lims = [0 ceil(max(ptp_amplitudes))];
cmap = jet(256);

% Scale amplitudes to colormap indices
scaled_amp = min(max(ptp_amplitudes, 0), amp_lims(2));
color_idx = round(scaled_amp / amp_lims(2) * (size(cmap,1)-1)) + 1;
spike_colors = cmap(color_idx,:);

%  Map channels to vertical positions 
[~, ~, y_idx] = unique(channels);  % returns 1..nCh for each spike
y_positions = y_idx;               % evenly spaced rows

%  Single scatter call for all spikes 
hold on;
scatter([data_to_raster.time_stamp] + min(TimeStamps), y_positions, 10, spike_colors, '|', 'LineWidth', 1);

%  Axes and labels 
nCh = length(unique_channels);

% Pick a subset of channels for ticks, e.g., max 5 ticks
max_ticks = 7;
tick_idx = round(linspace(1, nCh, min(max_ticks,nCh)));  % pick evenly spaced indices
yticks(tick_idx);
yticklabels(string(unique_channels(tick_idx)));
ylabel('Channel');
xlabel('Time (s)');
ylim([0.5 nCh + 0.5]);
xlim([min(TimeStamps) max(TimeStamps)]);
set(gca, 'YDir', 'normal', 'TickDir', 'out', 'Color', 'none');

%  Colorbar 
c = colorbar('southoutside');
caxis(amp_lims);
ylabel(c, 'Peak-to-Peak Amplitude (\muV)');

hold off;

end
