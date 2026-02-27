function plot_fr_callback(h)

h = guidata(h.figure);

%  Load probe map 
probe_maps = get(h.probe_map, 'Data');  
if ~isempty(probe_maps)
    matFile = probe_maps{2};
else
    matFile = 'sparse_x_y_coords.mat';
end
load(matFile, 'x_coords', 'y_coords', 'maps');

%  Clear main axes tab 
children = allchild(h.fr_tab); 
delete(findobj(children, 'Type', 'axes'));
topo_togg = get(h.bg).SelectedObject.String;


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
tlo = tiledlayout(h.fr_tab, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:size(selected,1)
    expIdx = selected(i,1);
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    selected_idx = selected(i,2);      % single-experiment mode: selected(i,1) is always 1
    current_port = results.ports(selected_idx).port_id;
    % Get channels and firing rates
    if numel(results.spike_results)<selected_idx
        choice = questdlg( ...
        'Waveforms were not detected. Would you like to detect spikes on the available data?', ...
        'Spike Detection', 'Yes','No','Yes');
    
    switch choice
        case 'Yes'
            run_spike_analysis(h);
        case 'No'
            return;
    end
    else
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
        selectedClusters = get(h.clusterListBox,'Value');
        TimeStamps = results.timestamps;
        recording_time = max(TimeStamps)-min(TimeStamps);
    
        if ~isempty(selectedClusters) && isfield(waveforms_all,'clusters')
            waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
            chans = unique([waveforms_all.channel]);
            fr = zeros(size(chans));
            for j = 1:length(chans)
                idx = ismember([waveforms_all.channel], chans(j));
                fr(j) = sum(idx)/recording_time;
            end
        else
            fr = [results.spike_results(selected_idx).set.spike_analysis.spike_rate];
            chans = [results.spike_results(selected_idx).set.spike_analysis.channel];
        end
    
        %  Create subplot axes for this experiment 
        ax = nexttile(tlo, i);
    
        %  Plot based on toggle 
        switch topo_togg
            case 'Distribution'
                histogram(ax, fr, 10, 'FaceColor',[0 0.5 0.5], 'EdgeColor','k');
                xlabel(ax,'Firing Rate (Hz)'); ylabel(ax,'Counts'); axis(ax,'square');
    
            case 'Simple Map'
                plot_heatmap_callback(fr, chans, sprintf('FR Hz (Expt %d Port %d)',expIdx,current_port), x_coords, y_coords);
    
            case 'Topographic Map'
                plot_interp_heatmap(fr, chans, sprintf('FR Hz (Expt %d Port %d)',expIdx,current_port), x_coords, y_coords);
                axis(ax,'square');
        end
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    end

end
end
