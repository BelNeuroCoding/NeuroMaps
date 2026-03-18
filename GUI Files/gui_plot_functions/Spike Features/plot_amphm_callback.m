function plot_amphm_callback(h,hm_props)
h = guidata(h.figure);
set_status(h.figure,"loading","Mapping Firing rates...");

if nargin<2
    hm_props = [];
end
%  Load probe map 
probe_maps = get(h.probe_map, 'Data');  
if ~isempty(probe_maps)
    matFile = probe_maps{2};
else
    matFile = 'sparse_x_y_coords.mat';
end
load(matFile, 'x_coords', 'y_coords', 'maps');

%  Clear main axes tab 
children = allchild(h.amp_tab); 
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
if isfield(h,'ampplotPanel') 
delete(findall(h.ampplotPanel,'Type','axes'))
delete(findall(h.ampplotPanel,'Type','tiledlayout'))
end

h.ampplotPanel = uipanel( ...
    'Parent', h.amp_tab, ...
    'Units','normalized', ...
    'Position',[0 0.15 1 0.85],'BackgroundColor',[1 1 1]); 
% Create tiled layout
tlo = tiledlayout(h.ampplotPanel, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');
img_togg = get(h.overlay_img).Value;
if img_togg
    probe_maps = get(h.probe_map, 'Data');   % cell array of file paths
    if ~isempty(probe_maps)
        matFile = probe_maps{2};   % second row (.mat file)
        imgFile = probe_maps{1};
    else
        matFile = 'sparse_x_y_coords.mat';
        imgFile = "sparseimg.tif";
    end
else
    imgFile = [];
end
for i = 1:size(selected,1)

    % --- Load results ---
    expIdx = selected(i,1);
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    selected_idx = selected(i,2);
    current_port = results.ports(selected_idx).port_id;

    % --- Ensure spike data exists ---
    if numel(results.spike_results) < selected_idx
        choice = questdlg( ...
            'Waveforms were not detected. Run spike detection?', ...
            'Spike Detection','Yes','No','Yes');

        if strcmp(choice,'Yes')
            run_spike_analysis(h);
        end
        return;
    end

    % --- Extract waveforms ---
    waveforms_all = results.spike_results(selected_idx).waveforms_all;

    % --- Apply amplitude / FWHM filtering ---
    if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)
        r = h.spike_filter_ranges;

        ptp  = [waveforms_all.ptp_amplitude]';
        fwhm = [waveforms_all.fwhm]';

        keep = ptp >= r.amp(1) & ptp <= r.amp(2) & ...
               fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);

        waveforms_all = waveforms_all(keep);
    end

    % --- Cluster filtering ---
    selectedStrings = get(h.clusterListBox,'String');
    selectedIdx     = get(h.clusterListBox,'Value');

    if ~isempty(selectedIdx) && isfield(waveforms_all,'clusters')
        selectedClusters = str2double(selectedStrings(selectedIdx));
        waveforms_all = waveforms_all( ...
            ismember([waveforms_all.clusters], selectedClusters));
    end

    % --- Guard against empty ---
    if isempty(waveforms_all)
        warning('No spikes remaining after filtering');
        continue;
    end

    % --- Compute amplitude per channel ---
    channels = [waveforms_all.channel];
    ptp_vals = [waveforms_all.ptp_amplitude];

    chans = unique(channels);
    amp   = zeros(size(chans));

    for j = 1:length(chans)
        idx = channels == chans(j);
        amp(j) = median(ptp_vals(idx));   % robust choice
    end

    % --- Create subplot ---
    ax = nexttile(tlo, i);

    % --- Plotting ---
    switch topo_togg

        case 'Distribution'
            histogram(ax, amp, 10, ...
                'FaceColor',[0 0.5 0.5], 'EdgeColor','k');
            xlabel(ax,'Amplitude (µV)');
            ylabel(ax,'Counts');
            axis(ax,'square');

        case 'Simple Map'
            plot_heatmap_callback(amp, chans, ...
                sprintf('Amplitude (µV) - Expt %d Port %d', expIdx, current_port), ...
                x_coords, y_coords, imgFile, hm_props);

        case 'Topographic Map'

            if h.fr_toggle.Value
                % --- Mean waveform per channel ---
                all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
                channels_all  = [waveforms_all.channel];

                mean_waveforms = zeros(length(chans), size(all_waveforms,2));

                for j = 1:length(chans)
                    idx = channels_all == chans(j);
                    mean_waveforms(j,:) = mean(all_waveforms(idx,:),1);
                end

                plot_interp_heatmap(amp, chans, ...
                    sprintf('Amplitude (µV)'), ...
                    x_coords, y_coords, mean_waveforms, imgFile, hm_props);

            elseif h.fr_clust_toggle.Value
                % --- Channel x Cluster mean waveforms ---
                all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
                channels_all  = [waveforms_all.channel];
                clust         = [waveforms_all.clusters];

                chans  = unique(channels_all);
                clusts = unique(clust);

                nCh = length(chans);
                nCl = length(clusts);
                nSamp = size(all_waveforms,2);

                mean_waveforms = zeros(nCh, nCl, nSamp);

                for j = 1:nCh
                    for k = 1:nCl
                        idx = channels_all == chans(j) & clust == clusts(k);
                        if any(idx)
                            mean_waveforms(j,k,:) = mean(all_waveforms(idx,:),1);
                        end
                    end
                end

                plot_interpclust_heatmap(amp, chans, ...
                    'Amplitude (µV)', ...
                    x_coords, y_coords, mean_waveforms, imgFile, hm_props);

            else
                plot_interp_heatmap(amp, chans, ...
                    sprintf('Amplitude (µV)'), ...
                    x_coords, y_coords, [], imgFile, hm_props);
            end
    end

    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
end
set_status(h.figure,"ready","Amplitude map complete...");
guidata(h.figure,h)

end