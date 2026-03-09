function plot_raster_callback(h)
h = guidata(h.figure);
backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
%  Plot mode 
color_opts = get(h.colorPopup, 'String');   % cell array of options
idx = get(h.colorPopup, 'Value');           % selected index
color_mode = lower(color_opts{idx});

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

if ~isfield(h, 'plotPanel') || ~isvalid(h.plotPanel)
    h.plotPanel = uipanel(h.rast_tab, 'Position', [0 0.15 1 0.8],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor);
end
tlo = tiledlayout(h.plotPanel, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');


for i = 1:size(selected,1)
    expIdx = selected(i,1);
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    selected_idx = selected(i,2);      % single-experiment mode: selected(i,1) is always 1

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
    end
    TimeStamps = results.timestamps;
    fs = results.fs;
    recording_time = max(TimeStamps)-min(TimeStamps);

    %  Create subplot axes for this experiment 
    ax = nexttile(tlo, i);
    hold(ax,'on');
    if isfield(h,'clusterListBox')
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


    %  Plot according to color mode 
    switch color_mode
        case 'black'
            plain_raster_plot(waveforms_all, TimeStamps);
        case 'amplitude'
            amplitude_raster_plot(waveforms_all, TimeStamps);

        case 'clusters'
            cluster_raster_plot(waveforms_all, TimeStamps,ax);

        case 'bursts'
            analysis_results = results.spike_results(selected_idx).set.spike_analysis;
            bursts_raster_plot(analysis_results, TimeStamps,ax);

    end

    set(ax, 'FontSize', 8);
    set(ax,'TickDir','out');


    %  Network overlay if requested 
    if h.rast_pop_plot_toggle.Value
        bin_answer = inputdlg({'Enter binarisation rate (Hz):'}, 'Binarisation Rate', [1 35], {'1000'});
        network_pop_plot(waveforms_all, TimeStamps, fs, recording_time, bin_answer, ax);
    end

    axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});
end

end
