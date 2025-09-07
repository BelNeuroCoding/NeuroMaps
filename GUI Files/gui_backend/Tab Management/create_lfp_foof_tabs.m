function create_lfp_foof_tabs(h)
h= guidata(h.figure);
backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
if ~isfield(h,'foof_tab') || ~isvalid(h.foof_tab)
h.foof_tab = uitab(h.SpectralTabs, 'Title', 'FOOOF Analysis', 'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.fooof_button = uicontrol('Style', 'pushbutton','Parent', h.foof_tab,'String', 'Plot','Units', 'normalized','Position', [0.80, 0.0, 0.20, 0.05],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) PlotFooof_callback(h)); 
h.fooof_toggle = uicontrol('Style', 'checkbox','Parent', h.foof_tab,'Units', 'normalized', 'Position', [0.05 0 0.2 0.04], 'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor, ...
    'FontName', 'Cambria', 'FontSize', 11, 'String', 'Global', 'Value', 0,'Callback',@(src,event) PlotFooof_callback(h)); 

h.lfp_main_tab = uitab(h.tabgroup2, 'Title', 'LFP Analysis','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
%% Nested Tabs - LFP Analysis
h.lfpTabs = uitabgroup('Parent', h.lfp_main_tab, 'Units', 'normalized', 'Position', [0 0 1 1]);
h.osc_tab       = uitab(h.lfpTabs, 'Title', 'Oscillatory Plots','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.osc_plot_button = uicontrol('Style', 'pushbutton','Parent', h.osc_tab,'String', 'Plot Oscillatory Heatmap', ...
'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) plot_osc_callback(h));

h.exps_tab      = uitab(h.lfpTabs, 'Title', 'Exponents Plots','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.exp_plot_button = uicontrol('Style', 'pushbutton','Parent', h.exps_tab,'String', 'Plot Exponents Heatmap', ...
'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) plot_exp_callback(h));

h.PAC_tab       = uitab(h.lfpTabs, 'Title', 'PAC','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.PAC_plot_button = uicontrol('Style', 'pushbutton','Parent', h.PAC_tab,'String', 'Compute', ...
'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) PAC_callback(h));

h.bandpower_tab = uitab(h.lfpTabs, 'Title', 'Bandpower','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.bandpower_plot_button = uicontrol('Style', 'pushbutton','Parent', h.bandpower_tab,'String', 'Compute', ...
'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], ... % Adjust position as needed
'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) bandpower_callback(h));
h.time_resolved_bandpower = uicontrol('Style', 'checkbox','Parent', h.bandpower_tab,'Units', 'normalized', ...
    'Position', [0.05 0 0.2 0.04], 'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor, ...
    'FontName', 'Cambria', 'FontSize', 11, 'String', 'Time-resolved', 'Value', 0,'Callback',@(src,event) bandpower_callback(h)); 
end
guidata(h.figure,h)
end