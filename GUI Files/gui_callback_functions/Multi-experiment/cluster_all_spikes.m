function cluster_all_spikes(h)
    h = guidata(h.figure);
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB

    if ~isfield(h,'cumulative_spikes') || isempty(h.cumulative_spikes.all_waveforms)
        errordlg('No aggregated spike data available. Run "Aggregate" first.');
        return;
    end

    % Extract aggregated data
    wf = h.cumulative_spikes.all_waveforms;

    initialize_random_seed();

    % Ask user to choose clustering mode
    mode_choice = questdlg('Choose clustering mode:', ...
                           'Clustering Method', ...
                           'PCA/KMEANS','GMM (Souza et al)',...
                           'PCA/KMEANS');

    if isempty(mode_choice)
        detected_clusters = [];
        return;
    elseif strcmp(mode_choice,'PCA/KMEANS')
           % Ask user for number of clusters
            answer = inputdlg('Enter number of clusters:', 'K-means Clustering', 1, {'5'});
            if isempty(answer), return; end
            nClusters = str2double(answer{1});       
            %  PCA 
            wf_norm = (wf - mean(wf,2)) ./ std(wf,[],2);
            [~, score, ~, ~, explained] = pca(wf_norm);
            nComponents = find(cumsum(explained) > 90, 1);
            reduced_data = score(:,1:nComponents);        
            % K-means clustering
            opts = statset('Display','final');
            [cluster_idx, C] = kmeans(reduced_data, nClusters, 'Replicates', 10, 'Options', opts);
    elseif strcmp(mode_choice,'GMM (Souza et al)')
            [cluster_idx,score,C] = ClusterDataGMM_MNG(wf);
    end

    % Save clustering info
    h.cumulative_spikes.cluster_idx = cluster_idx;
    h.cumulative_spikes.cluster_centers = C;
    h.cumulative_spikes.score = score;
    guidata(h.figure,h);
    plot_all_clusters(h);


end

