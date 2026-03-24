function create_network_tabs(h)
h=guidata(h.figure);
backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
if ~isfield(h,'network_dynamics_tab') || ~isvalid(h.network_dynamics_tab)
h.network_dynamics_tab = uitab(h.tabgroup2, 'Title', 'Network Dynamics','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
%% Nested Spike Feature Tabs
h.networkTabs = uitabgroup('Parent', h.network_dynamics_tab, 'Units', 'normalized', 'Position', [0 0 1 1]);
h.nc_tab        = uitab(h.networkTabs, 'Title', 'Network Connectivity','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.netconn_plot_button = uicontrol('Style', 'pushbutton','Parent', h.nc_tab,'String', 'Analyse Connectivity', ...
'Units', 'normalized','Position', [0.70, 0.0, 0.30, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) network_conn_callback(h));    

h.nwcorr_tab        = uitab(h.networkTabs, 'Title', 'Correlation Tab','BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor);
h.nwcorr_plot_button = uicontrol('Style', 'pushbutton','Parent', h.nwcorr_tab,'String', 'Plot Correlation', ...
'Units', 'normalized','Position', [0.70, 0.0, 0.30, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
'Callback', @(src, event) nwcorr_callback(h));    
end
guidata(h.figure,h)

end