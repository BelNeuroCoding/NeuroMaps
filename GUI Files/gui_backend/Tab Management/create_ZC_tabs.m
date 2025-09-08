function create_ZC_tabs(h)
h=guidata(h.figure);
backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
%% Nested Tabs - QC
if ~isfield(h,'quality_metrics_tab') || ~isvalid(h.quality_metrics_tab)
    h.quality_metrics_tab = uitab(h.tabgroup2, 'Title', 'Quality Check','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
    h.QCTabs = uitabgroup('Parent', h.quality_metrics_tab,'Units', 'normalized','Position', [0 0 1 1]);
end
if ~isfield(h,'ZC_tab') || ~isvalid(h.ZC_tab)
h.ZC_tab     = uitab(h.QCTabs, 'Title', 'Electrical Properties', 'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.Elec_plot_button = uicontrol('Style', 'pushbutton','Parent', h.ZC_tab,'String', 'Plot', ...
'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], ... 
'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) Elec_plot_callback(h));
h.qc_tab     = uitab(h.QCTabs, 'Title', 'QC','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.qc_plot_button = uicontrol('Style', 'pushbutton','Parent', h.qc_tab,'String', 'Plot', ...
'Units', 'normalized','Position', [0.80, 0.9, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, 'Callback', @(src, event) run_qc_plot(h));
h.qc_run_button = uicontrol('Style', 'pushbutton','Parent', h.qc_tab,'String', 'Run', ...
'Units', 'normalized','Position', [0.80, 0.95, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, 'Callback', @(src, event) run_qc_callback(h));
guidata(h.figure,h)
end
end