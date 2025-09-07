function bursts_raster_plot(analysis_set,TimeStamps,ax)
channels = [analysis_set.channel];
unique_channels = unique(channels);

hold all;

% Overlay bursts in red
for i = 1:length(unique_channels)
    plot_idx = find(channels == unique_channels(i));
    spike_times = [analysis_set(plot_idx).timestamps]+min(TimeStamps);
    plot(spike_times,channels(plot_idx),'|','Color','k','LineWidth',1);
    hold on;
    if ~isempty(analysis_set(plot_idx).bursts)
        burst_starts = [analysis_set(plot_idx).bursts.start]+min(TimeStamps);
        burst_ends = [analysis_set(plot_idx).bursts.end]+min(TimeStamps);

        for b = 1:length(burst_starts)
            in_burst = spike_times >= burst_starts(b) & spike_times <= burst_ends(b);
            if any(in_burst)
                plot(ax, spike_times(in_burst), ...
                     repmat(unique_channels(i), 1, sum(in_burst)), '|', ...
                     'Color', 'r', 'LineWidth', 1.5);
            end
     

        end
    end
end

yticks(unique_channels);          % put ticks exactly at channel numbers
yticklabels(string(unique_channels)); % show the channel numbers
ylabel('Channel');
xlabel('Time (s)');

xlim([min(TimeStamps) max(TimeStamps)]); % Set x-axis limits based on time


% Final figure settings
hold off;
set(gca, 'Color', 'none');  % Make the background transparent


end