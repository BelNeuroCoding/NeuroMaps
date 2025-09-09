function update_power_spectrum_tab(h)
h = guidata(h.figure);

% Get selection
idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

exclude_impedance_chans_toggle = get(h.excl_imp_toggle,'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
selectedStr = get(h.formatToggleGroup,'SelectedObject').String;
lab = extract_lab(selectedStr);

legendStrings = {};

% Global mode or multiple ports
if h.pspec_toggle.Value || (size(selected,1) > 1 && h.pspec_toggle.Value)
    axes(h.psAxes); hold(h.psAxes,'on');

    colors = lines(size(selected,1));
    for selIdx = 1:size(selected,1)
        expIdx = selected(selIdx,1);
        port_idx = selected(selIdx,2);

        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end

        % Mask channels
        channels = results.channels(port_idx).id;
        mask = true(1,numel(channels));
        if exclude_impedance_chans_toggle
            mask = mask & ~results.channels(port_idx).bad_impedance;
        end
        if exclude_noisy_chans_toggle
            noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
            mask = mask & ~noisy;
        end
        channels = channels(mask);

        signals = results.signals(port_idx).(lab)(mask,:);
        fs = results.fs;
        winLen  = round(fs*2);
        stepLen = round(fs/2);
        f_axis = 0:0.5:fs/2;
        goodMask = any(signals,2);
        PSDm = mPSD(signals(goodMask,:), round(fs), winLen, stepLen, stepLen);
        if isfield(h,'psLines') || isvalid(h.psLines)
            set(h.psLines, 'XData', nan, 'YData', nan);
        end
        if isfield(h,'psLinesWelch') || isvalid(h.psLinesWelch)
        set(h.psLinesWelch, 'XData', nan, 'YData', nan);  
        end
        % Update pre-created line or create temp line if needed
        if selIdx <= numel(h.psLines)
            set(h.psLines(selIdx), 'XData', f_axis, 'YData', mean(PSDm,2)', 'Color', colors(selIdx,:), 'LineWidth',1.5);
        else
            loglog(h.psAxes, f_axis, mean(PSDm,2)', 'Color', colors(selIdx,:), 'LineWidth',1.5);
        end
        

        legendStrings{end+1} = sprintf('Exp %d Port %d %s', expIdx, results.ports(port_idx).port_id, [upper(lab(1)) lower(lab(2:end))]);
    end
    xlim(h.psAxes,[1 round(fs)/2])
    title('');
else
    % Single-channel mode
    expIdx = selected(1,1);
    port_idx = selected(1,2);

    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    % Mask channels
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if exclude_impedance_chans_toggle
        mask = mask & ~results.channels(port_idx).bad_impedance;
    end
    if exclude_noisy_chans_toggle
        noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
        mask = mask & ~noisy;
    end
    channels = channels(mask);

    signals = results.signals(port_idx).(lab)(mask,:);
    SeriesNumber = round(get(h.series_slider,'Value'));
    sig = signals(SeriesNumber,:)';

    fs = results.fs;
    winLen = round(fs*2);
    stepLen = round(fs/2);
    f_axis = 0:0.5:fs/2;
    if ~isfield(h,'psdCache') || ...
       h.psdCache.expIdx ~= expIdx || ...
       h.psdCache.port_idx ~= port_idx || ...
       h.psdCache.SeriesNumber ~= SeriesNumber || ...
       ~strcmp(h.psdCache.lab, lab)
    
        % compute PSD
        PSDm = mPSD(sig', round(fs), winLen, stepLen, stepLen);
        PSDw = pwelch(sig, winLen, round(fs), winLen, round(fs));
    
        % store in cache
        h.psdCache.expIdx = expIdx;
        h.psdCache.port_idx = port_idx;
        h.psdCache.SeriesNumber = SeriesNumber;
        h.psdCache.lab = lab;
        h.psdCache.PSDm = PSDm;
        h.psdCache.PSDw = PSDw;
    end
    
    % use cached PSDs for plotting
    PSDm = h.psdCache.PSDm;
    PSDw = h.psdCache.PSDw;

    if isfield(h,'psLines') || isvalid(h.psLines)
        set(h.psLines, 'XData', nan, 'YData', nan);
    end
    if isfield(h,'psLinesWelch') || isvalid(h.psLinesWelch)
        set(h.psLinesWelch, 'XData', nan, 'YData', nan);  
    end
    % Update pre-created lines
    set(h.psLines(1), 'XData', f_axis, 'YData', PSDm, 'Color','b', 'LineWidth',1.5);
    set(h.psLinesWelch, 'XData', f_axis, 'YData', PSDw);
    xlim(h.psAxes,[1 fs/2])
    legendStrings = {'Median PSD','Welch PSD'};
    title(h.psAxes,sprintf('Port %d Ch %d %s', results.ports(port_idx).port_id,channels(SeriesNumber),[upper(lab(1)) lower(lab(2:end))]));
end

% Axis formatting
set(h.psAxes,'XScale','log','YScale','log');
xlabel(h.psAxes,'Frequency (Hz)'); ylabel(h.psAxes,'Power Spectral Density (a.u.)');
legend(h.psAxes, legendStrings,'Location','northeast');
grid(h.psAxes,'on');
axtoolbar(h.psAxes,{'save','zoomin','zoomout','restoreview','pan'});

drawnow limitrate;
guidata(h.figure,h);
end
