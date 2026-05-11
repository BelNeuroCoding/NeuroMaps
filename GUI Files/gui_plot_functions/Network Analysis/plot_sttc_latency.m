
function plot_sttc_latency(h, sttc_matrix, latency_matrix, unique_channels,titleStr)
    set_status(h.figure,"loading","Plotting STTC Matrix...");

    num_channels = length(unique_channels);
     if isfield(h,'sttc_panel') && isvalid(h.sttc_panel)
        delete(h.sttc_panel);
    end
    h.sttc_panel = uipanel(h.synchrony_tab, 'Units','normalized', 'Position',[0 0.1 1 0.9],'BackgroundColor',[1 1 1]); 
 
    % STTC heatmap
    h.sttc_axes = subplot(2,2,1,'Parent',h.sttc_panel);
    imagesc(h.sttc_axes, sttc_matrix);
    colormap(h.sttc_axes, jet); colorbar(h.sttc_axes);
    clim(h.sttc_axes, [0 1]); axis(h.sttc_axes,'square');
    xlabel('Channel'); ylabel('Channel'); title('STTC');
    tickStep = max(floor(num_channels/10),1);
    xticks(1:tickStep:num_channels); yticks(1:tickStep:num_channels);
    xticklabels(string(unique_channels(1:tickStep:end)));
    yticklabels(string(unique_channels(1:tickStep:end)));
    axtoolbar(h.sttc_axes, {'save','zoomin','zoomout','restoreview','pan'});
    set_status(h.figure,"loading","Plotting Latency Matrix...");

    % Latency heatmap
    h.latency_axes = subplot(2,2,2,'Parent',h.sttc_panel);
    imagesc(h.latency_axes, latency_matrix);
    colormap(h.latency_axes, jet); colorbar(h.latency_axes);
    axis(h.latency_axes,'square');
    xlabel('Channel'); ylabel('Channel'); title('Mean Latency (s)');
    tickStep = max(floor(num_channels/10),1);
    xticks(1:tickStep:num_channels); yticks(1:tickStep:num_channels);
    xticklabels(string(unique_channels(1:tickStep:end)));
    yticklabels(string(unique_channels(1:tickStep:end)));
    axtoolbar(h.latency_axes, {'save','zoomin','zoomout','restoreview','pan'});

    % STTC histogram
    h.sttc_hist_axes =subplot(2,2,3,'Parent',h.sttc_panel);
    histogram(h.sttc_hist_axes,sttc_matrix(~eye(num_channels)),20,'FaceColor','b');
    xlabel(h.sttc_hist_axes,'STTC'); ylabel(h.sttc_hist_axes,'Count'); title(h.sttc_hist_axes,'STTC Distribution');
    tb_sttc=axtoolbar(h.sttc_hist_axes, {'save','zoomin','zoomout','restoreview','pan'});
    axtoolbarbtn(tb_sttc, 'push', ...
    'Icon','export_data_icon.png',...
    'Tooltip',         'Export to CSV', ...
    'ButtonPushedFcn', @(~,~) export_axes_to_csv(h.sttc_hist_axes, 'sttc'));
    % Latency histogram
    h.lat_hist_axes = subplot(2,2,4,'Parent',h.sttc_panel);
    histogram(h.lat_hist_axes,latency_matrix(~eye(num_channels))*1000,20,'FaceColor','r');
    xlabel(h.lat_hist_axes,'Latency (ms)'); ylabel(h.lat_hist_axes,'Count'); title(h.lat_hist_axes,'Latency Distribution');
    tb_lat = axtoolbar(h.lat_hist_axes,{'save','zoomin','zoomout','restoreview','pan'});
    axtoolbarbtn(tb_lat, 'push', ...
    'Icon','export_data_icon.png',...
    'Tooltip',         'Export to CSV', ...
    'ButtonPushedFcn', @(~,~) export_axes_to_csv(h.lat_hist_axes, 'latency'));
    set_status(h.figure,"ready","STTC/Latency Matrices Complete...");
    if nargin>4
    sgtitle(titleStr)
    end
end
