function plot_corr_vs_distance(h, sttc_matrix, x_coords, y_coords, unique_channels, highCorrThresh, medCorrThresh,um_per_px)
    set_status(h.figure,"loading","Plotting Network Correlation/Distance...");
    num_channels = length(unique_channels);
    combins = nchoosek(1:num_channels, 2);
    for k=1:length(combins)
        i = combins(k,1); 
        j = combins(k,2); 
        distance = sqrt((x_coords(unique_channels(i)+1) - x_coords(unique_channels(j)+1))^2 + (y_coords(unique_channels(i)+1) - y_coords(unique_channels(j)+1))^2); 
        distanceMatrix(i,j) = distance*um_per_px; distanceMatrix(j,i) = distance*um_per_px; 
        corrMatrix(i,j) = sttc_matrix(i,j); corrMatrix(j,i) = sttc_matrix(i,j);
    end

    distanceMatrix(logical(eye(size(distanceMatrix)))) = NaN; 
    corrMatrix(logical(eye(size(corrMatrix)))) = NaN; 
    distAndCorr = [distanceMatrix(:), corrMatrix(:)]; 
    h.network_connectivity_summary = subplot(1,1,1,'Parent',h.nwcorr_tab);
    hold on
    % find high correlation distacne: > 0.8 
    distAndHighCorr = distAndCorr(distAndCorr(:, 2) >= highCorrThresh, 1); 
    % find medium correlation distances: 0.4 - 0.8 
    distAndMedCorr = distAndCorr(distAndCorr(:, 2) >= medCorrThresh & distAndCorr(:, 2) < highCorrThresh, 1); 
    % find low correlation distances: < 0.4 
    distAndLowCorr = distAndCorr(distAndCorr(:, 2) < medCorrThresh, 1);
    hHigh = plot_hist_by_corr(distAndHighCorr, [31, 120, 180] / 255);
    hMed  = plot_hist_by_corr(distAndMedCorr,  [178, 223, 138] / 255);
    hLow  = plot_hist_by_corr(distAndLowCorr,  [166, 206, 227] / 255);
    
    handles = [];
    labels  = {};
    
    if ~isempty(hLow)
        handles(end+1) = hLow;
        labels{end+1} = 'Low';
    end
    if ~isempty(hMed)
        handles(end+1) = hMed;
        labels{end+1} = 'Medium';
    end
    if ~isempty(hHigh)
        handles(end+1) = hHigh;
        labels{end+1} = 'High';
    end
    
    if ~isempty(handles)
        legend(handles, labels, ...
            'Orientation','horizontal', ...
            'Location','southoutside');
    end
    xlabel(h.network_connectivity_summary,'Distance (\mum)');
    ylabel(h.network_connectivity_summary,'Number of Connections');
    title(h.network_connectivity_summary,'Correlation vs Distance Based on STTC')
    set(h.network_connectivity_summary,'TickDir','out')
    axis square; box off; set(h.network_connectivity_summary,'Color','none');
    tb_corr = axtoolbar(h.network_connectivity_summary,{'save','zoomin','zoomout','restoreview','pan'});
    axtoolbarbtn(tb_corr, 'push', ...
    'Icon','export_data_icon.png',...
    'Tooltip',         'Export to CSV', ...
    'ButtonPushedFcn', @(~,~) export_axes_to_csv(h.network_connectivity_summary, 'correlation'));
    
    set_status(h.figure,"ready","Plotting Network Correlation/Distance...");

end

function hfit = plot_hist_by_corr(distVals, col)
    numbins = 15; 
    fitmethod = 'gamma';

    hfit = [];

    if any(distVals)
        h = histfit(distVals, numbins, fitmethod, 'Color', col);
        set(h(2),'Color',col)   % fitted curve
        delete(h(1))            % remove histogram bars
        hold on
        hfit = h(2);            % return line handle
    end
end