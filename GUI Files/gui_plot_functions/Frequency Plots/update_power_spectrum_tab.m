function update_power_spectrum_tab(h)
h=guidata(h.figure);
% Get selection
set_status(h.figure,"loading","Computing Power Spectrum...");

if isfield(h,'pspec_props')
    p = h.pspec_props;
else
    p.fmin = 1;
    p.fmax = [];
    p.xscale = 'log';
    p.yscale = 'log';
    p.showWelch = true;
    p.linewidth = 1.5;
    p.winLen = 2;       %seconds
    p.stepLen = 0.5; %seconds
end

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
        win_samples  = round(fs*p.winLen);
        stepLen = round(fs*p.stepLen);
        Nfft = win_samples;
        f_axis = linspace(0, fs/2, floor(Nfft/2)+1); 
        goodMask = any(signals,2);
        PSDm = mPSD(signals(goodMask,:), round(fs), win_samples, stepLen, stepLen);
        set_status(h.figure,"loading","Plotting Power Spectrum...");
        if isfield(h,'psLines') && all(isvalid(h.psLines))
            set(h.psLines, 'XData', nan, 'YData', nan);
        end
        if isfield(h,'psLinesWelch') && all(isvalid(h.psLinesWelch))
        set(h.psLinesWelch, 'XData', nan, 'YData', nan);  
        end
        % Update pre-created line or create temp line if needed
        if selIdx <= numel(h.psLines)
            set(h.psLines(selIdx), 'XData', f_axis, 'YData', mean(PSDm,2)', 'Color', colors(selIdx,:), 'LineWidth',p.linewidth);
        else
            loglog(h.psAxes, f_axis, mean(PSDm,2)', 'Color', colors(selIdx,:), 'LineWidth',p.linewidth);
        end
        

        legendStrings{end+1} = sprintf('Exp %d Port %d %s', expIdx, results.ports(port_idx).port_id, [upper(lab(1)) lower(lab(2:end))]);
    end
    if isempty(p.fmax)
        p.fmax = fs/2;
    end
    
    xlim(h.psAxes,[p.fmin p.fmax])
   
    set(h.psAxes,'XScale',p.xscale,'YScale',p.yscale);
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
    win_samples = round(fs*p.winLen);
    stepLen = round(fs*p.stepLen);
    Nfft = win_samples;  % or as used in mPSD
    f_axis = linspace(0, fs/2, floor(Nfft/2)+1); 
    if ~isfield(h,'psdCache') || ...
       h.psdCache.expIdx ~= expIdx || ...
       h.psdCache.port_idx ~= port_idx || ...
       h.psdCache.SeriesNumber ~= SeriesNumber || ...
       ~strcmp(h.psdCache.lab, lab)
    
        % compute PSD
        PSDm = mPSD(sig', round(fs), win_samples, stepLen, stepLen);
        PSDw = pwelch(sig, win_samples, round(fs), win_samples, round(fs));
    
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
    set_status(h.figure,"loading","Plotting Power Spectrum...");

    if isfield(h,'psLines') && all(isvalid(h.psLines))
        set(h.psLines, 'XData', nan, 'YData', nan);
    end
    if isfield(h,'psLinesWelch')  && all(isvalid(h.psLinesWelch))
        set(h.psLinesWelch, 'XData', nan, 'YData', nan);  
    end

    if p.showWelch
        set(h.psLinesWelch, 'XData', f_axis, 'YData', PSDw);
    else
        set(h.psLinesWelch, 'XData', nan, 'YData', nan);
    end
    % Update pre-created lines
    set(h.psLines(1), 'XData', f_axis, 'YData', PSDm, 'Color','b', 'LineWidth',p.linewidth);
    if isempty(p.fmax)
        p.fmax = fs/2;
    end
    xlim(h.psAxes,[p.fmin p.fmax])
    legendStrings = {'Median PSD'};
    if p.showWelch
        legendStrings{end+1} = 'Welch PSD';
    end
    title(h.psAxes,sprintf('Port %d Ch %d %s', results.ports(port_idx).port_id,channels(SeriesNumber),[upper(lab(1)) lower(lab(2:end))]));
end

% Axis formatting
set(h.psAxes,'XScale',p.xscale,'YScale',p.yscale);
xlabel(h.psAxes,'Frequency (Hz)'); ylabel(h.psAxes,'Power Spectral Density (a.u.)');
legend(h.psAxes, legendStrings,'Location','northeast');
grid(h.psAxes,'on');
axtoolbar(h.psAxes,{'save','zoomin','zoomout','restoreview','pan'});

drawnow limitrate;
set_status(h.figure,"ready","Power Spectra Plot Complete...");

guidata(h.figure,h);
end
