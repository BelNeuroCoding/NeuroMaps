function plot_power_spectrum(h)
h = guidata(h.figure);
%% Get selected port
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);
exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
selectedStr = get(h.formatToggleGroup, 'SelectedObject').String;
lab = extract_lab(selectedStr);

if ~isfield(h,'ps_panel') || ~isvalid(h.ps_panel)
    h.ps_panel = uipanel(h.pspec_tab,'Position',[0.05 0.08 0.9 0.9],'Title','Power Spectrum');
end
axesToDelete = findobj(h.ps_panel, 'Type', 'axes');
delete(axesToDelete); % clear old axes
h.ps_axes = axes('Parent', h.ps_panel); % new axes
hold(h.ps_axes,'on');

% Only allow one experiment & port
if size(selected,1) > 1 || h.pspec_toggle.Value
    axes(h.ps_axes)
    all_psdsm = {};
    all_freqs = {};
    port_labels ={};
    colors = lines(size(selected,1));
    for selIdx = 1:size(selected,1)
        expIdx = selected(selIdx,1);
        port_idx = selected(selIdx,2);
        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end
        bad_impedance = results.channels(port_idx).bad_impedance;
        noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
        channels = results.channels(port_idx).id;
        mask = true(1,numel(channels));
        if exclude_impedance_chans_toggle
            mask = mask & ~bad_impedance;
        end
        if exclude_noisy_chans_toggle
            mask =mask & ~noisy;
        end
        channels = channels(mask);

        signals = results.signals(port_idx).(lab)(mask,:);
        fs = results.fs;
        winLen  = round(fs*2);
        stepLen = round(fs/2);
        f_axis = 0:0.5:fs/2;
        goodMask = any(signals,2);
        medianPSD = medianWelch(signals(goodMask,:),round(fs), winLen,stepLen, stepLen);            
        loglog(h.ps_axes,f_axis, mean(medianPSD,2)', 'Color',colors(selIdx,:), 'LineWidth', 1.5);  % Median PSD
        port_labels{end+1} = sprintf('Exp %d Port %d %s',expIdx,results.ports(port_idx).port_id,lab);
        hold on;

    end     
    % Labels & formatting
    xlabel('Frequency (Hz)');
    ylabel('Power Spectral Density (a.u.)');
    title(['Median PSD']);
    legend(h.ps_axes,port_labels, 'Location','northeast');
    
    % Axis tweaks
    xlim([1 fs/2]);      % start from 1 Hz
    grid on;
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    
else
    expIdx = selected(1,1);
    port_idx = selected(1,2);      

    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    bad_impedance = results.channels(port_idx).bad_impedance;
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if exclude_impedance_chans_toggle
        mask = mask & ~bad_impedance;
    end
    if exclude_noisy_chans_toggle
        mask =mask & ~noisy;
    end
    channels = channels(mask);    
    signals = results.signals(port_idx).(lab)(mask,:);
    fs = results.fs;
    % Get Slider Position
    SeriesNumber = round(get(h.series_slider, 'Value')); % First figure, port number
    current_ch = channels(SeriesNumber); % Finds the corresponding channel name
    prange = 1:length(signals(SeriesNumber, :)); % Range of Indices
    [T,N] = size(signals);
    sig = signals(SeriesNumber, :)';
    nSamples = numel(sig);
    winLen  = round(fs*2);
    stepLen = round(fs/2);
    
    if nSamples < winLen
        errordlg(sprintf(['Selected time range is too short for spectrogram.\n' ...
                          'Need at least %.2f seconds (%d samples), but got only %d samples.'], ...
                          winLen/fs, winLen, nSamples), ...
                 'Insufficient Data');
        return;
    end

    % Plot PSDs

    f_axis = 0:0.5:fs/2;
    medianPSD = medianWelch(signals(SeriesNumber, prange),round(fs), winLen,stepLen, stepLen);
    PSDw = pwelch(signals(SeriesNumber, prange),winLen,round(fs),winLen,round(fs));

    loglog(h.ps_axes,f_axis, medianPSD, 'b-', 'LineWidth', 1.5);  % Median PSD
    hold on;
    loglog(h.ps_axes,f_axis, PSDw, 'r-.', 'LineWidth', 1.5); % Welch PSD
    hold off;
    
    % Labels & formatting
    xlabel('Frequency (Hz)');
    ylabel('Power Spectral Density (a.u.)');
    title(['Port: ' num2str(results.ports(port_idx).port_id) ' Ch: ' num2str(current_ch) lab ' Median vs Welch PSD']);
    legend({'Median PSD','Welch PSD'}, 'Location','northeast');
    
    % Axis tweaks
    xlim([1 fs/2]);      % start from 1 Hz
    grid on;
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
end


end