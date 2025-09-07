function amplitude_raster_plot(data_to_raster,TimeStamps)

channels = [data_to_raster.channel];
unique_channels = unique(channels);
ptp_amplitudes = [data_to_raster.ptp_amplitude];
amp_lims = [0 ceil(max(ptp_amplitudes))];

cmap = colormap('jet');
scaled_amp = min(max(ptp_amplitudes, 0), amp_lims(2));
color_idx = round(scaled_amp / amp_lims(2) * (size(cmap, 1) - 1)) + 1;
spike_colors = cmap(color_idx, :);

hold all;
for i = 1:length(unique_channels)    
    plot_idx = find(channels == unique_channels(i));
    spike_times = [data_to_raster(plot_idx).time_stamp];
    scatter(spike_times+min(TimeStamps), channels(plot_idx), 30, spike_colors(plot_idx,:), '|','LineWidth',1.5); 

    hold on;
end

yticks(unique_channels);          % put ticks exactly at channel numbers
yticklabels(string(unique_channels)); % show the channel numbers
ylabel('Channel');
xlabel('Time (s)');
xlim([min(TimeStamps) max(TimeStamps)]); % Set x-axis limits based on time

% Add colorbar for amplitude
c = colorbar('southoutside');
caxis(amp_lims);
ylabel(c, 'Peak-to-Peak Amplitude (\muV)');  % label colorbar


% Final figure settings
hold off;
set(gca, 'Color', 'none');  % Make the background transparent



end
