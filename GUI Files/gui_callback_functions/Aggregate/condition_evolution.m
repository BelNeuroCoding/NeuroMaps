function condition_evolution(h)
% CONDITION_EVOLUTION - Plot replicate-level metrics grouped by experimental condition.
%
% Example grouping:
%   Exp1_Port1 -> Baseline, Replicate 1
%   Exp2_Port1 -> Baseline, Replicate 2
%   Exp1_Port2 -> KCl,      Replicate 1
%   Exp2_Port2 -> KCl,      Replicate 2
%
% Output:
%   Box/scatter plots where x-axis groups are conditions.
%   Each scatter point represents one Exp/Port replicate-level value.

warning('off','all');

h = guidata(h.figure);

% Safety checks
if ~isfield(h,'cumulative_spikes') || ...
   ~isfield(h.cumulative_spikes,'all_waveforms') || ...
   isempty(h.cumulative_spikes.all_waveforms)

    errordlg('No cumulative spike data available. Run aggregation first.');
    return;
end

cs = h.cumulative_spikes;

% Ask user for condition / replicate assignment
condition_info = get_condition_grouping(h);

if isempty(fieldnames(condition_info))
    errordlg('No condition grouping entered.');
    return;
end

% Statistics option
statChoice = questdlg('Compute statistics?', ...
    'Statistics', ...
    'No','Kruskal-Wallis','Pairwise t-tests','No');

computeStats = ~(isempty(statChoice) || strcmpi(statChoice,'No'));

if computeStats
    statMethod = statChoice;
else
    statMethod = '';
end

% Metric map
metricMap = { ...
    'Spike Rate',                'spike_times'; ...
    'Burst Rate',                'spike_times'; ...
    'FWHM',                      'fwhm'; ...
    'Peak-to-Peak Amplitude',    'ptp_amplitude'; ...
    'Synchrony',                 'spike_times'; ...
    'Impedance',                 'impedance'; ...
    'Capacitance',               'capacitance'; ...
    'Aperiodic Offset',          'offset'; ...
    'Aperiodic Exponent',        'exponent'; ...
    'Number of Active Channels', 'channels' ...
    };

availableMetrics = {};

for i = 1:size(metricMap,1)
    dispName = metricMap{i,1};
    fieldName = metricMap{i,2};

    if isfield(cs, fieldName) && ~isempty(cs.(fieldName))
        availableMetrics{end+1} = dispName; %#ok<AGROW>
    end
end

if isempty(availableMetrics)
    errordlg('No valid metrics found in cumulative_spikes.');
    return;
end

[idx, ok] = listdlg( ...
    'PromptString','Select metrics to plot:', ...
    'SelectionMode','multiple', ...
    'ListString',availableMetrics);

if ~ok
    return;
end

metrics = availableMetrics(idx);
nMetrics = numel(metrics);

% Burst parameters
burstParams = [];

if any(strcmp(metrics,'Burst Rate')) || any(strcmp(metrics,'Synchrony'))
    burstParams.min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
    burstParams.isi_threshold = str2double(get(h.burst_param(1),'String'));
    burstParams.min_burst_duration = str2double(get(h.burst_param(3),'String'));
    burstParams.min_active_channels = str2double(get(h.burst_param(4),'String'));
end

% Build selected Exp/Port map
idx_ports = h.portList.Value;
map = h.portList.UserData;
selected = map(idx_ports,:);

nCombos = size(selected,1);
exp_port_map = zeros(nCombos,2);

for k = 1:nCombos
    exp_port_map(k,1) = selected(k,1);
    exp_port_map(k,2) = selected(k,2);
end

% Assign each spike to an Exp/Port combo
nSpikes = numel(cs.spike_origin_e);
combo_idx = NaN(nSpikes,1);

for k = 1:nCombos
    mask = cs.spike_origin_e == exp_port_map(k,1) & ...
           cs.spike_origin_p == exp_port_map(k,2);

    combo_idx(mask) = k;
end

% -------------------------------------------------------------------------
% Exclude low-amplitude spikes
% -------------------------------------------------------------------------
if isfield(cs,'ptp_amplitude') && ~isempty(cs.ptp_amplitude)

    answer = inputdlg( ...
        {'Exclude spikes with peak-to-peak amplitude below:'}, ...
        'Spike amplitude threshold', ...
        [1 50], ...
        {'0'});

    if isempty(answer)
        return;
    end

    ampThreshold = str2double(answer{1});

    if isnan(ampThreshold)
        errordlg('Amplitude threshold must be numeric.');
        return;
    end

    ptp_vec = cs.ptp_amplitude(:);

    if numel(ptp_vec) ~= nSpikes
        errordlg('ptp_amplitude length does not match number of spikes.');
        return;
    end

    low_amp_mask = ptp_vec < ampThreshold;

    % Low-amplitude spikes are excluded from all spike-derived metrics by
    % invalidating their Exp/Port assignment.
    combo_idx(low_amp_mask) = NaN;

else
    warndlg('ptp_amplitude not found. No amplitude filtering applied.');
end

% Assign spectral rows to Exp/Port combo, if available
if isfield(cs,'spec_e') && isfield(cs,'spec_p')
    nSpec = numel(cs.spec_e);
    spec_combo_idx = NaN(nSpec,1);

    for k = 1:nCombos
        mask_spec = cs.spec_e == exp_port_map(k,1) & ...
                    cs.spec_p == exp_port_map(k,2);

        spec_combo_idx(mask_spec) = k;
    end
else
    nSpec = 0;
    spec_combo_idx = [];
end

% Build condition groups
grouping_fields = fieldnames(condition_info);
all_conditions = cell(numel(grouping_fields),1);

for i = 1:numel(grouping_fields)
    all_conditions{i} = condition_info.(grouping_fields{i}).condition;
end

group_labels = unique(all_conditions, 'stable');
nGroups = numel(group_labels);

group_idx = NaN(nSpikes,1);

for k = 1:nCombos
    fld = sprintf('Exp%d_Port%d', exp_port_map(k,1), exp_port_map(k,2));

    if ~isfield(condition_info, fld)
        continue;
    end

    cond = condition_info.(fld).condition;
    g = find(strcmp(group_labels, cond), 1);

    group_idx(combo_idx == k) = g;
end

if nSpec > 0
    group_spec_idx = NaN(nSpec,1);

    for k = 1:nCombos
        fld = sprintf('Exp%d_Port%d', exp_port_map(k,1), exp_port_map(k,2));

        if ~isfield(condition_info, fld)
            continue;
        end

        cond = condition_info.(fld).condition;
        g = find(strcmp(group_labels, cond), 1);

        group_spec_idx(spec_combo_idx == k) = g;
    end
else
    group_spec_idx = [];
end

if isfield(h,'group_expt_avg') && isvalid(h.group_expt_avg)
    delete(setdiff(allchild(h.group_expt_avg), h.group_expt_avg_button));
end

% Prepare layout
nRows = ceil(sqrt(nMetrics));
nCols = ceil(nMetrics / nRows);

t = tiledlayout(h.group_expt_avg, nRows, nCols, ...
    'TileSpacing','compact', ...
    'Padding','compact');

% Loop over metrics
for m = 1:nMetrics

    metric_name = metrics{m};
    group_data = cell(nGroups,1);

    for g = 1:nGroups

        group_combo_ids = [];

        for c = 1:nCombos
            fld = sprintf('Exp%d_Port%d', exp_port_map(c,1), exp_port_map(c,2));

            if ~isfield(condition_info, fld)
                continue;
            end

            cond = condition_info.(fld).condition;

            if strcmp(cond, group_labels{g})
                group_combo_ids(end+1,1) = c; %#ok<AGROW>
            end
        end

        vals = [];

        switch metric_name

            % Spike Rate
            % One value per Exp/Port replicate:
            % mean channel spike rate within that Exp/Port.
            case 'Spike Rate'

                for c = group_combo_ids(:)'

                    submask = combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    chans_c = cs.channels(submask);
                    dur_c = unique(cs.rec_time(submask));

                    if isempty(dur_c) || all(isnan(dur_c))
                        continue;
                    end

                    dur_c = dur_c(1);

                    uch = unique(chans_c);

                    channel_rates = arrayfun(@(ch) ...
                        sum(chans_c == ch) / dur_c, uch);

                    vals(end+1,1) = mean(channel_rates,'omitnan'); %#ok<AGROW>
                end

                group_data{g} = vals;

            % FWHM
            % One value per Exp/Port replicate:
            % mean channel-level FWHM.
            case 'FWHM'

                for c = group_combo_ids(:)'

                    submask = combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    chans_c = cs.channels(submask);
                    fwhm_c = cs.fwhm(submask);

                    uch = unique(chans_c);

                    channel_vals = arrayfun(@(ch) ...
                        mean(fwhm_c(chans_c == ch),'omitnan'), uch);

                    vals(end+1,1) = mean(channel_vals,'omitnan'); %#ok<AGROW>
                end

                group_data{g} = vals;

            % Peak-to-Peak Amplitude
            % One value per Exp/Port replicate:
            % mean channel-level PTP.
            case 'Peak-to-Peak Amplitude'

                for c = group_combo_ids(:)'

                    submask = combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    chans_c = cs.channels(submask);
                    ptp_c = cs.ptp_amplitude(submask);

                    uch = unique(chans_c);

                    channel_vals = arrayfun(@(ch) ...
                        mean(ptp_c(chans_c == ch),'omitnan'), uch);

                    vals(end+1,1) = mean(channel_vals,'omitnan'); %#ok<AGROW>
                end

                group_data{g} = vals;

            % Burst Rate
            % One value per Exp/Port replicate:
            % mean burst rate across active channels.
            case 'Burst Rate'

                if isempty(burstParams)
                    group_data{g} = [];
                    continue;
                end

                for c = group_combo_ids(:)'

                    submask = combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    chans_c = cs.channels(submask);
                    st_c = cs.spike_times(submask);
                    dur_c = unique(cs.rec_time(submask));

                    if isempty(dur_c) || all(isnan(dur_c))
                        continue;
                    end

                    dur_c = dur_c(1);
                    uch = unique(chans_c);

                    tmp = nan(size(uch));

                    for iCh = 1:numel(uch)
                        stc = sort(st_c(chans_c == uch(iCh)));

                        bursts = detect_bursts_mod( ...
                            stc, ...
                            burstParams.isi_threshold, ...
                            burstParams.min_spikes_per_burst, ...
                            burstParams.min_burst_duration);

                        tmp(iCh) = numel(bursts) / dur_c;
                    end

                    vals(end+1,1) = mean(tmp,'omitnan'); %#ok<AGROW>
                end

                group_data{g} = vals;

            % Synchrony
            % One value per Exp/Port replicate.
            case 'Synchrony'

                if isempty(burstParams)
                    group_data{g} = [];
                    continue;
                end

                for c = group_combo_ids(:)'

                    submask = combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    chans_c = cs.channels(submask);
                    st_c = cs.spike_times(submask);
                    dur_c = unique(cs.rec_time(submask));

                    if isempty(dur_c) || all(isnan(dur_c))
                        continue;
                    end

                    dur_c = dur_c(1);
                    uch = unique(chans_c);

                    if numel(uch) > burstParams.min_active_channels

                        maxSpikesPerChannel = max(arrayfun(@(ch) ...
                            sum(chans_c == ch), uch));

                        S = NaN(maxSpikesPerChannel, numel(uch));

                        for ii = 1:numel(uch)
                            sti = sort(st_c(chans_c == uch(ii)));
                            S(1:numel(sti), ii) = sti;
                        end

                        [Synch, ~] = SpikeContrast(S, dur_c);

                        vals(end+1,1) = Synch; %#ok<AGROW>
                    else
                        vals(end+1,1) = NaN; %#ok<AGROW>
                    end
                end

                group_data{g} = vals;

            % Spectral / electrical metrics
            % One value per Exp/Port replicate.
            case {'Impedance','Capacitance','Aperiodic Offset','Aperiodic Exponent'}

                if isempty(group_spec_idx)
                    group_data{g} = [];
                    continue;
                end

                switch metric_name
                    case 'Impedance'
                        vec = cs.impedance(:);
                    case 'Capacitance'
                        vec = cs.capacitance(:);
                    case 'Aperiodic Offset'
                        vec = cs.offset(:);
                    case 'Aperiodic Exponent'
                        vec = cs.exponent(:);
                end

                if numel(vec) ~= numel(spec_combo_idx)
                    group_data{g} = [];
                    continue;
                end

                for c = group_combo_ids(:)'

                    submask = spec_combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    val = mean(vec(submask), 'omitnan');

                    if strcmp(metric_name,'Impedance') && val > 1000
                        val = 1000;
                    end

                    vals(end+1,1) = val; %#ok<AGROW>
                end

                group_data{g} = vals;

            % Number of Active Channels
            % One value per Exp/Port replicate.
            case 'Number of Active Channels'

                for c = group_combo_ids(:)'

                    submask = combo_idx == c;

                    if ~any(submask)
                        continue;
                    end

                    vals(end+1,1) = numel(unique(cs.channels(submask))); %#ok<AGROW>
                end

                group_data{g} = vals;
        end
    end

    % Skip metric if one or more condition groups are empty
    if any(cellfun(@isempty, group_data))
        hDlg = warndlg(sprintf( ...
            'Skipping %s: one or more condition groups have no data.', ...
            metric_name));

        pause(3);

        if ishandle(hDlg)
            close(hDlg);
        end

        continue;
    end

    % ---------------------------------------------------------------------
    % Plot
    % ---------------------------------------------------------------------
    ax = nexttile(t);
    hold(ax,'on');

    colors = lines(nGroups);

    plot_box_per_group_condition(ax, group_data, group_labels, colors, metric_name);

    title(ax, metric_name, 'Interpreter','none');

    % Statistics overlay
    if computeStats

        all_values = [];
        group_vec = [];

        for g = 1:nGroups
            vals_g = group_data{g};

            all_values = [all_values; vals_g(:)]; %#ok<AGROW>
            group_vec = [group_vec; g * ones(numel(vals_g),1)]; %#ok<AGROW>
        end

        % Correct NaN filtering while preserving group alignment
        valid_stats = ~isnan(all_values);

        all_values = all_values(valid_stats);
        group_vec = group_vec(valid_stats);

        if numel(all_values) > 2 && nGroups > 1

            switch statMethod

                case 'Kruskal-Wallis'

                    [~,~,stats] = kruskalwallis(all_values, group_vec, 'off');
                    cstats = multcompare(stats, 'Display','off');

                    add_stat_annotations(ax, cstats, group_data);
                case 'Pairwise t-tests'
                
                    combs = nchoosek(1:nGroups,2);
                    cstats = NaN(size(combs,1),6);
                
                    for kk = 1:size(combs,1)
                
                        g1 = combs(kk,1);
                        g2 = combs(kk,2);
                
                        cond1 = group_labels{g1};
                        cond2 = group_labels{g2};
                
                        [vals1_paired, vals2_paired] = get_paired_values_by_replicate( ...
                            condition_info, exp_port_map, group_labels, cond1, cond2, ...
                            group_data, g1, g2);
                
                        valid_pair = ~isnan(vals1_paired) & ~isnan(vals2_paired);
                
                        vals1_paired = vals1_paired(valid_pair);
                        vals2_paired = vals2_paired(valid_pair);
                
                        if numel(vals1_paired) < 2
                            p_pair = NaN;
                        else
                            [~, p_pair] = ttest(vals1_paired, vals2_paired);
                        end
                
                        cstats(kk,1) = g1;
                        cstats(kk,2) = g2;
                        cstats(kk,6) = p_pair;
                    end
                
                    add_stat_annotations(ax, cstats, group_data);
                % case 'Pairwise t-tests'
                % 
                %     combs = nchoosek(1:nGroups,2);
                %     cstats = NaN(size(combs,1),6);
                % 
                %     for kk = 1:size(combs,1)
                %         g1 = combs(kk,1);
                %         g2 = combs(kk,2);
                % 
                %         vals1 = group_data{g1};
                %         vals2 = group_data{g2};
                % 
                %         vals1 = vals1(~isnan(vals1));
                %         vals2 = vals2(~isnan(vals2));
                % 
                %         if numel(vals1) < 2 || numel(vals2) < 2
                %             p_pair = NaN;
                %         else
                %             [~,p_pair] = ttest2(vals1, vals2);
                %         end
                % 
                %         cstats(kk,1) = g1;
                %         cstats(kk,2) = g2;
                %         cstats(kk,6) = p_pair;
                %     end
                % 
                %     add_stat_annotations(ax, cstats, group_data);
            end
        end
    end
end

end


function condition_info = get_condition_grouping(h)
% GET_CONDITION_GROUPING - User assigns Exp/Port to condition, replicate and repeat.

h = guidata(h.figure);

idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

nPorts = size(selected,1);
condition_info = struct();

d = dialog( ...
    'Name','Assign Conditions / Replicates', ...
    'Units','pixels', ...
    'Position',[100 100 820 520], ...
    'Color',[0.94 0.94 0.94]);

% -------------------------------------------------------------------------
% Instruction panel
% -------------------------------------------------------------------------
p = uipanel( ...
    'Parent',d, ...
    'Title','How to fill this in', ...
    'Units','pixels', ...
    'Position',[20 350 780 150], ...
    'BackgroundColor',[1 1 1]);

helpText = sprintf([ ...
    'Condition: x-axis group, e.g. Baseline, KCl, Washout.\n' ...
    'Replicate ID: use the same number for the same biological sample across conditions.\n' ...
    'Repeat ID: use this for repeated technical recordings from the same sample and condition.\n\n' ...
    'Example paired design:\n' ...
    'Exp1_Port1 = Baseline, Replicate 1, Repeat 1\n' ...
    'Exp1_Port2 = KCl,      Replicate 1, Repeat 1\n' ...
    'Exp1_Port3 = Washout,  Replicate 1, Repeat 1' ...
    ]);

uicontrol( ...
    'Parent',p, ...
    'Style','text', ...
    'Units','pixels', ...
    'String',helpText, ...
    'HorizontalAlignment','left', ...
    'BackgroundColor',[1 1 1], ...
    'ForegroundColor',[0 0 0], ...
    'FontSize',9, ...
    'Position',[15 10 750 120]);

colnames = {'Experiment/Port','Condition','Replicate ID','Repeat ID'};

data = cell(nPorts,4);

for k = 1:nPorts
    expIdx = selected(k,1);
    portIdx = selected(k,2);

    data{k,1} = sprintf('Exp%d_Port%d', expIdx, portIdx);
    data{k,2} = '';
    data{k,3} = num2str(k);
    data{k,4} = '1';
end

t = uitable( ...
    'Parent',d, ...
    'Data',data, ...
    'ColumnName',colnames, ...
    'ColumnEditable',[false true true true], ...
    'RowName',[], ...
    'Position',[20 65 640 240]);

uicontrol( ...
    'Parent',d, ...
    'Style','pushbutton', ...
    'String','OK', ...
    'Position',[300 20 80 30], ...
    'Callback',@(src,event) uiresume(d));

uiwait(d);

if ishandle(t)

    user_data = t.Data;

    for k = 1:nPorts

        fld = user_data{k,1};
        cond = strtrim(user_data{k,2});
        repID = str2double(user_data{k,3});
        repeatID = str2double(user_data{k,4});

        if isempty(cond)
            warning('No condition entered for %s. Skipping.', fld);
            continue;
        end

        if isnan(repID)
            repID = k;
        end

        if isnan(repeatID)
            repeatID = 1;
        end

        condition_info.(fld) = struct( ...
            'condition', cond, ...
            'replicate', repID, ...
            'repeat', repeatID);
    end

    delete(d);
end

end


function plot_box_per_group_condition(ax, group_data, group_labels, colors, ylab)
% PLOT_BOX_PER_GROUP_CONDITION - Box/bar plot with overlaid replicate points.

hold(ax,'on');

nGroups = numel(group_data);
maxLen = max(cellfun(@numel, group_data));

data_mat = nan(maxLen, nGroups);

for k = 1:nGroups
    vals = group_data{k};
    data_mat(1:numel(vals), k) = vals(:);
end

if size(data_mat,1) < 2

    means = cellfun(@(x) mean(x,'omitnan'), group_data);

    b = bar(ax, 1:nGroups, means, ...
        'FaceColor','flat', ...
        'EdgeColor','k', ...
        'LineWidth',1.5);

    for k = 1:nGroups
        b.CData(k,:) = colors(k,:);
    end

    b.FaceAlpha = 0.6;

else

    boxplot(ax, data_mat, ...
        'Labels', group_labels, ...
        'Colors', colors(1,:), ...
        'Symbol','o', ...
        'MedianStyle','line');

    box_handles = findobj(ax,'Tag','Box');
    reversed_colors = flipud(colors);

    for i = 1:length(box_handles)
        patch( ...
            get(box_handles(i),'XData'), ...
            get(box_handles(i),'YData'), ...
            reversed_colors(i,:), ...
            'FaceAlpha',0.6, ...
            'EdgeColor','k', ...
            'LineWidth',1, ...
            'Parent',ax);
    end
end

for k = 1:nGroups

    valid_points = ~isnan(data_mat(:,k));
    y = data_mat(valid_points,k);

    x = k * ones(size(y));

    scatter(ax, x, y, 18, 'k', 'filled', ...
        'MarkerFaceAlpha',0.5, ...
        'DisplayName',group_labels{k});
end

ylabel(ax, ylab, 'Interpreter','none');

set(ax, ...
    'XTick',1:nGroups, ...
    'XTickLabel',group_labels, ...
    'XTickLabelRotation',45);

box(ax,'off');
hold(ax,'on');

tb_stats = axtoolbar(ax, {'save','zoomin','zoomout','restoreview','pan'});

axtoolbarbtn(tb_stats, 'push', ...
    'Icon','export_data_icon.png', ...
    'Tooltip','Export to CSV', ...
    'ButtonPushedFcn', @(~,~) export_axes_to_csv(ax, 'Condition_Stats'));

end


function add_stat_annotations(ax, cstats, group_data)
% ADD_STAT_ANNOTATIONS - Adds significance bars to grouped plots.
%
% cstats columns expected:
%   col 1 = group 1
%   col 2 = group 2
%   col 6 = p-value

all_vals = [];

for g = 1:numel(group_data)
    all_vals = [all_vals; group_data{g}(:)]; %#ok<AGROW>
end

all_vals = all_vals(~isnan(all_vals));

if isempty(all_vals)
    return;
end

ylims = ylim(ax);
dataMin = min([all_vals(:); ylims(1)]);
dataMax = max([all_vals(:); ylims(2)]);

if dataMax == dataMin
    dataMax = dataMin + 1;
end

yspan = dataMax - dataMin;
offset_step = 0.08 * yspan;
base_y = dataMax + 0.08 * yspan;

used = 0;
y_offsets = [];

for k = 1:size(cstats,1)

    g1 = cstats(k,1);
    g2 = cstats(k,2);
    p_pair = cstats(k,6);

    if isnan(p_pair)
        continue;
    end

    if isempty(group_data{g1}) || isempty(group_data{g2})
        continue;
    end

    if p_pair < 0.001
        star = '***';
    elseif p_pair < 0.01
        star = '**';
    elseif p_pair < 0.05
        star = '*';
    else
        star = 'n.s.';
    end

    used = used + 1;
    y = base_y + used * offset_step;

    plot(ax, [g1 g2], [y y], 'k-', 'LineWidth',1.2);

    text(ax, mean([g1 g2]), y + 0.02*yspan, star, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'Color','k', ...
        'FontSize',9);

    y_offsets(end+1) = y; %#ok<AGROW>
end

if ~isempty(y_offsets)
    ylim(ax, [dataMin, max(y_offsets) + 0.15*yspan]);
end

end

function [vals1_paired, vals2_paired] = get_paired_values_by_replicate( ...
    condition_info, exp_port_map, group_labels, cond1, cond2, ...
    group_data, g1, g2)

% GET_PAIRED_VALUES_BY_REPLICATE
% Returns paired condition values matched by biological replicate ID.
%
% This assumes that group_data{g} is ordered in the same order as
% group_combo_ids were collected inside the main metric loop.

rep1 = [];
rep2 = [];

fields = fieldnames(condition_info);

for i = 1:numel(fields)

    fld = fields{i};
    info = condition_info.(fld);

    if strcmp(info.condition, cond1)
        rep1(end+1,1) = info.replicate; %#ok<AGROW>
    elseif strcmp(info.condition, cond2)
        rep2(end+1,1) = info.replicate; %#ok<AGROW>
    end
end

vals1 = group_data{g1};
vals2 = group_data{g2};

% Safety: trim replicate vectors to match available values.
rep1 = rep1(1:min(numel(rep1), numel(vals1)));
rep2 = rep2(1:min(numel(rep2), numel(vals2)));

vals1 = vals1(1:numel(rep1));
vals2 = vals2(1:numel(rep2));

common_reps = intersect(rep1, rep2, 'stable');

vals1_paired = NaN(numel(common_reps),1);
vals2_paired = NaN(numel(common_reps),1);

for r = 1:numel(common_reps)

    this_rep = common_reps(r);

    idx1 = find(rep1 == this_rep, 1, 'first');
    idx2 = find(rep2 == this_rep, 1, 'first');

    vals1_paired(r) = vals1(idx1);
    vals2_paired(r) = vals2(idx2);
end

end