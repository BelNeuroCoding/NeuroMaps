function h = plot_specgram(h, src)
%% Spectrogram plotting with panel & settings

h = guidata(h.figure);
set_status(h.figure, "loading", "Computing/Plotting Spectrogram...");

%% Get selected port
idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

expIdx = selected(1,1);
port_idx = selected(1,2);

% Load results
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else
    results = h.figure.UserData;
end

%% Get signal type
labelObj = get(h.formatToggleGroup, 'SelectedObject');
label = '';
if ~isempty(labelObj), label = labelObj.String; end
if isempty(label)
    label = questdlg('What would you like to plot?', 'Plot Selection', 'Raw','Filtered','Referenced','Raw');
end

%% Channel masks
exclude_impedance = get(h.excl_imp_toggle,'Value');
exclude_noisy = get(h.excl_high_STD_toggle,'Value');
channels = results.channels(port_idx).id;
mask = true(1, numel(channels));
if exclude_impedance
    mask = mask & ~results.channels(port_idx).bad_impedance;
end
if exclude_noisy
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    mask = mask & ~noisy;
end
channels = channels(mask);

%% Timestamps & sampling rate
Timestamps = results.timestamps;
fs = round(results.fs);

%% Extract signals and default frequency limits
switch label
    case {'Raw','AC Filtered'}
        sigmat = results.signals(port_idx).raw(mask,:);
        fmin = 1; fmax = fs/2;
    case 'LFP'
        sigmat = results.signals(port_idx).lfp(mask,:);
        fmin = 1; fmax = results.filt_params(port_idx).lfp;
        Timestamps = results.resampled_time;
    case 'Spikes'
        sigmat = results.signals(port_idx).hpf(mask,:);
        freqlims = results.filt_params(port_idx).spikes;
        fmin = freqlims(1); fmax = freqlims(2);
    case 'Ref'
        sigmat = results.signals(port_idx).ref(mask,:);
        if isfield(results,'filt_params')
            freqlims = results.filt_params(port_idx).spikes;
            fmin = freqlims(1); fmax = freqlims(2);
        else
            fmin = 1; fmax = fs/2;
        end
    otherwise
        error('Unexpected toggle state.');
end

%% Initialize spectrogram properties if needed
if ~isfield(h,'specgram_props')
    h.specgram_props.winLen  = 2;       % seconds
    h.specgram_props.stepLen = 0.5;     % seconds
    h.specgram_props.colormap = 'jet';
    h.specgram_props.fmin = fmin;
    h.specgram_props.fmax = fmax;
end
% Ensure fmax <= Nyquist
h.specgram_props.fmax = min(h.specgram_props.fmax, fs/2);
winLen = h.specgram_props.winLen;
stepLen = h.specgram_props.stepLen;

%% Time range
if nargin > 1
    time_plot = str2num(src.String);  % allow [start end]
else
    time_plot = [min(Timestamps), min(max(Timestamps), min(Timestamps)+60)];
end
time_plot(1) = max(time_plot(1), min(Timestamps));
time_plot(2) = min(max(time_plot(2), time_plot(1)+eps), max(Timestamps));

if nargin > 1
    src.String = num2str(time_plot);
else
    set(h.timeBox_specgram, 'String', num2str(round(time_plot)));
end

tIdx = Timestamps >= time_plot(1) & Timestamps <= time_plot(2);

%% Current channel
SeriesNumber = min(max(round(get(h.series_slider,'Value')),1), numel(channels));
current_ch = channels(SeriesNumber);
sig = sigmat(SeriesNumber, tIdx);
Timestamps = Timestamps(tIdx);

%% Create panel & axes
if ~isfield(h,'specgram_panel') || ~isvalid(h.specgram_panel)
    h.specgram_panel = uipanel('Parent', h.specgram_tab, ...
        'Units','normalized', 'Position',[0.05 0.15 0.9 0.8], ...
        'BackgroundColor',[1 1 1]);
end

if ~isfield(h,'specgram_axes') || ~isvalid(h.specgram_axes)
    h.specgram_axes = axes('Parent', h.specgram_panel);
else
    cla(h.specgram_axes);
    delete(findall(h.specgram_axes,'Type','colorbar'));
end

%% Compute spectrogram
overlapPercent = (1 - stepLen/winLen)*100;
[P,F,T] = pspectrum(sig', Timestamps, 'spectrogram', ...
                    'FrequencyLimits', [h.specgram_props.fmin, h.specgram_props.fmax], ...
                    'OverlapPercent', overlapPercent);

%% Cache results
h.specgramCache.P = P;
h.specgramCache.F = F;
h.specgramCache.T = T;
h.specgramCache.SeriesNumber = SeriesNumber;
h.specgramCache.time_plot = time_plot;
h.specgramCache.label = label;

%% Plot
imagesc(h.specgram_axes, T, F, pow2db(P));
set(h.specgram_axes,'YDir','normal');
colormap(h.specgram_axes, h.specgram_props.colormap);
c = colorbar(h.specgram_axes);
c.Label.String = 'Power (dB)';
ylim(h.specgram_axes, [h.specgram_props.fmin,h.specgram_props.fmax]);
xlabel(h.specgram_axes,'Time (s)');
ylabel(h.specgram_axes,'Frequency (Hz)');
title(h.specgram_axes,[label ' Spectrogram Ch: ' num2str(current_ch)]);
axtoolbar(h.specgram_axes,{'datacursor','save','zoomin','zoomout','restoreview','pan'});

set_status(h.figure,"ready","Spectrogram Plot Complete...");
guidata(h.figure,h);
end