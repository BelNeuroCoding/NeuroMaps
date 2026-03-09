function render_waterfall_page(fig,src1,src2,lab,exclude_impedance_chans_toggle,exclude_noisy_chans_toggle)

h = guidata(fig);
backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB

selected = h.selectedPorts;
numTiles = size(selected,1);

startIdx = (h.waterfallPage-1)*h.tilesPerPage + 1;
endIdx = min(startIdx + h.tilesPerPage - 1, numTiles);

allChildren = get(h.waterfall_tab,'Children');

% List of handles NOT to delete
keepChildren = [h.export_waterfall_button,h.plot_waterfall_button,h.startLabel_waterfall, ...
                h.timeBox_waterfall, h.excluded_chansLabel_waterfall, ...
                h.excluded_chans_waterfall];

% Delete everything else
toDelete = setdiff(allChildren, keepChildren);
delete(toDelete);


tlo = tiledlayout(h.waterfall_tab,1,1,'TileSpacing','Compact','Padding','Compact');

tileCount = 1;

for i = startIdx:endIdx

    expIdx = selected(i,1);

    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
        exptit = ['Exp ' num2str(expIdx)];
    else
        results = h.figure.UserData;
        exptit = [];
    end

    portIdx = selected(i,2);

    channels = results.channels(portIdx).id;
    mask = true(1,numel(channels));

    if exclude_noisy_chans_toggle || exclude_impedance_chans_toggle
        bad_impedance = results.channels(portIdx).bad_impedance;
        noisy = results.channels(portIdx).high_psd & results.channels(portIdx).high_std;

        if exclude_impedance_chans_toggle
            mask = mask & ~bad_impedance;
        end

        if exclude_noisy_chans_toggle
            mask = mask & ~noisy;
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

    %% Time selection (unchanged)

    if nargin<3 || isempty(src1)
        startTime = min(TimeStamps);
        endTime = min(TimeStamps)+60;
        if isnan(endTime) || endTime <= startTime || endTime>max(TimeStamps)
            endTime = max(TimeStamps);
        end
    else
        timeplot = str2num(src1.String);
        startTime = timeplot(1);
        endTime = timeplot(2);
    end

    if nargin>3 && ~isempty(src2)
        excludedChannels = str2num(src2.String);
    else
        excludedChannels = [];
    end

    ChosenChannels = setdiff(channels, excludedChannels);

    timeIdx = TimeStamps >= startTime & TimeStamps <= endTime;
    TimeStamps = TimeStamps(timeIdx);
    signals = signals(:, timeIdx);

    %% Scrollable tile

    tile = nexttile(tlo,tileCount);
    
    pos = tile.Position;   % capture tile location
    delete(tile)           % remove axes created by nexttile
    
    scrollPanel = uipanel('Parent',h.waterfall_tab,...
        'Units','normalized',...
        'Position',pos,...
        'BorderType','none');
    scrollPanel.BackgroundColor = [1 1 1];
    % Capture panel position in pixels
    scrollPanel.Units = 'pixels';
    panelPos = scrollPanel.Position;
    
    % Slider width in pixels
    sliderWidth = 10;
    
    % Axes width = panel width minus slider
    axWidth = max(panelPos(3)-sliderWidth*1.5, 1);  % must be >=1
    
    % Axes height = total channels height
    pixelHeightPerChannel = 60;
    totalHeight = max(length(ChosenChannels)*pixelHeightPerChannel, 1);
    leftMargin = 40;   % space for channel labels
    % Create axes
    ax = axes('Parent',scrollPanel,...
              'Units','pixels',...
              'Position',[leftMargin 30 axWidth-leftMargin totalHeight],...
              'Clipping','off');
    
    
    slider = uicontrol('Parent',h.waterfall_tab,...
        'Style','slider',...
        'Units','normalized',...
        'Position',[0.95 0.15 0.03 0.8],...
        'Min',0,'Max',1,'Value',0,...
        'SliderStep',[0.02 0.1],...
        'BackgroundColor',[1 1 1],'Callback',@(src,~)scroll_waterfall(src,ax));

    plot_waterfall(ax, signals, ChosenChannels, TimeStamps, title_str);

    tileCount = tileCount + 1;

end

%% Navigation buttons

uicontrol('Parent',h.waterfall_tab,...
    'Style','pushbutton',...
    'String','<<',...
    'BackgroundColor',backgdcolor, ...
    'ForegroundColor',accentcolor,...
    'Position',[20 5 40 15],...
    'Callback',@(src,evt)prev_page(fig));
uicontrol('Parent',h.waterfall_tab,...
    'Style','pushbutton',...
    'String','>>', ...
    'BackgroundColor',backgdcolor, ...
    'ForegroundColor',accentcolor,...
    'Position',[70 5 40 15],...
    'Callback',@(src,evt)next_page(fig));
end

function scroll_waterfall(src,ax)

panel = ax.Parent;

ax.Units = 'pixels';
panel.Units = 'pixels';

axPos = ax.Position;
panelPos = panel.Position;

maxScroll = axPos(4) - panelPos(4);

if maxScroll <= 0
    return
end

scrollVal = src.Value;

axPos(2) = -scrollVal * maxScroll;
ax.Position = axPos;

end


function scroll_time(src,ax,signals,ChosenChannels,timeWindow,TimeStamps,title_str)
    startTime = src.Value;
    endTime = startTime + timeWindow;
    idx = TimeStamps >= startTime & TimeStamps <= endTime;
    TimeStamps_win = TimeStamps(idx);
    signals_win = signals(:,idx);
    cla(ax)
    plot_waterfall(ax, signals_win, ChosenChannels, TimeStamps_win, title_str)
end