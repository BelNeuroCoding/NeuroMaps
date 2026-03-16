function plot_all_spikes(h)
    aggregate_spikes(h)
    h = guidata(h.figure);

    % Collect all selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);
    all_waveforms     = h.cumulative_spikes.all_waveforms;
    all_channels      = h.cumulative_spikes.channels;
    spike_origin_p    = h.cumulative_spikes.spike_origin_p;
    spike_origin_e    = h.cumulative_spikes.spike_origin_e;

    % Calculate total tiles
    unique_combos = unique([spike_origin_e, spike_origin_p, all_channels], 'rows');
    total_tiles = size(unique_combos,1);

    % Delete old panel if exists
    if isfield(h,'spikesPanel') && isvalid(h.spikesPanel)
        delete(h.spikesPanel);
    end

    % Create a new panel inside your GUI tab/container
    togglePos = get(h.spikes_tab,'Position');  % example parent
    panelHeight = 0.88;   % 90% of parent height
    panelBottom = 0.05;  % leave 5% padding
    if ~isfield(h,'spikesPanel') || ~isvalid(h.spikesPanel)
    h.spikesPanel = uipanel('Parent', h.assess_spike_groups, ...
                            'Units','normalized', ...
                            'Position',[0, panelBottom, 1, panelHeight], ...
                            'BackgroundColor',[1 1 1], ...
                            'Title','Spike Waveforms');
    end
    % Clear old axes inside the panel
    existingAxes = findall(h.spikesPanel,'Type','axes');
    delete(existingAxes);

    % Tiled layout inside the panel
    nRows = ceil(sqrt(total_tiles));
    nCols = ceil(total_tiles/nRows);
    t = tiledlayout(h.spikesPanel, nRows, nCols, 'TileSpacing','compact','Padding','compact');

    h.spikes_axes = gobjects(total_tiles,1);

    for i = 1:total_tiles
        expIdx  = unique_combos(i,1);
        portIdx = unique_combos(i,2);
        chan    = unique_combos(i,3);

        sel_idx = find(spike_origin_e==expIdx & spike_origin_p==portIdx & all_channels==chan);
        mean_wf = mean(all_waveforms(sel_idx,:),1);
        std_wf  = std(all_waveforms(sel_idx,:),1);

        ax = nexttile(t);
        h.spikes_axes(i) = ax;

        hold(ax,'on');
        x = linspace(-1,1,200);
        plot(ax, x, mean_wf,'k','LineWidth',2);
        fill(ax, [x fliplr(x)], [mean_wf+std_wf fliplr(mean_wf-std_wf)], ...
             'b','FaceAlpha',0.3,'EdgeColor','none');
        hold(ax,'off');

        % Get port ID safely
        if iscell(h.figure.UserData)
            results = h.figure.UserData;
        else
            results = {h.figure.UserData};
        end
        title(ax, sprintf('P %d, C %d, E %d', results{expIdx}.ports(portIdx).port_id, chan, expIdx));
        axis(ax,'off'); box(ax,'off');
    end

    sgtitle(h.assess_spike_groups,'Port | Channel | Experiment');
    guidata(h.figure,h);
end
