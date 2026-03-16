function network_pop_plot(waveforms_all,TimeStamps,fs,recording_time,bin_rate,ax)

unique_channels = unique([waveforms_all.channel]);

if isempty(bin_rate) | nargin<5
    bin_rate = 1000; % fallback default if user cancels
else
    if isnan(bin_rate) || bin_rate <= 0
        bin_rate = 1000; % fallback if invalid input
    end
end
len = ceil((recording_time) * bin_rate); % Length of the spike matrix
numchan = length(unique_channels);
if numchan>0
bin_sp = zeros(numchan, len); % Initialize binned spike matrix

% Plot spikes for each channel
for chan = 1:numchan
    current_channel = unique_channels(chan);
    indices_chan = find([waveforms_all.channel] == current_channel);
    spikes = [waveforms_all(indices_chan).time_stamp];
    % Binning spikes for each channel
    if any(spikes)
        bin_sp(chan,:) = bin_spikes(spikes * fs, [fs, len / bin_rate], bin_rate);
    end
    
end
hold on
%Binarize spikes
bsp = squeeze(bin_sp);
t_ds = (TimeStamps(1):(1/bin_rate): ceil(TimeStamps(end)))';
% Count spikes per channel
nws = squeeze(sum(bsp, 1));
t_ds = t_ds(1:length(nws));
nws_smo = conv(nws, gausswin(100), 'same');
plot(t_ds, nws_smo, 'LineWidth', 1,'Color',[0.5, 0, 0],'HandleVisibility','off'); % Dark gray color
ylabel('Population Spike Count');
xlabel('Time (s)');
box off;
xlim([min(TimeStamps) max(TimeStamps)]); % Set x-axis limits based on time
ax.YColor = [0 0 0];  % Right y-axis color
ylabel('Population Spike Count','Color',[0 0 0]);
axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

end
end