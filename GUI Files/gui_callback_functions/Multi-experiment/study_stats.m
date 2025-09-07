function study_stats(h)
    h = guidata(h.figure); 
    if ~isfield(h,'cumulative_spikes') || isempty(h.cumulative_spikes.all_waveforms)
        errordlg('No cumulative spike data available. Run aggregation first.');
        return;
    end

    cs = h.cumulative_spikes;

    % Ask user for metric(s)
    metrics = {'Spike Rate','Burst Rate','FWHM','Peak-to-Peak Amplitude','Synchrony',...
        'Impedance','Capacitance','Aperiodic Offset','Aperiodic Exponent','Number of Active Channels'};
    [idx, ok] = listdlg('PromptString','Select metrics to plot:', ...
        'SelectionMode','multiple','ListString',metrics);
    if ~ok, return; end
    metric_names = metrics(idx); 
    nMetrics = numel(metric_names);

    group_name = 'Experiment/Port';

    % Ask user if they want statistics
    statChoice = questdlg('Compute statistics?', 'Statistics', ...
        'No','Kruskal-Wallis','Pairwise t-tests','No');
    if isempty(statChoice) || strcmp(statChoice,'No')
        computeStats = false; statMethod = '';
    else
        computeStats = true; statMethod = statChoice; % 'Kruskal-Wallis' or 'Pairwise t-tests'
    end

    % Default burst/synchrony params
    burstParams.min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
    burstParams.isi_threshold = str2double(get(h.burst_param(1),'String'));
    burstParams.min_burst_duration = str2double(get(h.burst_param(3),'String'));
    burstParams.min_active_channels = str2double(get(h.burst_param(4),'String'));

    combos = unique([cs.spike_origin_e, cs.spike_origin_p], 'rows');
    nGroups = size(combos,1);
    group_ids = combos;
    labels = arrayfun(@(k) sprintf('E%d-P%d', combos(k,1), h.figure.UserData{combos(k,1)}.ports(combos(k,2)).port_id), 1:nGroups, 'UniformOutput', false);

    % Plotting layout
    if isfield(h,'stats_axes') && ~isempty(h.stats_axes)
        delete(h.stats_axes(ishandle(h.stats_axes)));
    end
    h.stats_axes = gobjects(0);
    nRows = ceil(sqrt(nMetrics));
    nCols = ceil(nMetrics/nRows);
    t = tiledlayout(h.group_stats,nRows,nCols,'TileSpacing','compact','Padding','compact');

    % Loop over metrics
    for m = 1:nMetrics
        metric_name = metric_names{m};
        data_for_plot = cell(nGroups,1);

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
            capacitance = cs.capacitance(mask_spec); aperiodic_exp = cs.exponent(mask_spec); 
            aperiodic_off = cs.offset(mask_spec); chans_spec = cs.spec_chans(mask_spec);

            switch metric_name
                case 'Spike Rate'
                    vals = arrayfun(@(ch) sum(chans==ch)/duration_sec, unique_chans);
                    data_for_plot{g} = vals;
                case 'FWHM'
                    vals = arrayfun(@(ch) mean(fwhm(chans==ch)), unique_chans);
                    data_for_plot{g} = vals;
                case 'Peak-to-Peak Amplitude'
                    vals = arrayfun(@(ch) mean(ptp(chans==ch)), unique_chans);
                    data_for_plot{g} = vals;
                case 'Burst Rate'
                    vals = nan(size(unique_chans));
                    for ci = 1:numel(unique_chans)
                        st = sort(spike_times(chans==unique_chans(ci)));
                        bursts = detect_bursts_mod(st, burstParams.isi_threshold, burstParams.min_spikes_per_burst, burstParams.min_burst_duration);
                        vals(ci) = numel(bursts)/duration_sec;
                    end
                    data_for_plot{g} = vals;
                case 'Synchrony'
                    if numel(unique_chans) > burstParams.min_active_channels
                        max_spikes = sum(mask);
                        spikes_mat = NaN(max_spikes, numel(unique_chans));
                        for c = 1:numel(unique_chans)
                            st = spike_times(chans==unique_chans(c));
                            spikes_mat(1:numel(st), c) = st;
                        end
                        [Synch,~] = SpikeContrast(spikes_mat, duration_sec);
                        data_for_plot{g} = Synch;
                    else
                        data_for_plot{g} = NaN;
                    end
                case 'Impedance'
                    impedance(impedance>1000) = 1000;
                    data_for_plot{g} = impedance;
                case 'Capacitance', data_for_plot{g} = capacitance;
                case 'Aperiodic Offset', data_for_plot{g} = aperiodic_off;
                case 'Aperiodic Exponent', data_for_plot{g} = aperiodic_exp;
                case 'Number of Active Channels', data_for_plot{g} = length(unique_chans);
            end
        end

        % Plot one tile
        ax = nexttile(t); hold(ax,'on');
        colors = lines(nGroups);
        plot_box_per_group(ax, data_for_plot, colors, lab);
        set(ax,'XTick',1:nGroups,'XTickLabel',labels,'XTickLabelRotation',45);
        ylabel(ax, lab); box(ax,'off'); hold(ax,'on');

        % Compute and overlay statistics
        if computeStats
            all_values = []; group_vec = [];
            for g = 1:nGroups
                vals = data_for_plot{g};
                all_values = [all_values; vals(:)];
                group_vec = [group_vec; g*ones(numel(vals),1)];
            end
            if length(all_values)>2 && nGroups>1
                switch statMethod
                    case 'Kruskal-Wallis'
                        [p,~,stats] = kruskalwallis(all_values, group_vec,'off');
                        c = multcompare(stats, 'Display','off');
                        ylims = [0 max(all_values(:))]; yspan = ylims(2)-ylims(1); offset_step = 0.05*yspan;
                        y_offsets = zeros(size(c,1),1);
                        for k = 1:size(c,1)
                            g1=c(k,1); g2=c(k,2); p_pair=c(k,6);
                            if isempty(data_for_plot{g1}) || isempty(data_for_plot{g2}), continue; end
                            if p_pair < 0.001, star='***'; elseif p_pair < 0.01, star='**'; elseif p_pair < 0.05, star='*'; else star=''; end
                            y_offsets(k) = ylims(2)+offset_step+k*offset_step;
                            if ~isempty(star)
                                plot(ax,[g1 g2],y_offsets(k)*[1 1],'k-','LineWidth',1.5);
                                text(mean([g1 g2]),y_offsets(k)+0.01*yspan,star,'HorizontalAlignment','center','FontSize',14,'Color','r');
                            end
                        end
                        if any(y_offsets), ylim(ax,[0 max(y_offsets)*1.05]); end
                    case 'Pairwise t-tests'
                        combs = nchoosek(1:nGroups,2); ylims=[0 max(all_values(:))]; yspan=ylims(2)-ylims(1);
                        for k = 1:size(combs,1)
                            g1=combs(k,1); g2=combs(k,2);
                            [~,p_pair] = ttest2(data_for_plot{g1},data_for_plot{g2});
                            if p_pair<0.001, star='***'; elseif p_pair<0.01, star='**'; elseif p_pair<0.05, star='*'; else star=''; end
                            y_offsets(k) = ylims(2)+0.05*yspan+0.05*k*yspan;
                            if ~isempty(star)
                                plot(ax,[g1 g2],y_offsets(k)*[1 1],'k-','LineWidth',1.5);
                                text(mean([g1 g2]),y_offsets(k)+0.01*yspan,star,'HorizontalAlignment','center','FontSize',14,'Color','r');
                            end
                        end
                        if any(y_offsets), ylim(ax,[0 max(y_offsets)*1.05]); end
                end
            end
        end
        axtoolbar({'save','zoomin','zoomout','restoreview','pan'}); hold(ax,'off');
    end
end