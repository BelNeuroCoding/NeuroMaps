function plot_fr_callback(h,hm_props)

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
if isfield(h,'FRplotPanel') 
delete(findall(h.FRplotPanel,'Type','axes'))
delete(findall(h.FRplotPanel,'Type','tiledlayout'))
end

h.FRplotPanel = uipanel( ...
    'Parent', h.fr_tab, ...
    'Units','normalized', ...
    'Position',[0 0.15 1 0.85],'BackgroundColor',[1 1 1]); 
% Create tiled layout
tlo = tiledlayout(h.FRplotPanel, rows, cols, 'TileSpacing', 'Compact', 'Padding', 'Compact');
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
        TimeStamps = results.timestamps;
        recording_time = max(TimeStamps)-min(TimeStamps);
         %  Filter selected clusters 
        selectedStrings = get(h.clusterListBox,'String');  % all strings in listbox
        selectedIdx     = get(h.clusterListBox,'Value');   % indices of selected strings
        if ~isempty(selectedIdx) && isfield(waveforms_all,'clusters')
            selectedClusters = str2double(selectedStrings(selectedIdx));
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
                plot_heatmap_callback(fr, chans, sprintf('FR Hz (Expt %d Port %d)',expIdx,current_port), x_coords, y_coords,imgFile,hm_props);
    
            case 'Topographic Map'
                if h.fr_toggle.Value
                    all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');                    
                    channels = cell2mat(arrayfun(@(x) x.channel, waveforms_all, 'UniformOutput', false)');
                    mean_waveforms = zeros(length(chans), size(all_waveforms,2));
                    for j = 1:length(chans)
                        idx_ch = channels == chans(j);
                        mean_waveforms(j,:) = mean(all_waveforms(idx_ch,:),1);
                    
                    end
                    plot_interp_heatmap(fr, chans, sprintf('FR Hz (Expt %d Port %d)',expIdx,current_port), x_coords, y_coords,mean_waveforms,imgFile,hm_props);
                elseif h.fr_clust_toggle.Value
                    selectedStrings = get(h.clusterListBox,'String');
                    selectedIdx     = get(h.clusterListBox,'Value');
                    
                    if ~isempty(selectedIdx) && isfield(waveforms_all,'clusters')
                    
                        selectedClusters = str2double(selectedStrings(selectedIdx));
                        waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
                    
                        all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
                        channels      = cell2mat(arrayfun(@(x) x.channel, waveforms_all, 'UniformOutput', false)');
                        clust         = [waveforms_all.clusters]';
                    
                        chans  = unique(channels);
                        clusts = unique(clust);
                    
                        nCh = length(chans);
                        nCl = length(clusts);
                        nSamp = size(all_waveforms,2);
                    
                        mean_waveforms = zeros(nCh, nCl, nSamp);
                    
                        for j = 1:nCh
                            for k = 1:nCl
        
                                idx = find(channels == chans(j) & clust == clusts(k));
                                if isempty(idx), continue; end
                                wf = all_waveforms(idx,:);
                                mean_waveforms(j,k,:)  = mean(wf,1);                    
                            end
                        end
                    
                    end
                    plot_interpclust_heatmap(fr,chans,sprintf('FR'),x_coords,y_coords,mean_waveforms,imgFile,hm_props)

                else
                    plot_interp_heatmap(fr, chans, sprintf('FR Hz (Expt %d Port %d)',expIdx,current_port), x_coords, y_coords,[],imgFile,hm_props);
                end
        end
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    end

end
set_status(h.figure,"ready","Firing rate maps complete...");
guidata(h.figure,h);
end
