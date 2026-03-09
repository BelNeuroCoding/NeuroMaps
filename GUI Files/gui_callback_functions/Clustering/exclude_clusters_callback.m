function exclude_clusters_callback(h)
%% EXCLUDE_CLUSTERS_CALLBACK - Exclude clusters or channel-cluster combos from selected ports
h = guidata(h.figure);

%% Ask user for clusters or channel-cluster combos
prompt = {'Enter clusters to exclude (e.g., 3,5) OR channel-cluster pairs (e.g., [1,3],[2,5]):'};
dlgtitle = 'Exclude Clusters';
dims = [1 70];
definput = {''};
answer = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer)
    return; % user cancelled
end

userInput = strtrim(answer{1});

clusterOnly = [];
channelClusterPairs = [];

if startsWith(userInput,'[')  % treat as channel-cluster pairs
    try
        channelClusterPairs = eval(['[' userInput ']']);
        if size(channelClusterPairs,2) ~= 2
            error('Each pair must have 2 numbers: [channel, cluster]');
        end
    catch
        msgbox('Invalid channel-cluster format. Use [chan,cluster],[chan,cluster],...','Error','error');
        return;
    end
else
    % treat as cluster-only list
    try
        clusterOnly = eval(['[' userInput ']']);
    catch
        msgbox('Invalid cluster format. Use comma-separated numbers, e.g., 3,5','Error','error');
        return;
    end
end
%% Get selected ports
idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

%% Loop through selected ports
for s = 1:size(selected,1)
    expIdx = selected(s,1);
    portIdx = selected(s,2);

    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    waveforms_all = results.spike_results(portIdx).waveforms_all;

    %% Apply cluster-only exclusion
    if ~isempty(clusterOnly)
        waveforms_all = waveforms_all(~ismember([waveforms_all.clusters], clusterOnly));
    end

    %% Apply channel-cluster pair exclusion
    if ~isempty(channelClusterPairs)
        for k = 1:size(channelClusterPairs,1)
            chID = channelClusterPairs(k,1);
            clsID = channelClusterPairs(k,2);
            mask = ~([waveforms_all.clusters]==clsID & [waveforms_all.channel]==chID);
            waveforms_all = waveforms_all(mask);
        end
    end

    % Update results
    results.spike_results(portIdx).waveforms_all = waveforms_all;
    results.spike_results(portIdx).set = spike_feats_callback(h); % recompute spike features

    % Save back
    if iscell(h.figure.UserData)
        allResults = h.figure.UserData;
        allResults{expIdx} = results;
        set(h.figure,'UserData',allResults);
    else
        set(h.figure,'UserData',results);
    end
end

%% Refresh cluster plots
plot_cluster_callback(h);

end