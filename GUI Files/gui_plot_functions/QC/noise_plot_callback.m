function noise_plot_callback(h)
%% This Function Computes Noise using the Quiroga et al estimation: median(abs(signal)/0.6745)
%% Takes in the GUI handle containing data and plots distribution/map depending on toggle.
h = guidata(h.figure);  
set_status(h.figure,"loading","Computing Noise Levels...");

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

% Get user-selected data format
selectedStr = get(h.formatToggleGroup, 'SelectedObject').String;
lab = extract_lab(selectedStr);

numTiles = size(selected,1);
maxRows = 2; 
maxCols = 4;

% Determine rows and cols for tiling
rows = min(maxRows, ceil(sqrt(numTiles)));
cols = min(maxCols, ceil(numTiles/rows));

% Clear tab axes
children = allchild(h.noise_tab);         % get all children
axesToDelete = findobj(children, 'Type', 'axes');  % find only axes
delete(axesToDelete);                      % delete them
% 
h.noise_button = uicontrol('Style', 'pushbutton','Parent', h.noise_tab,'String', 'Plot Noise Levels', ...
'Units', 'normalized','Position', [0.80, 0.0, 0.20, 0.05], ... % Adjust position as needed
'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6], ...
'Callback', @(src, event) noise_plot_callback(h));   

% Create tiled layout
tlo = tiledlayout(h.noise_tab, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');

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
    signals = results.signals(selected_idx).(lab);
    selectedport = results.ports(selected_idx).port_id;
    noiseVals = median(abs(signals),2)/0.6745;
    results.qc(selected_idx).noise = noiseVals;


    % Create subplots
    ax =nexttile(tlo, i);
    topo_togg = get(h.bg).SelectedObject.String;
    set_status(h.figure,"loading","Plotting Noise...");

    switch topo_togg
        case 'Distribution'
            histogram(noiseVals,10,'FaceColor',[0.5 0 0.5],'EdgeColor','k')
            xlabel(ax,['Noise Levels ' exptit 'Port ' num2str(selectedport)  ' (\muV)'])
            ylabel(ax,'Counts')
        case 'Simple Map'
            [x_coords, y_coords, maps] = load_probe_map(h);
            plot_heatmap_callback(noiseVals,results.channels(selected_idx).id, ...
                                 ['Noise Levels ' exptit 'Port ' num2str(selectedport)  ' (\muV)'],x_coords,y_coords);
        case 'Topographic Map'
            [x_coords, y_coords, maps] = load_probe_map(h);
            plot_interp_heatmap(noiseVals,results.channels(selected_idx).id, ...
                                ['Noise Levels ' exptit 'Port ' num2str(selectedport)  ' (\muV)'],x_coords,y_coords);
    end

    axtoolbar(ax,{'save','zoomin','zoomout','restoreview','pan'});
    axis(ax,'square')
    
    % --- Update summary text
    currentText = get(h.summary_text,'String');
    if ischar(currentText), currentText = cellstr(currentText); end
    newMsg = sprintf('Noise Measurement (%s) - Exp %d, Port %d', ...
                     lab, expIdx, selectedport);
    currentText{end+1} = newMsg;
    set(h.summary_text,'String',currentText);
end
set_status(h.figure,"ready","Noise Plot Complete...");

end
