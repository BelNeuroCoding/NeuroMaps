function init_power_spectrum_tab(h)
% Pre-create axes, line objects, legend, and probe map markers

h = guidata(h.figure);
idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

% Only one experiment & port at a time
expIdx = selected(1,1);
portIdx = selected(1,2);
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else
    results = h.figure.UserData;
end

mask = true(1,numel(results.channels(portIdx).id));
if get(h.excl_imp_toggle,'Value'), mask = mask & ~results.channels(portIdx).bad_impedance; end
if get(h.excl_high_STD_toggle,'Value')
    noisy = results.channels(portIdx).high_psd & results.channels(portIdx).high_std;
    mask = mask & ~noisy;
end
channels = results.channels(portIdx).id(mask);
numCh = numel(channels);

% Pre-create PSD axes
axesToDelete = findobj(h.pspec_tab, 'Type', 'axes');
delete(axesToDelete);
h.psAxes = subplot(1,1,1,'Parent',h.pspec_tab);
hold(h.psAxes,'on');

% Pre-create line objects
colorsMap = lines(numCh);
h.psLines = gobjects(numCh,1);
for ch = 1:numCh
    h.psLines(ch) = loglog(h.psAxes, nan, nan, 'Color', colorsMap(ch,:), 'LineWidth',1.5);
end

% Pre-create Welch line
h.psLinesWelch = loglog(h.psAxes, nan, nan, 'r-.', 'LineWidth',1.5);

guidata(h.figure,h);
end
