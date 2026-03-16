function nwcorr_callback(h)
 %  Load probe map (coords etc.)
    [x_coords, y_coords, maps,um_per_px] = load_probe_map(h);

    %  Get thresholds from user
    dtv = str2double(get(h.dt_window,'String'));
    min_corr = str2double(get(h.min_corr,'String'));
    sr_thresh = str2double(get(h.sr_thresh,'String'));
    corrThresh = str2num(get(h.hm_thresh,'String'));
    
    highCorrThresh = corrThresh(1);  % e.g., 0.8
    medCorrThresh  = corrThresh(2);  % e.g., 0.4

    %  Compute STTC & latency if not cached
   compute_sttc_latency(h, dtv);
   [results, selected_idx, unique_channels, sttc_matrix, latency_matrix] = get_network_results(h);

    %  Plot distance vs correlation histograms
    plot_corr_vs_distance(h, sttc_matrix, x_coords, y_coords, unique_channels,highCorrThresh, medCorrThresh,um_per_px);

end