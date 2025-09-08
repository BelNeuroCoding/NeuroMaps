function study_evolution(h)
    warning('off', 'all');

    % STUDY_EVOLUTION - Plot cumulative spike and channel metrics over time
    h = guidata(h.figure);
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    %  Safety checks 
    if ~isfield(h,'cumulative_spikes') || isempty(h.cumulative_spikes.all_waveforms)
        errordlg('No cumulative spike data available. Run aggregation first.');
        return;
    end
    cs = h.cumulative_spikes;
    
    %  Get experiment ages 
    experiment_ages = get_experiment_ages(h);
    if isempty(fieldnames(experiment_ages)), return; end
    
    %  Time binning 
    choice = questdlg('Plot evolution by days, weeks or months?', ...
        'Time Binning', 'Days', 'Weeks', 'Months','Days');
    if isempty(choice), return; end
    time_unit = lower(choice);
    
    %  Statistics option 
    statChoice = questdlg('Compute statistics?', 'Statistics', ...
        'No','Kruskal-Wallis','Pairwise t-tests','No');
    computeStats = ~(isempty(statChoice) || strcmpi(statChoice,'No'));
    if computeStats, statMethod = statChoice; else, statMethod = ''; end
        warning('off', 'all');
    
        h = guidata(h.figure); 
        if ~isfield(h,'cumulative_spikes') || ...
           ~isfield(h.cumulative_spikes,'all_waveforms') || ...
           isempty(h.cumulative_spikes.all_waveforms)
            errordlg('No cumulative spike data available. Run aggregation first.');
            return;
        end


    %  map names to fields 
    metricMap = { ...
        'Spike Rate',             'spike_times'; ...
        'Burst Rate',             'spike_times'; ... % needs spike_times for bursts
        'FWHM',                   'fwhm'; ...
        'Peak-to-Peak Amplitude', 'ptp_amplitude'; ...
        'Synchrony',              'spike_times'; ...
        'Impedance',              'impedance'; ...
        'Capacitance',            'capacitance'; ...
        'Aperiodic Offset',       'offset'; ...
        'Aperiodic Exponent',     'exponent'; ...
        'Number of Active Channels','channels' ...
        };

    % filter available + nonempty 
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
    %  ask user which to plot 
    [idx, ok] = listdlg('PromptString','Select metrics to plot:', ...
        'SelectionMode','multiple', 'ListString',availableMetrics);
    if ~ok, return; end
    metrics = availableMetrics(idx);
    nMetrics = numel(metrics);
    
    %  Burst parameters 
    burstParams = [];
    if any(strcmp(metrics,'Burst Rate')) || any(strcmp(metrics,'Synchrony'))
        burstParams.min_spikes_per_burst = str2double(get(h.burst_param(2),'String'));
        burstParams.isi_threshold = str2double(get(h.burst_param(1),'String'));
        burstParams.min_burst_duration = str2double(get(h.burst_param(3),'String'));
        burstParams.min_active_channels = str2double(get(h.burst_param(4),'String'));
    end
    
    %  Map experiment/port -> start date/age 
    fields_exp = fieldnames(experiment_ages);
    nCombos = numel(fields_exp);
    exp_port_map = zeros(nCombos,2);
    start_dates = NaT(nCombos,1);
    start_ages = NaN(nCombos,1);
    for k = 1:nCombos
        toks = split(fields_exp{k}, '_'); % 'ExpX_PortY'
        exp_port_map(k,1) = str2double(strrep(toks{1}, 'Exp', ''));
        exp_port_map(k,2) = str2double(strrep(toks{2}, 'Port', ''));
        start_dates(k) = experiment_ages.(fields_exp{k}).start_date;
        start_ages(k) = experiment_ages.(fields_exp{k}).age;
    end
    
    %  Spike ages and combo indices 
    nSpikes = numel(cs.spike_origin_e);
    combo_idx = NaN(nSpikes,1);
    for k = 1:nCombos
        mask = cs.spike_origin_e==exp_port_map(k,1) & cs.spike_origin_p==exp_port_map(k,2);
        combo_idx(mask) = k;
    end
    
    exp_dates = NaT(nSpikes,1);
    unique_exps = unique(cs.spike_origin_e);
    for i = 1:numel(unique_exps)
        idxe = cs.spike_origin_e==unique_exps(i);
        res = h.figure.UserData{unique_exps(i)};
        exp_dates(idxe) = datetime(res.metadata.date,'InputFormat','dd-MMM-yyyy');
    end
    
    ages = NaN(nSpikes,1);
    valid_mask = ~isnan(combo_idx);
    ages(valid_mask) = days(exp_dates(valid_mask) - start_dates(combo_idx(valid_mask))) + ...
        start_ages(combo_idx(valid_mask));
    
    switch time_unit
        case 'weeks', ages = ages/7;
        case 'months', ages = ages/30;
    end
    
    %  Spec-derived ages 
    if isfield(cs,'spec_e') && isfield(cs,'spec_p')
        nSpec = numel(cs.spec_e);
        spec_combo_idx = NaN(nSpec,1);
        for k = 1:nCombos
            m = cs.spec_e==exp_port_map(k,1) & cs.spec_p==exp_port_map(k,2);
            spec_combo_idx(m) = k;
        end
        spec_exp_dates = NaT(nSpec,1);
        spec_unique_exps = unique(cs.spec_e);
        for i = 1:numel(spec_unique_exps)
            idxe = cs.spec_e==spec_unique_exps(i);
            res = h.figure.UserData{spec_unique_exps(i)};
            spec_exp_dates(idxe) = datetime(res.metadata.date,'InputFormat','dd-MMM-yyyy');
        end
        ages_spec = NaN(nSpec,1);
        spec_valid = ~isnan(spec_combo_idx);
        ages_spec(spec_valid) = days(spec_exp_dates(spec_valid) - start_dates(spec_combo_idx(spec_valid))) + ...
            start_ages(spec_combo_idx(spec_valid));
        switch time_unit
            case 'weeks', ages_spec = ages_spec/7;
            case 'months', ages_spec = ages_spec/30;
        end
    else
        nSpec = 0; spec_combo_idx = []; ages_spec = [];
    end
    
    %  Bin spikes and spec by age 
    age_bins = unique(floor(ages(~isnan(ages))));
    nGroups = numel(age_bins);
    group_idx = NaN(nSpikes,1);
    group_labels = cell(nGroups,1);
    for g = 1:nGroups
        m = floor(ages) == age_bins(g);
        group_idx(m) = g;
        group_labels{g} = sprintf('%d %s', age_bins(g), time_unit);
    end
    
    if nSpec > 0
        group_spec_idx = NaN(nSpec,1);
        for g = 1:nGroups
            m = floor(ages_spec) == age_bins(g);
            group_spec_idx(m) = g;
        end
    else
        group_spec_idx = [];
    end
    
    %  Clear previous content 
    if isfield(h,'group_evolution') && isvalid(h.group_evolution)
        delete(allchild(h.group_evolution));
    end
    
    %  Prepare layout 
    nRows = ceil(sqrt(nMetrics));
    nCols = ceil(nMetrics/nRows);
    t = tiledlayout(h.group_evolution,nRows,nCols,'TileSpacing','compact','Padding','compact');
    
    useDenseOrCombo = @(numCombos) (numCombos <= 1); % single combo per bin => dense
    
    %  Loop over metrics 
    for m = 1:nMetrics
        metric_name = metrics{m};
        ax = nexttile(t); hold(ax,'on'); ylabel(ax, metric_name);
        group_data = cell(nGroups,1);
    
        for g = 1:nGroups
            mask = (group_idx == g);
            if ~any(mask) && ~ismember(metric_name, {'Impedance','Capacitance','Aperiodic Offset','Aperiodic Exponent'})
                group_data{g} = [];
                continue;
            end
    
            %  Compute values per metric 
            switch metric_name
                case 'Spike Rate'
                    combo_ids = unique(combo_idx(mask));
                    if useDenseOrCombo(numel(combo_ids))
                        chans = cs.channels(mask);
                        dur = unique(cs.rec_time(mask));
                        uch = unique(chans);
                        vals = arrayfun(@(ch) sum(chans==ch)/dur, uch);
                    else
                        vals = [];
                        for c = combo_ids(:)'
                            submask = mask & (combo_idx==c);
                            chans_c = cs.channels(submask);
                            dur_c = unique(cs.rec_time(submask));
                            vals(end+1,1) = mean(arrayfun(@(ch) sum(chans_c==ch)/dur_c, unique(chans_c)));
                        end
                    end
                    group_data{g} = vals;
    
                case 'FWHM'
                    combo_ids = unique(combo_idx(mask));
                    if useDenseOrCombo(numel(combo_ids))
                        chans = cs.channels(mask);
                        fwhm = cs.fwhm(mask);
                        uch = unique(chans);
                        vals = arrayfun(@(ch) mean(fwhm(chans==ch),'omitnan'), uch);
                    else
                        vals = [];
                        for c = combo_ids(:)'
                            submask = mask & (combo_idx==c);
                            chans_c = cs.channels(submask);
                            fwhm_c = cs.fwhm(submask);
                            uch = unique(chans_c);
                            vals(end+1,1) = mean(arrayfun(@(ch) mean(fwhm_c(chans_c==ch),'omitnan'), uch),'omitnan');
                        end
                    end
                    group_data{g} = vals;
    
                case 'Peak-to-Peak Amplitude'
                    combo_ids = unique(combo_idx(mask));
                    if useDenseOrCombo(numel(combo_ids))
                        chans = cs.channels(mask);
                        ptp = cs.ptp_amplitude(mask);
                        uch = unique(chans);
                        vals = arrayfun(@(ch) mean(ptp(chans==ch),'omitnan'), uch);
                    else
                        vals = [];
                        for c = combo_ids(:)'
                            submask = mask & (combo_idx==c);
                            chans_c = cs.channels(submask);
                            ptp_c = cs.ptp_amplitude(submask);
                            uch = unique(chans_c);
                            vals(end+1,1) = mean(arrayfun(@(ch) mean(ptp_c(chans_c==ch),'omitnan'), uch),'omitnan');
                        end
                    end
                    group_data{g} = vals;
    
                case 'Burst Rate'
                    if isempty(burstParams), group_data{g} = []; continue; end
                    combo_ids = unique(combo_idx(mask));
                    vals = [];
                    for c = combo_ids(:)'
                        submask = mask & (combo_idx==c);
                        chans_c = cs.channels(submask);
                        st_c = cs.spike_times(submask);
                        dur_c = unique(cs.rec_time(submask));
                        uch = unique(chans_c);
                        tmp = nan(size(uch));
                        for iCh = 1:numel(uch)
                            stc = sort(st_c(chans_c==uch(iCh)));
                            bursts = detect_bursts_mod(stc, burstParams.isi_threshold, ...
                                burstParams.min_spikes_per_burst, burstParams.min_burst_duration);
                            tmp(iCh) = numel(bursts)/dur_c;
                        end
                        vals(end+1,1) = mean(tmp,'omitnan');
                    end
                    group_data{g} = vals;
    
                case 'Synchrony'
                    if isempty(burstParams), group_data{g} = []; continue; end
                    combo_ids = unique(combo_idx(mask));
                    vals = [];
                    for c = combo_ids(:)'
                        submask = mask & (combo_idx==c);
                        chans_c = cs.channels(submask);
                        st_c = cs.spike_times(submask);
                        dur_c = unique(cs.rec_time(submask));
                        uch = unique(chans_c);
                        if numel(uch) > burstParams.min_active_channels
                            S = NaN(sum(submask), numel(uch));
                            for ii = 1:numel(uch)
                                sti = st_c(chans_c==uch(ii));
                                S(1:numel(sti),ii) = sti;
                            end
                            [Synch,~] = SpikeContrast(S, dur_c);
                            vals(end+1,1) = Synch;
                        else
                            vals(end+1,1) = NaN;
                        end
                    end
                    group_data{g} = vals;
    
                case {'Impedance','Capacitance','Aperiodic Offset','Aperiodic Exponent'}
                    if isempty(group_spec_idx), group_data{g} = []; continue; end
                    mask_spec = (group_spec_idx == g);
                    if ~any(mask_spec), group_data{g} = []; continue; end
                    switch metric_name
                        case 'Impedance', vec = cs.impedance(:);
                        case 'Capacitance', vec = cs.capacitance(:);
                        case 'Aperiodic Offset', vec = cs.offset(:);
                        case 'Aperiodic Exponent', vec = cs.exponent(:);
                    end
                    combo_ids = unique(spec_combo_idx(mask_spec));
                    if useDenseOrCombo(numel(combo_ids))
                        vals = vec(mask_spec);
                    else
                        vals = [];
                        for c = combo_ids(:)'
                            submask = mask_spec & (spec_combo_idx==c);
                            vals(end+1,1) = mean(vec(submask),'omitnan');
                        end
                    end
                    if strcmp(metric_name,'Impedance'), vals(vals>1000) = 1000; end
                    group_data{g} = vals;
            end
        end
    
        %  Plot 
        colors = lines(nGroups);
        plot_box_per_group(ax, group_data, colors, metric_name);
        set(ax,'XTick',1:nGroups,'XTickLabel',group_labels,'XTickLabelRotation',45);
        title(ax, metric_name); box(ax,'off'); hold(ax,'on');
    
        %  Statistics overlay 
        if computeStats
            all_values = []; group_vec = [];
            for g = 1:nGroups
                vals = group_data{g};
                if isempty(vals), continue; end
                all_values = [all_values; vals(:)];
                group_vec = [group_vec; g*ones(numel(vals),1)];
            end
    
            if numel(all_values)>2 && nGroups>1
                switch statMethod
                    case 'Kruskal-Wallis'
                        [~,~,stats] = kruskalwallis(all_values, group_vec,'off');
                        c = multcompare(stats, 'Display','off');
                        ylims = [0 max(all_values(:))]; yspan = ylims(2)-ylims(1);
                        offset_step = 0.05*yspan; y_offsets = zeros(size(c,1),1);
                        for k = 1:size(c,1)
                            g1=c(k,1); g2=c(k,2); p_pair=c(k,6);
                            if isempty(group_data{g1}) || isempty(group_data{g2}), continue; end
                            if p_pair<0.001, star='***';
                            elseif p_pair<0.01, star='**';
                            elseif p_pair<0.05, star='*'; else, star=''; end
                            y_offsets(k) = ylims(2)+offset_step+k*offset_step;
                            if ~isempty(star)
                                plot(ax,[g1 g2],y_offsets(k)*[1 1],'k-','LineWidth',1.5);
                                text(mean([g1 g2]),y_offsets(k)+0.01*yspan,star, ...
                                    'HorizontalAlignment','center','FontSize',14,'Color','r');
                            end
                        end
                        if any(y_offsets), ylim(ax,[0 max(y_offsets)*1.05]); end
    
                    case 'Pairwise t-tests'
                        combs = nchoosek(1:nGroups,2); ylims=[0 max(all_values(:))]; yspan=ylims(2)-ylims(1);
                        for k = 1:size(combs,1)
                            g1=combs(k,1); g2=combs(k,2);
                            if isempty(group_data{g1}) || isempty(group_data{g2}), continue; end
                            [~,p_pair] = ttest2(group_data{g1}, group_data{g2});
                            if p_pair<0.001, star='***'; elseif p_pair<0.01, star='**';
                            elseif p_pair<0.05, star='*'; else, star=''; end
                            y_offsets(k)=ylims(2)+0.05*yspan+0.05*k*yspan;
                            if ~isempty(star)
                                plot(ax,[g1 g2],y_offsets(k)*[1 1],'k-','LineWidth',1.5);
                                text(mean([g1 g2]),y_offsets(k)+0.01*yspan,star,'HorizontalAlignment','center','FontSize',14,'Color','r');
                            end
                        end
                        if any(y_offsets), ylim(ax,[0 max(y_offsets)*1.05]); end
                end
            end
        end
    end
    h.plotEvolutionBtn = uicontrol('Parent', h.group_evolution,  'Style', 'pushbutton',  'Units', 'normalized', ...
        'Position', [0.80, 0.0, 0.18, 0.05], 'String', 'Plot Evolution', 'Callback', @(src,event) study_evolution(h), 'Background',backgdcolor,... 
        'Foreground',accentcolor);
end

function experiment_ages = get_experiment_ages(h)
% Returns struct with experiment start dates and ages
h = guidata(h.figure); 
idx = h.portList.Value; % selected rows 
map = h.portList.UserData; % mapping to exp/port
selected = map(idx,:); % selected exp/ports
nPorts = size(selected,1); experiment_ages = struct();
% Create dialog
d = dialog('Name','Enter Experiment Ages','Position',[100 100 450 300]);

% Column names for the table
colnames = {'Experiment/Port','Age (days)','Start Date (yyyy-MM-dd)'};

% Initialize table data
data = cell(nPorts,3);

% Fill first column with labels, leave other columns empty for user input
for k = 1:nPorts
    expIdx = selected(k,1);
    portIdx = selected(k,2);
    data{k,1} = sprintf('Exp%d_Port%d', expIdx, portIdx); % label
    data{k,2} = ''; % age input
    data{k,3} = ''; % start date input
end

% Create uitable
t = uitable('Parent',d,...
            'Data',data,...
            'ColumnName',colnames,...
            'ColumnEditable',[false true true],...
            'RowName',[],...
            'Position',[20 60 410 220]);

% OK button
uicontrol('Parent',d,...
          'Style','pushbutton',...
          'String','OK',...
          'Position',[180 20 80 30],...
          'Callback',@(src,event) uiresume(d));

% Wait for user to finish input
uiwait(d);

% Read table data
if ishandle(t)
    user_data = t.Data;
    for k = 1:nPorts
        try
            fld = user_data{k,1};
            experiment_ages.(fld) = struct(...
                'age', str2double(user_data{k,2}),...
                'start_date', datetime(user_data{k,3},'InputFormat','yyyy-MM-dd'));
        catch
            warning('Invalid input for %s, skipping.', user_data{k,1});
        end
    end
    delete(d);
end

end

function plot_box_per_group(ax, group_data, colors, ylab)
% PLOT_BOX_PER_GROUP - Plots boxplots with overlaid scatter points for each group
%
% ax         : Axes handle to plot on
% group_data : Cell array of vectors, each cell = one group's data
% colors     : nGroups x 3 RGB matrix
% ylab       : Y-axis label (string)

hold(ax,'on');

nGroups = numel(group_data);
maxLen = max(cellfun(@numel, group_data));

% Create data matrix (rows = points, columns = groups)
data_mat = nan(maxLen, nGroups);
for k = 1:nGroups
    data_mat(1:numel(group_data{k}), k) = group_data{k};
end

if size(data_mat,1) < 2
    % Single value per group → bar plot
    means = cellfun(@mean, group_data);
    b = bar(ax, 1:nGroups, means, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.5);
    % Apply colors
    for k = 1:nGroups
        b.CData(k,:) = colors(k,:);
    end
    b.FaceAlpha = 0.6;
else
    % Regular boxplot
    boxplot(ax, data_mat, 'Colors', colors(1,:), 'Symbol','o','MedianStyle','line');

    % Recolor boxes manually
    box_handles = findobj(ax,'Tag','Box');
    reversed_colors = flipud(colors); % boxplot draws last box first
    for i = 1:length(box_handles)
        patch(get(box_handles(i),'XData'), get(box_handles(i),'YData'), reversed_colors(i,:), ...
              'FaceAlpha',0.6,'EdgeColor','k','LineWidth',1,'Parent',ax);
    end
end

for k = 1:nGroups
    valid_points = ~isnan(data_mat(:,k));
    x = k * ones(1,sum(valid_points));
    scatter(ax, x, data_mat(valid_points,k), 10, 'k', 'filled', 'MarkerFaceAlpha', 0.5);
end

ylabel(ax, ylab);
box(ax, 'off');
hold(ax,'off');

end


