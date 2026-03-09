function Elec_plot_callback(h)
%% ELEC_PLOT_CALLBACK - Updates impedance and capacitance plots for the selected port(s).

h = guidata(h.figure);  
set_status(h.figure,"loading","Computing Electrical Properties...");

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

% Load probe map
[x_coords, y_coords, maps] = load_probe_map(h);

% Clear tab axes
children = allchild(h.ZC_tab);
axesToDelete = findobj(children,'Type','axes');
delete(axesToDelete);

numTiles = size(selected,1);
maxRows = 2; 
maxCols = 4;

% Determine rows and cols for tiling
rows = min(maxRows, ceil(sqrt(numTiles*2)));
cols = min(maxCols, ceil(numTiles*2/rows));



% Create tiled layout
tlo = tiledlayout(h.ZC_tab, cols, rows, 'TileSpacing', 'Compact', 'Padding', 'Compact');

% Get selected topography option
topo_togg = get(h.bg.SelectedObject,'String');

% Loop through selections
for i = 1:numTiles
    expIdx = selected(i,1);
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
    Z(Z > 1000) = 1000;

    % Create next tiles for impedance and capacitance
    axZ = nexttile(tlo);
    axC = nexttile(tlo);
    set_status(h.figure,"loading","Plotting Electrical Property Metric...");

    switch topo_togg
        case 'Distribution'
            histogram(axZ, Z, 10, 'FaceColor', [0 0.5 0.5], 'EdgeColor', 'k');
            xlabel(axZ, ['Impedance ' exptit 'Port ' num2str(selectedport) ' (k\Omega)']); ylabel(axZ, 'Counts'); axis(axZ,'square');

            histogram(axC, C, 10, 'FaceColor', [1 0.5 0.31], 'EdgeColor', 'k');
            xlabel(axC, ['Capacitance ' exptit 'Port ' num2str(selectedport) ' (nF)']); ylabel(axC, 'Counts'); axis(axC,'square');

        case 'Simple Map'
            axes(axZ)
            plot_heatmap_callback(Z, port_chans,  ['Impedance ' exptit 'Port ' num2str(selectedport) ' (k\Omega)'], x_coords, y_coords);
            axis(axZ,'square');
            axes(axC)
            plot_heatmap_callback(C, port_chans, ['Capacitance ' exptit 'Port ' num2str(selectedport) ' (nF)'], x_coords, y_coords);
            axis(axC,'square');

        case 'Topographic Map'
            axes(axZ)
            plot_interp_heatmap(Z, port_chans,  ['Impedance ' exptit 'Port ' num2str(selectedport) ' (k\Omega)'], x_coords, y_coords);
            axis(axZ,'square');
            axes(axC)
            plot_interp_heatmap(C, port_chans, ['Capacitance ' exptit 'Port ' num2str(selectedport) ' (nF)'], x_coords, y_coords);
            axis(axC,'square');
    end
end
set_status(h.figure,"ready","Electrical Properties Plot Complete...");

end
