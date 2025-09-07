function plot_spikes_callback(h)
h = guidata(h.figure);

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

%  Delete old axes once 
if isfield(h,'spikes_axes') && ~isempty(h.spikes_axes)
    delete(h.spikes_axes(ishandle(h.spikes_axes)));
end
h.spikes_axes = gobjects(0);

% Retrieve the results from the h structure
if exist('spike_config.mat','file')
    cfg = load('spike_config.mat');
    cfg = cfg.config;  % unpack struct
    pre_time = cfg.pre_time; post_time =cfg.pre_time;
else
    % fallback defaults
    pre_time = 0.8;
    post_time = 0.8;
end

% Loop over all selected ports
for p = 1:size(selected,1)
    expIdx = selected(p,1);
    selected_idx = selected(p,2);
    % Load experiment results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    selectedport = results.ports(selected_idx).port_id;
    if numel(results.spike_results)<selected_idx
        warndlg(['Spikes were not detected in port: ' num2str(selectedport)]);
        continue;
    end
    waveforms_all = results.spike_results(selected_idx).waveforms_all;
    all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
    indices_to_flip = find(abs(min(all_waveforms,[],2))<(abs(max(all_waveforms,[],2))));
    all_waveforms(indices_to_flip,:) = -all_waveforms(indices_to_flip,:);
    N_samples = size(all_waveforms, 2);
    ts = linspace(-pre_time, post_time, N_samples);
    channels = cell2mat(arrayfun(@(x) x.channel, waveforms_all, 'UniformOutput', false)');
    fs = results.fs;    

    unique_chans = unique(channels);
    nChans = numel(unique_chans);
    nRows = ceil(sqrt(nChans));
    nCols = ceil(nChans / nRows);
    for i = 1:nChans
        indices = find(ismember(channels,unique_chans(i)));
        if ~isempty(indices)
        ch = unique_chans(i);
        mean_waveform = mean(all_waveforms(indices,:),1);
        std_waveform = std(all_waveforms(indices,:),1);
        ax_idx = (p-1)*nChans + i; % global axes index
        h.spikes_axes(ax_idx) = subplot(nRows, nCols, i, 'Parent', h.spikes_tab);
        plot(ts,mean_waveform, 'k', 'LineWidth', 2)
        hold(h.spikes_axes(ax_idx),'on');
        fill([ts fliplr(ts)], ...
                     [mean_waveform + std_waveform fliplr(mean_waveform - std_waveform)], ...
                     'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none'); % Blue for std area
        hold(h.spikes_axes(ax_idx),'off');
        %ylim([-100 100])
        title(['Ch: ' num2str(ch)])
        box off
        axtoolbar({'datacursor','save','zoomin','zoomout','restoreview','pan'});
        sgtitle(['Port: ' num2str(selectedport)])
        end
    end
end


end
