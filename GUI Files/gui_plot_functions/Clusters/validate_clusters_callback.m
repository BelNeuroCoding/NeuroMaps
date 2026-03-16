function validate_clusters_callback(h)
h = guidata(h.figure);
set_status(h.figure,"loading","Validate Clusters...");

idx = h.portList.Value;        % listbox indices
map = h.portList.UserData;     % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);

if size(selected,1) > 1
    choicesStr = cell(size(selected,1),1);
    for i = 1:size(selected,1)
        expIdxTmp = selected(i,1);
        portIdxTmp = selected(i,2);
        if iscell(h.figure.UserData)
            resultsTmp = h.figure.UserData{expIdxTmp};
        else
            resultsTmp = h.figure.UserData;
        end
        portID = resultsTmp.ports(portIdxTmp).port_id;
        choicesStr{i} = sprintf('Exp %d, Port %d', expIdxTmp, portID);
    end

    % Ask user which one to use
    sel = listdlg('PromptString','Multiple experiments/ports selected. Choose one:', ...
                  'SelectionMode','single', 'ListString', choicesStr);
    if isempty(sel)
        return; % user cancelled
    end
    expIdx = selected(sel,1);
    selected_idx = selected(sel,2);
else
    expIdx = selected(1,1);
    selected_idx = selected(1,2);
end

%  Load results 
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else
    results = h.figure.UserData;
end
waveforms_all = results.spike_results(selected_idx).waveforms_all;
selectedClusters = get(h.clusterListBox,'Value');
if ~isempty(selectedClusters) && isfield(waveforms_all,'clusters')
    waveforms_all = waveforms_all(ismember([waveforms_all.clusters], selectedClusters));
end
results.spike_results(selected_idx).waveforms_all = waveforms_all;

% Save updated results
if iscell(h.figure.UserData)
    allresults = h.figure.UserData;
    allresults{expIdx} = results;
    set(h.figure, 'UserData', allresults);
else
    set(h.figure, 'UserData', results);
end
h=guidata(h.figure);
% Only proceed if spikes detected
results.spike_results(selected_idx).set = spike_feats_callback(h);
% Save updated results
if iscell(h.figure.UserData)
    allresults = h.figure.UserData;
    allresults{expIdx} = results;
    set(h.figure, 'UserData', allresults);
else
    set(h.figure, 'UserData', results);
end
 set_status(h.figure,"ready","Clusters Validation Complete...");

plot_cluster_callback(h);
end