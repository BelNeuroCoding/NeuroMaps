function run_qc_plot(h)
%% Perform QC on selected ports across experiments, plotting per port in tiled layout
h = guidata(h.figure);
set_status(h.figure,"loading","Computing QC Metrics...");
drawnow()
% Get selected ports from listbox
idx = h.portList.Value;                  % selected rows in the listbox
map = h.portList.UserData;               % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);                   % rows correspond to each selected port

% Load all results
all_Results = get(h.figure,'UserData');
if ~iscell(all_Results)
    all_Results = {all_Results};
end

%  Clear old QC axes 
delete(findobj(h.qc_tab, 'Type', 'axes'));
if isfield(h,'qCPanel')
    delete(h.qcPanel);
end
h.qcPanel = uipanel(h.qc_tab, ...
    'Units','normalized', ...
    'Position',[0 0.1 1 0.9], ... 
    'BackgroundColor',[1 1 1], ...
    'BorderType','none');

%  Determine tiling 
numTiles = size(selected,1);
cols = ceil(sqrt(numTiles));
rows = ceil(numTiles / cols);

tlo = tiledlayout(h.qcPanel, cols, rows, 'TileSpacing', 'Compact', 'Padding', 'Compact');

%  Loop through selected ports 
for i = 1:numTiles
    expIdx = selected(i,1);
    portIdx = selected(i,2);

    results = all_Results{expIdx};
    selectedport = results.ports(portIdx).port_id;
    port_chans = results.channels(portIdx).id;
    %  Load probe map 
    probe_maps = get(h.probe_map, 'Data');
    if ~isempty(probe_maps)
        matFile = probe_maps{2};
    else
        matFile = 'sparse_x_y_coords.mat';
    end
    load(matFile, 'x_coords', 'y_coords', 'maps');
    if ~isfield(results.channels(portIdx),'bad_impedance')
        warndlg(['QC plot on port ' num2str(selectedport) ' skipped'])
        return;
    end
    for c = 1:numel(port_chans)
        labels = {};
        if results.channels(portIdx).bad_impedance(c), labels{end+1} = 'Bad Impedance'; end
        if results.channels(portIdx).high_std(c), labels{end+1} = 'High STD/MAD'; end
        if results.channels(portIdx).high_psd(c), labels{end+1} = 'High PSD'; end
        if isfield(results.channels(portIdx),'dead_chans')
        if results.channels(portIdx).dead_chans(c), labels{end+1} = 'Dead'; end
        end
        qc_status{c} = labels;
    end
    set_status(h.figure,"loading","Plotting QC...");

    %  Plot QC in tiled layout 
    ax = nexttile(tlo, i);
    hold(ax,'on');
    categories = {'Good','Bad Impedance','High STD/MAD','High PSD','Dead'};
    colors = {
        [0.6 0.9 0.7];   % Good
        [1   0.4 0.6];   % Impedance
        [1   0.8 0.6];   % STD/MAD
        [0.3 0.3 1];     % PSD
        [0.5 0   0];     % Dead
    };
    for j = 1:numel(maps)
        elec_num = maps(j);
        idxChan = find(port_chans == elec_num);
        if isempty(idxChan), continue; end
    
        labels = qc_status{idxChan}; % cell of labels
        if isempty(labels)
            catIdx = 1; % Good
        else
            % pick first label (or prioritise Dead if multiple)
            if any(strcmp(labels,'Dead'))
                catIdx = 5; 
            else
                catIdx = find(strcmp(categories,labels{1}));
            end
        end
    
        scatter(ax,x_coords(j),y_coords(j),200, ...
            'MarkerFaceColor',colors{catIdx}, ...
            'MarkerEdgeColor','k','LineWidth',1.2, ...
            'Tag',sprintf('QCcat%d',catIdx));
        text(ax,x_coords(j),y_coords(j)+0.1,string(elec_num), ...
            'HorizontalAlignment','center','FontSize',8);
        set(ax,'YDir','reverse')
    end

    axis(ax,'equal'); axis(ax,'off');
    title(ax,sprintf('Exp %d, Port %d',expIdx, selectedport));
end

legLabels = {'Good','Bad Impedance','High STD/MAD','High PSD','Dead'};
hLeg = gobjects(1,numel(legLabels));
for k = 1:numel(legLabels)
    hLeg(k) = scatter(ax,NaN,NaN,100,colors{k}, 'filled','MarkerEdgeColor','k', ...
        'Tag',sprintf('QCcat%d',k));
end
lgd = legend(hLeg,categories,'Orientation','horizontal');
lgd.Layout.Tile = 'south'; % shared legend below all tiles
lgd.ItemHitFcn = @(src,evt) toggleVisibility(evt,tlo); 


set_status(h.figure,"ready","QC Plots Complete...");

guidata(h.figure,h)

end
function toggleVisibility(evt, ax) 
tag = evt.Peer.Tag; 
objs = findobj(ax.Parent,'Tag',tag); % find across all subplots 
if strcmp(objs(1).Visible,'on') 
    set(objs,'Visible','off'); 
else set(objs,'Visible','on'); 
end 
end


