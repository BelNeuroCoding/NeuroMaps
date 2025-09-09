function pop_graph_callback(h,src1,src2)
%% pop_graph_callback - Display channel signals over a selected time window
% This function handles both single and multi-experiment datasets.
% Users can select ports, specify time ranges, and exclude channels.
% Signals are displayed as stacked (waterfall) plots with scale bars and channel labels.
h = guidata(h.figure);  
% Get user-selected data format
selectedStr = get(h.formatToggleGroup, 'SelectedObject').String;
lab = extract_lab(selectedStr);

exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

numTiles = size(selected,1);
maxRows = 2; 
maxCols = 4;

% Determine rows and cols for tiling
rows = min(maxRows, ceil(sqrt(numTiles)));
cols = min(maxCols, ceil(numTiles/rows));

% Create tiled layout
tlo = tiledlayout(h.waterfall_tab, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');


% Loop through selections
for i = 1:size(selected,1)
    expIdx = selected(i,1);
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
        exptit = ['Exp ' num2str(expIdx)];
    else
        results = h.figure.UserData;
        exptit = [];
    end
    portIdx = selected(i,2);      % single-experiment mode: selected(i,1) is always 1
    channels = results.channels(portIdx).id;
    mask = true(1,numel(channels));
    if exclude_noisy_chans_toggle || exclude_impedance_chans_toggle
        bad_impedance = results.channels(portIdx).bad_impedance;
        noisy = results.channels(portIdx).high_psd & results.channels(portIdx).high_std;
        if exclude_impedance_chans_toggle
            mask = mask & ~bad_impedance;
        end
        if exclude_noisy_chans_toggle
            mask =mask & ~noisy;
        end
    end
    signals = results.signals(portIdx).(lab)(mask,:);
    channels = results.channels(portIdx).id(mask);
    if strcmp(lab,'lfp')
        TimeStamps = results.resampled_time;
    else
        TimeStamps = results.timestamps;
    end
    port_num = results.ports(portIdx).port_id;
    title_str = [exptit ' port ' num2str(port_num)];
    if nargin<2
        startTime = min(TimeStamps);
        endTime = min(TimeStamps)+60; 
        if isnan(endTime) || endTime <= startTime|| endTime>max(TimeStamps) || isempty(isempty(startTime))
            endTime = max(TimeStamps);
        end
        excludedChannels = [];
        set(h.timeBox_waterfall,'String',num2str([startTime,endTime]));
    elseif nargin<=3
        if ~isempty(src1)
        timeplot = str2num(src1.String);
        startTime = timeplot(1);
        endTime = timeplot(2);
        else
            startTime = min(TimeStamps);
            endTime = max(TimeStamps);
        end
        excludedChannels = [];
        % Validate times
        if isnan(startTime) || startTime < min(TimeStamps) 
            startTime = min(TimeStamps);
        end
        if isnan(endTime) || endTime <= startTime|| endTime>max(TimeStamps)
            endTime = max(TimeStamps);
        end
        src1.String = num2str([startTime,endTime]);    
    end
    if nargin>2
        excludedChannels = str2num(src2.String);
    end
    % Exclude channels if specified
    ChosenChannels = setdiff(channels, excludedChannels);

    % Filter signals by time window
    timeIdx = TimeStamps >= startTime & TimeStamps <= endTime;
    TimeStamps = TimeStamps(timeIdx);
    signals = signals(:, timeIdx);

    % Plot the signals in a tile
    ax = nexttile(tlo, i);
    plot_waterfall(ax, signals, ChosenChannels, TimeStamps, title_str);
end
end
