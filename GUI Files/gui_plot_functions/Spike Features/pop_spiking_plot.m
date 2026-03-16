function pop_spiking_plot(h)
h = guidata(h.figure);
set_status(h.figure,"loading","Plotting Population Spiking Plot...");

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
    ptp  = [waveforms_all.ptp_amplitude]';
    fwhm = [waveforms_all.fwhm]';
    if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)

            r = h.spike_filter_ranges;
        
            idx_keep = ...
                ptp  >= r.amp(1)  & ptp  <= r.amp(2) & ...
                fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
        
            waveforms_all = waveforms_all(idx_keep);
    end

    if ~isfield(waveforms_all,'clusters')
        [waveforms_all.clusters] = deal(1);
    else
    
   %  Filter selected clusters 
    selectedStrings = get(h.clusterListBox,'String');  % all strings in listbox
    selectedIdx     = get(h.clusterListBox,'Value');   % indices of selected strings
    if ~isempty(selectedIdx)
        % Convert selected strings to numeric values if waveforms_all.clusters is numeric
        selectedClusters = str2double(selectedStrings(selectedIdx));
    
        % Filter waveforms
        if isnumeric([waveforms_all.clusters])
            waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
        else
            % fallback if clusters are stored as strings
            waveforms_all = waveforms_all(ismember({waveforms_all.clusters}, selectedStrings(selectedIdx)));
        end
    end
    end
    fs = results.fs;
  
    %  Create subplot axes for this experiment 
    ax = nexttile(tlo, i);
    hold(ax,'on');
    
    network_pop_plot(waveforms_all,TimeStamps,fs,recording_time,bin_answer,ax)
    ylabel('Population Spiking Plot')
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

    hold all;
set_status(h.figure,"ready","Completed Plotting Population Spiking Plot...");

end