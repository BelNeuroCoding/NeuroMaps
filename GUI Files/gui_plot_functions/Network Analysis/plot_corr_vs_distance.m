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
    h.network_connectivity_summary = subplot(1,2,2,'Parent',h.nc_tab);
    hold on
    % find high correlation distacne: > 0.8 
    distAndHighCorr = distAndCorr(distAndCorr(:, 2) >= highCorrThresh, 1); 
    plot_hist_by_corr(distAndHighCorr, [31, 120, 180] / 255);
    % find medium correlation distances: 0.4 - 0.8 
    distAndMedCorr = distAndCorr(distAndCorr(:, 2) >= medCorrThresh & distAndCorr(:, 2) < highCorrThresh, 1); 
    plot_hist_by_corr(distAndMedCorr, [178, 223, 138] / 255);
    % find low correlation distances: < 0.4 
    distAndLowCorr = distAndCorr(distAndCorr(:, 2) < medCorrThresh, 1);
    plot_hist_by_corr(distAndLowCorr, [166, 206, 227] / 255);

    xlabel('Distance (\mum)');
    ylabel('Number of Connections');
    axis square; box off; set(gca,'Color','none');
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    set_status(h.figure,"loading","Plotting Network Correlation/Distance...");

end

function plot_hist_by_corr(distVals, col)
    numbins = 15; fitmethod = 'gamma';

    if any(distVals)
        h = histfit(distVals,numbins,fitmethod,'Color',col); 
        set(h(2),'Color',col)
        delete(h(1))
        hold on
    end

    legend({'Low','Medium','High'}, 'Location','southoutside');
end
