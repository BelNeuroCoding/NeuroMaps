function Elec_plot_callback(h)
%% ELEC_PLOT_CALLBACK - Subtabs per port, Z/C inside each port

h = guidata(h.figure);  
set_status(h.figure,"loading","Computing Electrical Properties...");
accentcolor = [0.1, 0.4, 0.6];
% Get selected port indices
idx = h.portList.Value;           
map = h.portList.UserData;        
selected = map(idx,:);            

% Load probe map coordinates
[x_coords, y_coords, maps] = load_probe_map(h);

children = allchild(h.ZC_tab);

for k = 1:length(children)
    % Only delete tabs and axes, not the button
    if ~isequal(children(k), h.Elec_plot_button)
        if isa(children(k),'matlab.ui.container.Tab') || isa(children(k),'matlab.ui.container.TabGroup') || isa(children(k),'matlab.graphics.axis.Axes')
            delete(children(k))
        end
    end
end

% Create top-level uitabgroup for ports
tg_ports = uitabgroup(h.ZC_tab,'Units','normalized', ...
        'Position',[0 0.06 1 0.94]);

% Get topography overlay options
topo_togg = get(h.bg.SelectedObject,'String');
img_togg = get(h.overlay_img).Value;

if img_togg
    probe_maps = get(h.probe_map, 'Data');
    if ~isempty(probe_maps)
        matFile = probe_maps{2};
        imgFile = probe_maps{1};
    else
        matFile = 'sparse_x_y_coords.mat';
        imgFile = "sparseimg.tif";
    end
else
    imgFile = [];
end

numPorts = size(selected,1);

for i = 1:numPorts
    expIdx = selected(i,1);

    % Extract results for this experiment
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
        exptit = ['Exp ' num2str(expIdx) ' '];
    else
        results = h.figure.UserData;
        exptit = [];
    end

    selected_idx = selected(i,2);
    port_chans = results.channels(selected_idx).id;
    selectedport = results.ports(selected_idx).port_id;

    Z = results.electrical_properties(selected_idx).electrode_impedance;
    C = results.electrical_properties(selected_idx).electrode_capacitance;
    Z(Z>1000) = 1000;

    %  Create top-level tab for this port 
    tab_port = uitab(tg_ports,'Title',[exptit 'Port ' num2str(selectedport)],'BackgroundColor',[1 1 1],'ForegroundColor', accentcolor);

    %  Create sub-tab group inside this port tab 
    tg_sub = uitabgroup(tab_port);

    % Impedance sub-tab
    tabZ = uitab(tg_sub,'Title','Impedance','BackgroundColor',[1 1 1],'ForegroundColor', accentcolor);
    axZ = axes(tabZ);
    switch topo_togg
        case 'Distribution'
            histogram(axZ,Z,10,'FaceColor',[0 0.5 0.5],'EdgeColor','k');
            xlabel(axZ,['Impedance ' exptit 'Port ' num2str(selectedport) ' (k\Omega)']);
            ylabel(axZ,'Counts'); axis(axZ,'square');
        case 'Simple Map'
            plot_heatmap_callback(Z, port_chans, ['Impedance ' exptit 'Port ' num2str(selectedport) ' (k\Omega)'], x_coords, y_coords,imgFile);
        case 'Topographic Map'
            plot_interp_heatmap(Z, port_chans, ['Impedance ' exptit 'Port ' num2str(selectedport) ' (k\Omega)'], x_coords, y_coords,[],imgFile);
    end

    % Capacitance sub-tab
    tabC = uitab(tg_sub,'Title','Capacitance','BackgroundColor',[1 1 1],'ForegroundColor', accentcolor);
    axC = axes(tabC);
    switch topo_togg
        case 'Distribution'
            histogram(axC,C,10,'FaceColor',[1 0.5 0.31],'EdgeColor','k');
            xlabel(axC,['Capacitance ' exptit 'Port ' num2str(selectedport) ' (nF)']);
            ylabel(axC,'Counts'); axis(axC,'square');
        case 'Simple Map'
            plot_heatmap_callback(C, port_chans, ['Capacitance ' exptit 'Port ' num2str(selectedport) ' (nF)'], x_coords, y_coords,imgFile);
            
        case 'Topographic Map'
            plot_interp_heatmap(C, port_chans, ['Capacitance ' exptit 'Port ' num2str(selectedport) ' (nF)'], x_coords, y_coords,[],imgFile);
    end
end

set_status(h.figure,"ready","Electrical Properties Plot Complete...");
end