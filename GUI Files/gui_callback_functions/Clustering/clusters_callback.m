function [clusters] = clusters_callback(h)

h = guidata(h.figure);  
% Get selected ports
idx = h.portList.Value;        % listbox indices
map = h.portList.UserData;     % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);

%  Handle multiple selections 
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


clusternum =str2double(get(h.clusternums_value,'String'));
initialize_random_seed();

% Ask user to choose clustering mode
mode_choice = questdlg('Choose clustering mode:', ...
                       'Clustering Method', ...
                       'PCA/KMEANS','PCA/GM', 'GMM (Souza et al)',...
                       'PCA/KMEANS');
tic
all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
X_scaled = zscore(double(all_waveforms),0,2);
if isempty(mode_choice)
    detected_clusters = [];
    return;
elseif strcmp(mode_choice,'PCA/KMEANS')
    [coeff,score,latent,tsquared,explained] = pca(X_scaled); % PCA Feature Extraction
    reduced_data = score(:,1:2);
    [clusters, centroid] = kmeans(reduced_data,clusternum);
    clust = num2cell(clusters);
  %  clusters = ClusterDataGMM_MNG([all_waveforms]);
elseif strcmp(mode_choice,'GMM (Souza et al)')
    clusters = ClusterDataGMM_MNG([all_waveforms]);
else
    [coeff,score,latent,tsquared,explained] = pca(X_scaled); % PCA Feature Extraction
    % Use enough components to explain a significant portion of variance
    explained_variance = 95; % in percentage
    num_components = find(cumsum(explained) >= explained_variance, 1);
    principal_components = score(:, 1:num_components);
    %principal_components = score;
    [~,s] = size(coeff);
    if s>1
    % Use enough components to explain a significant portion of variance
    gm = fitgmdist(principal_components, clusternum, 'CovarianceType', 'full', 'RegularizationValue', 0.01);
    clusters = cluster(gm, principal_components);
    end
end
total_time = toc;
fprintf('Total time for Clustering %.3f s',total_time)
clust = num2cell(clusters);
[waveforms_all.clusters] = deal(clust{:});
results.spike_results(selected_idx).waveforms_all = waveforms_all;

% Save updated results
if iscell(h.figure.UserData)
    allresults = h.figure.UserData;
    allresults{expIdx} = results;
    set(h.figure, 'UserData', allresults);
else
    set(h.figure, 'UserData', results);
end
guidata(h.figure);

results.spike_results(selected_idx).set = spike_feats_callback(h);
% Save updated results
if iscell(h.figure.UserData)
    allresults = h.figure.UserData;
    allresults{expIdx} = results;
    set(h.figure, 'UserData', allresults);
else
    set(h.figure, 'UserData', results);
end
guidata(h.figure);
plot_cluster_callback(h);
end