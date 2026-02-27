function plot_individual_cluster_waveforms(mean_waveforms, mean_stdev,fs,  mean_fwhm, num_spikes, title_text, clusters_eliminated,channels_per_cluster)
    % Check for eliminated clusters
    if nargin < 7
        clusters_eliminated = [];
        channels_per_cluster = [];
    end

    % Number of clusters
    numClusters = size(mean_waveforms, 1);
    cluster_colors = lines(numClusters); % Generate unique colors for clusters

    % Determine subplot grid layout
    numRows = ceil(sqrt(numClusters));
    numCols = ceil(numClusters / numRows);
    indices = 1:size(mean_waveforms,2);
    mean_waveforms = mean_waveforms(:,indices);
    mean_stdev = mean_stdev(:,indices);
    % Time vector for waveforms
    num_samples = size(mean_waveforms, 2);
    time_ms = ((1:num_samples) - (num_samples + 1) / 2) * (1000 / fs);


%    figure('Color', 'w'); % Set background to white

    for i = 1:numClusters
        if ismember(i, clusters_eliminated)
            continue; % Skip eliminated clusters
        end

        subplot(numRows, numCols, i); % Create subplot for each cluster
        hold on;

        % Extract mean and std waveforms
        mean_waveform = mean_waveforms(i, :);
        std_waveform = mean_stdev(i, :);

        % Define the color for the cluster
        color_idx = mod(i - 1, size(cluster_colors, 1)) + 1;
        cluster_color = cluster_colors(color_idx, :);

        % Plot the mean waveform
        plot(time_ms, mean_waveform, 'Color', cluster_color, 'LineWidth', 1.5);

        % Add shaded area for standard deviation
        fill([time_ms, fliplr(time_ms)], ...
             [mean_waveform + std_waveform, fliplr(mean_waveform - std_waveform)], ...
             cluster_color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        ymax = ceil(max(mean_waveform(:)) / 50) * 50;
        ymin = floor(min(mean_waveform(:)) / 50) * 50;
        % Axis formatting
        ylim([ymin ymax]);
        xlim([min(time_ms), max(time_ms)]);
        xticks(linspace(min(time_ms), max(time_ms), 5)); % More x ticks
        %yticks([ymin:10:ymax]); % More y ticks
        xlabel('Time (ms)', 'FontSize', 10);
        ylabel('Amplitude (\muV)', 'FontSize', 10);
        %grid minor
        set(gca, 'FontSize', 9, 'Box', 'off', 'LineWidth', 1);
        set(gca, 'TickDir', 'out');

        if nargin>3
        % Display FWHM and Spike Rate in the title
            chan_str = sprintf('%d, ', channels_per_cluster{i});
            chan_str = chan_str(1:end-2);  % Remove trailing comma and space
            
            title(sprintf('Cluster %d\nFWHM: %.2f ms | N: %.0f | Chans: %s', ...
                i, mean_fwhm(i), num_spikes(i), chan_str), 'FontSize', 9);

        end

        pbaspect([2 1 1]); % Adjust aspect ratio
       
    end
    set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);
            if nargin>3

    sgtitle(title_text, 'FontSize', 12, 'FontWeight', 'bold'); % Global title
            end
end
