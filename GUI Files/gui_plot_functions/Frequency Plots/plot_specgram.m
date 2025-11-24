function h= plot_specgram(h,src)
%%  Spectrogram Plotting for Selected Channel & Experiment 
%  Get selected port and format 
h = guidata(h.figure);

%%  Get selected port 
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);

% Only allow one experiment & port
expIdx = selected(1,1);
port_idx = selected(1,2);      

% Load results
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else
    results = h.figure.UserData;
end

label = get(h.formatToggleGroup, 'SelectedObject').String;

if isempty(label)
     label = questdlg('What would you like to plot?', ...
    'Plot Selection', ...
    'Raw','Filtered','Referenced','Raw');
end

exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
channels = results.channels(port_idx).id;
mask = true(1,numel(channels));
if exclude_impedance_chans_toggle
    bad_impedance = results.channels(port_idx).bad_impedance;
    mask = mask & ~bad_impedance;
end
if exclude_noisy_chans_toggle
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    mask =mask & ~noisy;
end
channels = channels(mask);

%  Extract timestamps and sampling rate 
Timestamps = results.timestamps;
fs = round(results.fs);

%  Get signals and frequency limits based on toggle 
switch label
    case {'Raw','AC Filtered'}
        signals = results.signals(port_idx).raw(mask,:);
        frequencyLimits = [1 fs/2];
    case 'LFP'
                signals = results.signals(port_idx).lfp(mask,:);
                frequencyLimits = [1 results.filt_params(port_idx).lfp];
                Timestamps = results.resampled_time;
    case 'Spikes'
                signals = results.signals(port_idx).hpf(mask,:);
                frequencyLimits = results.filt_params(port_idx).spikes;
    case 'Ref'
        signals = results.signals(port_idx).ref(mask,:);
        if isfield(results,'filt_params')
            frequencyLimits = results.filt_params(port_idx).spikes;
        else
            frequencyLimits = [1 fs/2];
        end
    otherwise
        error('Unexpected toggle state.');
end

%  Read start/end times from UI 
if nargin>1
    time_plot = str2num(src.String);
else
    time_plot = [min(Timestamps),min(max(Timestamps),60)];
end
% Validate times
if isnan(time_plot(1)) || time_plot(1) < min(Timestamps)
    time_plot(1) = min(Timestamps);
end
if isnan(time_plot(2)) || time_plot(2) <= time_plot(1) || time_plot(2)>max(Timestamps)
    time_plot(2) = max(Timestamps);
end
if nargin>1
src.String=num2str(time_plot);
else
    set(h.timeBox_specgram,'String',num2str(time_plot));
end

%  Restrict signals to time range 
tIdx = Timestamps >= time_plot(1) & Timestamps <= time_plot(2);


%  Get current channel from slider 
SeriesNumber = round(get(h.series_slider, 'Value'));
current_ch = channels(SeriesNumber);

signals = signals(SeriesNumber, tIdx);
Timestamps = Timestamps(tIdx);

%  Compute and plot spectrogram 
axes(h.specgram_plots_axes);
if ~isfield(h,'specgramCache')
    h.specgramCache = struct();
end

% Only recompute if anything changed
needsRecompute = ...
    ~isfield(h.specgramCache,'SeriesNumber') || h.specgramCache.SeriesNumber ~= SeriesNumber || ...
    ~isequal(h.specgramCache.time_plot,time_plot) || ...
    ~strcmp(h.specgramCache.label,label);

if needsRecompute
    % compute spectrogram
    [P,F,T] = pspectrum(signals', Timestamps, 'spectrogram', 'FrequencyLimits', frequencyLimits,'OverlapPercent',50);
    
    % store cache
    h.specgramCache.P = P;
    h.specgramCache.F = F;
    h.specgramCache.T = T;
    h.specgramCache.SeriesNumber = SeriesNumber;
    h.specgramCache.time_plot = time_plot;
    h.specgramCache.label = label;
else
    P = h.specgramCache.P;
    F = h.specgramCache.F;
    T = h.specgramCache.T;
end

imagesc(h.specgram_plots_axes, T, F, pow2db(P));
set(h.specgram_plots_axes, 'YDir','normal', 'Visible','on');
colormap(h.specgram_plots_axes, jet);
c = colorbar(h.specgram_plots_axes);
c.Label.String = 'Power (dB)'; 
c.FontSize = 12;
ylim(h.specgram_plots_axes, [frequencyLimits(1) frequencyLimits(2)/2]);
title(h.specgram_plots_axes, [label ' Signal Spectrogram Ch: ' num2str(current_ch)]);
axtoolbar({'datacursor','save','zoomin','zoomout','restoreview','pan'});
guidata(h.figure,h);
end
