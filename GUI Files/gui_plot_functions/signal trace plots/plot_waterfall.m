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
scalebardist = TimeStamps(1) - 0.2*xrange;
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

scale_bar_y = -2*spacing;
plot(ax, [TimeStamps(1), TimeStamps(1)+scale_bar_length], [scale_bar_y, scale_bar_y], 'k','LineWidth',1);
plot(ax, [TimeStamps(1), TimeStamps(1)], [scale_bar_y, scale_bar_y+scaleBarAmp], 'k','LineWidth',1);
text(ax, TimeStamps(1)+scale_bar_length/2, scale_bar_y-scalebardist, sprintf('%.1f s', scale_bar_length), 'HorizontalAlignment','center');
text(ax, scalebardist, scale_bar_y, sprintf('%d uV',scaleBarAmp), 'HorizontalAlignment','center','Rotation',90);

% Axis formatting
title(ax, [title_str]);
ylim(ax, [-3, num_channels]*2*spacing + spacing);
set(ax,'Color',[1 1 1],'XColor','k','YColor','none');
hold(ax,'off');

end
