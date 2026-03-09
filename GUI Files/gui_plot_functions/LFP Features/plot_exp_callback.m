function plot_exp_callback(h)

h = guidata(h.figure);
set_status(h.figure,"loading","Plotting Exponent Heatmap...");

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

numTiles = size(selected,1);
maxRows = 2; 
% Determine rows and cols for tiling
rows = min(maxRows, ceil(sqrt(numTiles)));

% Create tiled layout
tlo = tiledlayout(h.exps_tab, rows, 2, 'TileSpacing', 'Compact', 'Padding', 'Compact');


for i = 1:numTiles
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
    all_aperiodic_params = cell2mat(arrayfun(@(x) x.aperiodic_params, fooofed_results_fitted, 'UniformOutput', false)');
    chans = results.channels(port_idx).id(mask);

    topo_togg =get(h.bg).SelectedObject.String;
    axApoff = nexttile(tlo);
    axApexp = nexttile(tlo);
    if strcmp(topo_togg,'Distribution')
        axes(axApoff)
        histogram(all_aperiodic_params(:,1),10,'FaceColor',[0 0.5 0.5],'EdgeColor','k')
        xlabel('Aperiodic Offset')
        ylabel('Counts')
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
        axis square
        axes(axApexp)
        histogram(all_aperiodic_params(:,2),10,'FaceColor',[0 0.5 0.5],'EdgeColor','k')
        xlabel('Aperiodic Exponent')
        ylabel('Counts')
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
        axis square
    elseif strcmp(topo_togg,'Simple Map')    
        [x_coords,y_coords,maps] = load_probe_map(h);
        axes(axApoff)
        hold(ax,'on')
        plot_heatmap_callback(all_aperiodic_params(:,1),chans,'Aperiodic Offset',x_coords,y_coords)
        axis square
    
        axes(axApexp)
        hold(ax,'on')
        plot_heatmap_callback(all_aperiodic_params(:,2),chans,'Aperiodic Exponent',x_coords,y_coords)
        axis square
    elseif strcmp(topo_togg,'Topographic Map')
        [x_coords,y_coords,maps] = load_probe_map(h);
        axes(axApoff)
        plot_interp_heatmap(all_aperiodic_params(:,1),chans,'Aperiodic Offset',x_coords,y_coords)
        axis square
    
        axes(axApexp)
        plot_interp_heatmap(all_aperiodic_params(:,2),chans,'Aperiodic Exponent',x_coords,y_coords)
        axis square
end
set_status(h.figure,"ready","Exponent Heatmap Plot Complete...");

axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

end
%  Create table figure 
if isfield(h,'exps_table_fig') && isvalid(h.exps_table_fig)
    % Update existing figure
    figure(h.exps_table_fig);
    set(h.exps_table, 'Data', [ chans' all_aperiodic_params(:,1) all_aperiodic_params(:,2)]);
else
    % Create new figure
    h.exps_table_fig = figure('Name','Aperiodic Params','NumberTitle','off',...
                            'MenuBar','figure','ToolBar','figure',...
                            'Position',[100 100 400 600]); % adjust size
    tableData = table(chans', all_aperiodic_params(:,1),all_aperiodic_params(:,2), ...
                      'VariableNames', {'Channel','Offset','Exponent'});
    h.exps_table = uitable('Parent',h.exps_table_fig,...
                         'Data', tableData{:,:},...
                         'ColumnName', tableData.Properties.VariableNames,...
                         'Units','normalized','Position',[0 0 1 1]);
end

h.saveTableBtn = uicontrol('Parent', h.exps_table_fig, ...
                           'Style','pushbutton', ...
                           'String','Save Table', ...
                           'Units','normalized', ...
                           'Position',[0.8 0.02 0.15 0.05], ...
                           'Callback', @(src,event) saveFRTable(h));

end
