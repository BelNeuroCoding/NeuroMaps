function plain_raster_plot(data_to_raster,TimeStamps)

channels = [data_to_raster.channel];
unique_channels = unique(channels);

hold all;
for i = 1:length(unique_channels)    
    plot_idx = find(channels == unique_channels(i));
    spike_times = [data_to_raster(plot_idx).time_stamp];
    plot(spike_times+min(TimeStamps),channels(plot_idx),'|','Color','k','LineWidth',1);

    hold on;
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
