function cluster_all_spikes(h)
    h = guidata(h.figure);
    set_status(h.figure,"loading","Clustering All Spikes...");
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
    h.clustplot_panel = uipanel('Parent', h.cluster_spike_groups, ...
    'Units','normalized', ...
    'Position',[0 0.1 1 0.9], ...
    'BackgroundColor', backgdcolor, ...
    'BorderType','none');
    cluster_labels = arrayfun(@(k) sprintf('Cluster %d', k), unique(cluster_idx),'UniformOutput',false);
    if isfield(h,'cluster_listbox') && ishandle(h.cluster_listbox)
        delete(h.cluster_listbox)
    end
    h.cluster_listbox = uicontrol('Parent', h.clustplot_panel, ...
                              'Style','listbox', ...
                              'String', cluster_labels, ...
                              'Max',10, ...
                              'Min',1,... % allow multi-select
                              'Units','normalized', ...
                              'Position',[0.85 0.2 0.15 0.2], ...
                              'BackgroundColor',[1 1 1]); 
    guidata(h.figure,h);
    set_status(h.figure,"ready","Clustering Complete...");

    plot_all_clusters(h);


end

