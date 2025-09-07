function plot_all_spikes(h)
    aggregate_spikes(h)
    h = guidata(h.figure);

    % Collect all selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);
    labels = h.portList.String(idx);
    all_waveforms     = h.cumulative_spikes.all_waveforms;
    all_channels      = h.cumulative_spikes.channels;
    spike_origin_p    = h.cumulative_spikes.spike_origin_p;
    spike_origin_e    = h.cumulative_spikes.spike_origin_e;
    all_fwhm          = h.cumulative_spikes.fwhm;
    all_ptp_amplitude = h.cumulative_spikes.ptp_amplitude;

    % Calculate total tiles
    unique_combos = unique([spike_origin_e, spike_origin_p, all_channels], 'rows');
    total_tiles = size(unique_combos,1);
    
    % Delete old axes
    if isfield(h,'spikes_axes') && ~isempty(h.spikes_axes)
        delete(h.spikes_axes(ishandle(h.spikes_axes)));
    end
    h.spikes_axes = gobjects(0);
    
    % Determine rows and cols
    nRows = ceil(sqrt(total_tiles));
    nCols = ceil(total_tiles/nRows);
    
    tile_counter = 1;
    
    % Plot each (exp × port × channel)
    
    unique_combos = unique([spike_origin_e, spike_origin_p, all_channels], 'rows');
    
    for i = 1:size(unique_combos,1)
        expIdx = unique_combos(i,1);
        portIdx = unique_combos(i,2);
        chan = unique_combos(i,3);
    
        sel_idx = find(spike_origin_e==expIdx & spike_origin_p==portIdx & all_channels==chan);
        mean_wf = mean(all_waveforms(sel_idx,:),1);
        std_wf = std(all_waveforms(sel_idx,:),1);
    
        h.spikes_axes(tile_counter) = subplot(nRows,nCols,tile_counter,'Parent',h.assess_spike_groups);
        plot(linspace(-1,1,200), mean_wf,'k','LineWidth',2); hold on;
        fill([linspace(-1,1,200) fliplr(linspace(-1,1,200))], ...
             [mean_wf+std_wf fliplr(mean_wf-std_wf)], 'b','FaceAlpha',0.3,'EdgeColor','none');
        hold off;

        if size(unique_combos)<2
            results = {h.figure.UserData};
        else
            results = h.figure.UserData;
        end
    
        title(sprintf('P %d, C %d, E %d', results{expIdx}.ports(portIdx).port_id, chan, expIdx));
        axis off; box off;
    
        tile_counter = tile_counter + 1;
    end
    
    sgtitle(h.assess_spike_groups,'Port | Channel | Experiment');
    guidata(h.figure, h);

end