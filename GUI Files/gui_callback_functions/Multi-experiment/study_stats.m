function study_stats(h)
    warning('off', 'all');
    set_status(h.figure,"loading","Loading Data for Comparisons...");

    h = guidata(h.figure); 
    if ~isfield(h,'cumulative_spikes') || ...
       ~isfield(h.cumulative_spikes,'all_waveforms') || ...
       isempty(h.cumulative_spikes.all_waveforms)
        errordlg('No cumulative spike data available. Run aggregation first.');
        return;
    end

    cs = h.cumulative_spikes;
    combos = unique([cs.spike_origin_e, cs.spike_origin_p], 'rows');
    nGroups = size(combos,1);
    group_ids = combos;
    labels = arrayfun(@(k) sprintf('E%d-P%d', combos(k,1), h.figure.UserData{combos(k,1)}.ports(combos(k,2)).port_id), 1:nGroups, 'UniformOutput', false);

    % Clear previous axes/panel
    if isfield(h,'stats_axes') && ~isempty(h.stats_axes)
        delete(h.stats_axes(ishandle(h.stats_axes)));
    end
    h.stats_axes = gobjects(0);

    % Map metrics to data fields
    metricMap = { ...
        'Spike Rate',             'spike_times'; ...
        'Burst Rate',             'spike_times'; ...
        'FWHM',                   'fwhm'; ...
        'Peak-to-Peak Amplitude', 'ptp_amplitude'; ...
        'Synchrony',              'spike_times'; ...
        'Impedance',              'impedance'; ...
        'Capacitance',            'capacitance'; ...
        'Aperiodic Offset',       'offset'; ...
        'Aperiodic Exponent',     'exponent'; ...
        'Number of Active Channels','channels' ...
    };

    % Filter available metrics
    availableMetrics = {};
    for i = 1:size(metricMap,1)
        if isfield(cs, metricMap{i,2}) && ~isempty(cs.(metricMap{i,2}))
            availableMetrics{end+1} = metricMap{i,1}; %#ok<AGROW>
        end
    end
    if isempty(availableMetrics)
        errordlg('No valid metrics found in cumulative_spikes.');
        return;
    end

    % Ask user which metrics to plot
    [idx, ok] = listdlg('PromptString','Select metrics to plot:', ...
                        'SelectionMode','multiple', 'ListString',availableMetrics);
    if ~ok, return; end
    metric_names = availableMetrics(idx);
    nMetrics = numel(metric_names);

    % Ask about statistics
    statChoice = questdlg('Compute statistics?', 'Statistics', 'No','Kruskal-Wallis','Pairwise t-tests','No');
    if isempty(statChoice) || strcmp(statChoice,'No')
        computeStats = false; statMethod = '';
    else
        computeStats = true; statMethod = statChoice;
    end

    % Burst/Synchrony params
    burstParams = [];
    if any(strcmp(metric_names, 'Burst Rate')) || any(strcmp(metric_names,'Synchrony'))
        burstParams.min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
        burstParams.isi_threshold = str2double(get(h.burst_param(1),'String'));
        burstParams.min_burst_duration = str2double(get(h.burst_param(3),'String'));
        burstParams.min_active_channels = str2double(get(h.burst_param(4),'String'));
    end

    % Layout panel
    nRows = ceil(sqrt(nMetrics));
    nCols = ceil(nMetrics/nRows);
    if isfield(h,'statsPanel') && isvalid(h.statsPanel)
        delete(h.statsPanel);
    end
    panelHeight = 0.9; panelBottom = 0.1;
    h.statsPanel = uipanel('Parent', h.group_stats, ...
                            'Units','normalized', ...
                            'Position',[0, panelBottom, 1, panelHeight], ...
                            'BackgroundColor',[1 1 1]);
    t = tiledlayout(h.statsPanel,nRows,nCols,'TileSpacing','compact','Padding','compact');

    % Loop over metrics
    for m = 1:nMetrics
        metric_name = metric_names{m};
        data_for_plot = cell(nGroups,1);

        % Axis label
        switch metric_name
            case 'Spike Rate', lab = 'Spike Rate (Hz)';
            case 'Burst Rate', lab = 'Burst Rate (Hz)';
            case 'FWHM', lab = 'FWHM (ms)';
            case 'Peak-to-Peak Amplitude', lab = 'Pk-to-pk Amplitude (\muV)';
            case 'Synchrony', lab = 'Synchrony index';
            case 'Impedance', lab = 'Impedance (k\Omega)';
            case 'Capacitance', lab = 'Capacitance (nF)';
            case 'Aperiodic Offset', lab = 'Aperiodic Offset (\muV)';
            case 'Aperiodic Exponent', lab = 'Aperiodic Exponent';
            case 'Number of Active Channels', lab = 'Number of Active Channels';
        end

        % Collect data per group
        for g = 1:nGroups
            mask = cs.spike_origin_e==group_ids(g,1) & cs.spike_origin_p==group_ids(g,2);
            mask_spec = cs.spec_e==group_ids(g,1) & cs.spec_p==group_ids(g,2);

            chans = cs.channels(mask); tstamp = cs.rec_time(mask); fwhm = cs.fwhm(mask);
            ptp = cs.ptp_amplitude(mask); spike_times = cs.spike_times(mask); unique_chans = unique(chans);
            duration_sec = unique(tstamp); impedance = cs.impedance(mask_spec);
            chans_spec = cs.spec_chans(mask_spec);

            switch metric_name
                case 'Spike Rate'
                    vals = arrayfun(@(ch) sum(chans==ch)/duration_sec, unique_chans);
                case 'FWHM'
                    vals = arrayfun(@(ch) mean(fwhm(chans==ch)), unique_chans);
                case 'Peak-to-Peak Amplitude'
                    vals = arrayfun(@(ch) mean(ptp(chans==ch)), unique_chans);
                case 'Burst Rate'
                    vals = nan(size(unique_chans));
                    for ci = 1:numel(unique_chans)
                        st = sort(spike_times(chans==unique_chans(ci)));
                        bursts = detect_bursts_mod(st, burstParams.isi_threshold, burstParams.min_spikes_per_burst, burstParams.min_burst_duration);
                        vals(ci) = numel(bursts)/duration_sec;
                    end
                case 'Synchrony'
                    if numel(unique_chans) > burstParams.min_active_channels
                        max_spikes = sum(mask);
                        spikes_mat = NaN(max_spikes, numel(unique_chans));
                        for c = 1:numel(unique_chans)
                            st = spike_times(chans==unique_chans(c));
                            spikes_mat(1:numel(st), c) = st;
                        end
                        [Synch,~] = SpikeContrast(spikes_mat, duration_sec);
                        set_status(h.figure,"loading","Computing Synchrony. Please be patient...");
                        vals = Synch;
                    else
                        vals = NaN;
                    end
                case 'Impedance'
                    impedance(impedance>1000) = 1000;
                    vals = impedance;
                case 'Capacitance'
                    vals = cs.capacitance(mask_spec);
                case 'Aperiodic Offset'
                    vals = length(mask_spec)==length(cs.offset) * cs.offset(mask_spec);
                case 'Aperiodic Exponent'
                    vals = length(mask_spec)==length(cs.exponent) * cs.exponent(mask_spec);
                case 'Number of Active Channels'
                    vals = length(unique_chans);
            end
            data_for_plot{g} = vals;
        end

        if any(cellfun(@isempty, data_for_plot))
            hDlg = warndlg(sprintf('Skipping %s: one or more groups have no data.',metric_name));
            pause(3);
            if ishandle(hDlg), close(hDlg); end
            continue
        end

        % Compute per-metric ylims
        all_vals = cell2mat(cellfun(@(x)x(:), data_for_plot, 'UniformOutput', false));
        all_vals = all_vals(~isnan(all_vals));
        if isempty(all_vals)
            ylims_base = [0 1];
        else
            ymin = min(all_vals); ymax = max(all_vals); yspan = max(ymax-ymin, eps);
            ylims_base = [ymin-0.1*yspan, ymax+0.2*yspan];
        end
        if strcmp(metric_name,'Synchrony'), ylims_base = [0 1]; end
        if strcmp(metric_name,'Impedance'), ylims_base(2) = min(ylims_base(2), 1000); end

        % Plot
        ax = nexttile(t); hold(ax,'on');
        colors = lines(nGroups);
        plot_box_per_group(ax, data_for_plot, colors, lab, ylims_base);
        set(ax,'XTick',1:nGroups,'XTickLabel',labels,'XTickLabelRotation',45);
        ylabel(ax, lab); box(ax,'off'); hold(ax,'on');

        % Overlay statistics
        if computeStats
            set_status(h.figure,"loading","Computing Stats...");
            all_values = []; group_vec = [];
            for g = 1:nGroups
                vals = data_for_plot{g};
                all_values = [all_values; vals(:)];
                group_vec = [group_vec; g*ones(numel(vals),1)];
            end
            if length(all_values)>2 && nGroups>1
                switch statMethod
                    case 'Kruskal-Wallis'
                        [~,~,stats] = kruskalwallis(all_values, group_vec,'off');
                        c = multcompare(stats,'Display','off');
                        yspan = diff(ylims_base);
                        y_offsets = zeros(size(c,1),1);
                        for k = 1:size(c,1)
                            g1=c(k,1); g2=c(k,2); p_pair=c(k,6);
                            if isempty(data_for_plot{g1}) || isempty(data_for_plot{g2}), continue; end
                            if p_pair < 0.001, star='***'; elseif p_pair < 0.01, star='**'; elseif p_pair < 0.05, star='*'; else star='n.s.'; end
                            y_offsets(k) = ylims_base(2) + 0.05*yspan + k*0.05*yspan;
                            plot(ax,[g1 g2],y_offsets(k)*[1 1],'k-','LineWidth',1.5);
                            text(mean([g1 g2]), y_offsets(k)+0.02*yspan, star,'HorizontalAlignment','center','Color','k');
                        end
                        if any(y_offsets), ylim(ax,[ylims_base(1) max(y_offsets)*1.05]); end
                    case 'Pairwise t-tests'
                        combs = nchoosek(1:nGroups,2); yspan = diff(ylims_base);
                        y_offsets = zeros(size(combs,1),1);
                        for k = 1:size(combs,1)
                            g1=combs(k,1); g2=combs(k,2);
                            [~,p_pair] = ttest2(data_for_plot{g1}, data_for_plot{g2});
                            if p_pair<0.001, star='***'; elseif p_pair<0.01, star='**'; elseif p_pair<0.05, star='*'; else star='n.s.'; end
                            y_offsets(k) = ylims_base(2)+0.08*yspan+0.05*k*yspan;
                            plot(ax,[g1 g2],y_offsets(k)*[1 1],'k-','LineWidth',1.5);
                            text(mean([g1 g2]), y_offsets(k)+0.02*yspan, star,'HorizontalAlignment','center','Color','k');
                        end
                        if any(y_offsets), ylim(ax,[ylims_base(1) max(y_offsets)*1.05]); end
                end
            end
        end
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'}); hold(ax,'off');
    end

    set_status(h.figure,"ready","Plotting Stats Complete...");
end