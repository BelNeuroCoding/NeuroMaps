function pop_spiking_plot(h)
h = guidata(h.figure);
prompt = {'Enter binarisation rate (Hz):'};
dlgtitle = 'Binarisation Rate';
dims = [1 35];
definput = {'1000'}; % default = 1000 Hz
bin_answer = inputdlg(prompt, dlgtitle, dims, definput);

children = allchild(h.nws_tab); 
delete(findobj(children, 'Type', 'axes'));

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
tlo = tiledlayout(h.nws_tab, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:size(selected,1)
    expIdx = selected(i,1);
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    selected_idx = selected(i,2);      % single-experiment mode: selected(i,1) is always 1
    TimeStamps = results.timestamps;
    recording_time = max(TimeStamps)-min(TimeStamps);
    waveforms_all = results.spike_results(selected_idx).waveforms_all;
    if ~isfield(waveforms_all,'clusters')
        [waveforms_all.clusters] = deal(1);
    else
    selectedClusters = get(h.clusterListBox,'Value');
    if ~isempty(selectedClusters)
        waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
    end
    end
    fs = results.fs;
  
    %  Create subplot axes for this experiment 
    ax = nexttile(tlo, i);
    hold(ax,'on');
    
    network_pop_plot(waveforms_all,TimeStamps,fs,recording_time,bin_answer,ax)
    ylabel('Population Spiking Plot')
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

    hold all

end