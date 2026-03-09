
function plot_sttc_latency(h, sttc_matrix, latency_matrix, unique_channels)
    set_status(h.figure,"loading","Plotting STTC Matrix...");

    num_channels = length(unique_channels);
    % STTC heatmap
    h.sttc_axes = subplot(2,2,1,'Parent',h.synchrony_tab);
    imagesc(h.sttc_axes, sttc_matrix);
    colormap(h.sttc_axes, jet); colorbar(h.sttc_axes);
    clim(h.sttc_axes, [0 1]); axis(h.sttc_axes,'square');
    xlabel('Channel'); ylabel('Channel'); title('STTC');
    xticks(1:num_channels); yticks(1:num_channels);
    xticklabels(string(unique_channels)); yticklabels(string(unique_channels));
    axtoolbar(h.sttc_axes, {'save','zoomin','zoomout','restoreview','pan'});
    set_status(h.figure,"loading","Plotting Latency Matrix...");

    % Latency heatmap
    h.latency_axes = subplot(2,2,2,'Parent',h.synchrony_tab);
    imagesc(h.latency_axes, latency_matrix);
    colormap(h.latency_axes, jet); colorbar(h.latency_axes);
    axis(h.latency_axes,'square');
    xlabel('Channel'); ylabel('Channel'); title('Mean Latency (s)');
    xticks(1:num_channels); yticks(1:num_channels);
    xticklabels(string(unique_channels)); yticklabels(string(unique_channels));
    axtoolbar(h.latency_axes, {'save','zoomin','zoomout','restoreview','pan'});

    % STTC histogram
    subplot(2,2,3,'Parent',h.synchrony_tab);
    histogram(sttc_matrix(~eye(num_channels)),20,'FaceColor','b');
    xlabel('STTC'); ylabel('Count'); title('STTC Distribution');
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

    % Latency histogram
    subplot(2,2,4,'Parent',h.synchrony_tab);
    histogram(latency_matrix(~eye(num_channels))*1000,20,'FaceColor','r');
    xlabel('Latency (ms)'); ylabel('Count'); title('Latency Distribution');
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    set_status(h.figure,"ready","STTC/Latency Matrices Complete...");

end
