function plot_osc_callback(h)
h = guidata(h.figure);
set_status(h.figure,"loading","Plotting Oscillatory Power Heatmap...");

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

numTiles = size(selected,1);
maxRows = 2; 
maxCols = 2;

% Determine rows and cols for tiling
rows = min(maxRows, ceil(sqrt(numTiles)));
cols = min(maxCols, ceil(numTiles/rows));

% Create tiled layout
tlo = tiledlayout(h.osc_tab, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:size(selected,1)
    expIdx = selected(i,1);
    port_idx = selected(i,2);      % single-experiment mode: selected(i,1) is always 1

    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    bad_impedance = results.channels(port_idx).bad_impedance;
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if h.excl_imp_toggle.Value
        mask = mask & ~bad_impedance;
    end
    if h.excl_high_STD_toggle.Value
        mask =mask & ~noisy;
    end
    fooofed_results_fitted = results.foof_lfp(port_idx).foof_results(mask);

    all_fooofed_spectrum = cell2mat(arrayfun(@(x) x.fooofed_spectrum, fooofed_results_fitted, 'UniformOutput', false)');
    all_apfit = cell2mat(arrayfun(@(x) x.ap_fit, fooofed_results_fitted, 'UniformOutput', false)');
    freqs = cell2mat(arrayfun(@(x) x.freqs, fooofed_results_fitted, 'UniformOutput', false)');

    oscillatory_power = all_fooofed_spectrum - all_apfit;
    total_osc_power =  trapz(freqs(1,:), oscillatory_power')';
    chans = results.channels(port_idx).id(mask);
    %  Load probe map 
    probe_maps = get(h.probe_map, 'Data');  
    if ~isempty(probe_maps)
        matFile = probe_maps{2};
    else
        matFile = 'sparse_x_y_coords.mat';
    end
    load(matFile, 'x_coords', 'y_coords', 'maps');


    %  Axes for this experiment 
    ax = nexttile(tlo,i);
    hold(ax,'on');
    topo_togg = get(h.bg).SelectedObject.String;

    if strcmp(topo_togg,'Distribution')
        histogram(ax,total_osc_power,10,'FaceColor',[0 0.5 0.5],'EdgeColor','k')
        xlabel(ax,'Oscillatory Power (\muV^2/Hz)')
        ylabel(ax,'Counts')
        axis(ax,'square')
    elseif strcmp(topo_togg,'Simple Map')
        [x_coords,y_coords,maps] = load_probe_map(h);
        plot_heatmap_callback(total_osc_power,0:chans,'Oscillatory Power (\muV^2/Hz)',x_coords,y_coords)
    elseif strcmp(topo_togg,'Topographic Map')
        [x_coords,y_coords,maps] = load_probe_map(h);
        plot_interp_heatmap(total_osc_power,chans,'Oscillatory Power (\muV^2/Hz)',x_coords,y_coords)
        axis(ax,'square')
    end

    axtoolbar(ax,{'save','zoomin','zoomout','restoreview','pan'});

    %  Create / update table 
    if isfield(h,'osc_table_fig') && isvalid(h.osc_table_fig)
        % Update existing figure
        figure(h.osc_table_fig);
        set(h.osc_table, 'Data', [ (chans)' total_osc_power ]);
    else
        % Create new figure
        h.osc_table_fig = figure('Name','Oscillatory Power Table','NumberTitle','off',...
                                 'MenuBar','figure','ToolBar','figure',...
                                 'Position',[100 100 400 600]); % adjust size
        tableData = table(chans', total_osc_power, ...
                          'VariableNames', {'Channel','Oscillatory_Power_uV2_per_Hz'});
        h.osc_table = uitable('Parent',h.osc_table_fig,...
                             'Data', tableData{:,:},...
                             'ColumnName', tableData.Properties.VariableNames,...
                             'Units','normalized','Position',[0 0 1 1]);
    end

    % Save Table button (create once if missing)
    if ~isfield(h,'saveTableBtn') || ~isvalid(h.saveTableBtn)
        h.saveTableBtn = uicontrol('Parent', h.osc_table_fig, ...
                                   'Style','pushbutton', ...
                                   'String','Save Table', ...
                                   'Units','normalized', ...
                                   'Position',[0.8 0.02 0.15 0.05], ...
                                   'Callback', @(src,event) saveFRTable(h));
    end
end
set_status(h.figure,"ready","Completed Oscillatory Power Heatmap...");

end