function bursts_raster_plot(analysis_set, TimeStamps, ax)

channels = [analysis_set.channel];
unique_channels = unique(channels);
nCh = length(unique_channels);
spacing = 1.5;
y_positions = (1:nCh) * spacing;

hold(ax, 'on');

all_spike_times = [];
all_y = [];
all_colors = [];

for i = 1:nCh
    plot_idx = find(channels == unique_channels(i));
    yval = y_positions(i);

    % Collect all spikes for this channel
    spike_times = [analysis_set(plot_idx).timestamps] + min(TimeStamps);
    all_spike_times = [all_spike_times, spike_times];
    all_y = [all_y, repmat(yval, 1, numel(spike_times))];
    all_colors = [all_colors; repmat([0 0 0], numel(spike_times), 1)];

    % Collect burst spikes
    if ~isempty(analysis_set(plot_idx).bursts)
        burst_starts = [analysis_set(plot_idx).bursts.start] + min(TimeStamps);
        burst_ends   = [analysis_set(plot_idx).bursts.end]   + min(TimeStamps);

        for b = 1:numel(burst_starts)
            in_burst = spike_times >= burst_starts(b) & spike_times <= burst_ends(b);
            if any(in_burst)
                all_colors(sum(cellfun(@numel, {all_y})) - numel(spike_times) + find(in_burst), :) = repmat([1 0 0], sum(in_burst), 1);
            end
        end
    end
end

% Single scatter call for all spikes
scatter(ax, all_spike_times, all_y, 10, all_colors, '|', 'LineWidth', 1);

% Axes settings
yticks(y_positions);
yticklabels(string(unique_channels));
ylim([0 spacing*(nCh+0.5)]);
ylabel('Channel');
xlabel('Time (s)');
xlim([min(TimeStamps) max(TimeStamps)]);
set(ax, 'Color', 'none', 'TickDir', 'out');

hold(ax, 'off');

end
