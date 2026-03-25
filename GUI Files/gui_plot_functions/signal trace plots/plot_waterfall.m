function plot_waterfall(ax, signals, ChosenChannels, TimeStamps, title_str, axprops)
%% plot_waterfall - Stacked channel plot with labels and scale bars
% Inputs:
%   ax            - axes handle to plot into
%   signals       - signal matrix (channels x time)
%   ChosenChannels- channels to plot
%   TimeStamps    - corresponding time vector
%   title_str     - plot title
%   port          - port ID (for title)

if isempty(axprops)
    spacing = 300;  % vertical offset between channels
    scaleBarAmp = 200;
    scale_bar_length = 0.1*(TimeStamps(end)-TimeStamps(1));
else
    spacing = axprops.spacing;
    scale_bar_length = axprops.scaleBarTimeFrac;   % fraction of x-range
    scaleBarAmp = axprops.scaleBarAmplitude;  % e.g. 200 uV
end
num_channels = length(ChosenChannels);
colors = lines(num_channels);  % distinct colors
hold(ax,'on');
xrange = diff(xlim(ax));
labelX = TimeStamps(1) - 0.05*xrange; % 5% to the left of axis
pixelHeightPerChannel = 30;
totalHeight = length(ChosenChannels)*pixelHeightPerChannel;

ax.Units = 'pixels';

pos = ax.Position;
pos(4) = totalHeight;
ax.Position = pos;
for i = 1:num_channels
    chan = ChosenChannels(i);
    plot(ax, TimeStamps, signals(i,:) + (2*i-1)*spacing, 'Color', colors(i,:));
    text(ax, labelX, (2*i-1)*spacing, ...
         sprintf('Ch %d', chan), ...
         'Color', colors(i,:), ...
         'VerticalAlignment','middle', ...
         'HorizontalAlignment','right','Clipping','off');
end
    
% Add scale bars

xrange = TimeStamps(end) - TimeStamps(1);

x0 = TimeStamps(1) + 0.01 * xrange;   
y0 = -2 * spacing;                    % below signals

plot(ax, [x0, x0 + scale_bar_length], [y0, y0], 'k', 'LineWidth', 1);
plot(ax, [x0, x0], [y0, y0 + scaleBarAmp], 'k', 'LineWidth', 1);

text(ax, x0 + scale_bar_length/2, ...
        y0 - 0.4*spacing, ...   % more clearance
        sprintf('%.2f s', scale_bar_length), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top','FontSize',9);

text(ax, x0 - 0.03*xrange, ...
        y0- 0.7*spacing, ...
        sprintf('%d µV', scaleBarAmp), ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','middle', ...
        'Rotation',90,'FontSize',9);

% Axis formatting
title(ax, [title_str]);
ylim(ax, [-3, num_channels]*2*spacing + spacing);
xlim(ax,[TimeStamps(1)-0.05*xrange TimeStamps(end)+0.05*xrange])

set(ax,'Color',[1 1 1],'XColor','k','YColor','none');
hold(ax,'off');
end
