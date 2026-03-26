function plot_all_spikes(h)
    h = guidata(h.figure);
    set_status(h.figure,"loading","Plotting Aggregated Spikes...");

    % Collect selected ports
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);
    if ~isfield(h,'cumulative_spikes')
       errordlg('Please aggregate spikes before proceeding..');
    end
    all_waveforms     = h.cumulative_spikes.all_waveforms;
    all_channels      = h.cumulative_spikes.channels;
    ptp_amplitude     = h.cumulative_spikes.ptp_amplitude;
    fwhm              = h.cumulative_spikes.fwhm;
    spike_origin_p    = h.cumulative_spikes.spike_origin_p;
    spike_origin_e    = h.cumulative_spikes.spike_origin_e;
    if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)
        r = h.spike_filter_ranges;
        keep = ptp_amplitude >= r.amp(1) & ptp_amplitude <= r.amp(2) & fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
        all_waveforms = all_waveforms(keep,:);
        all_channels = all_channels(keep);
        spike_origin_p = spike_origin_p(keep);
        spike_origin_e = spike_origin_e(keep);
    end
    % Unique combinations for plotting
    unique_combos = unique([spike_origin_e, spike_origin_p, all_channels], 'rows');
    total_tiles = size(unique_combos,1);

    % Delete old panel if exists
    if isfield(h,'spikesPanel') && isvalid(h.spikesPanel)
        delete(h.spikesPanel);
    end
    if exist('spike_config.mat','file')
        cfg = load('spike_config.mat'); cfg = cfg.config;
    end

    % DEFAULTS
    def = struct('pre_time',0.8,'post_time',0.8','pre_time_plot',0.8,'post_time_plot',0.8,'align_mode','min','central_tendency','mean',...
                 'spread','std','line_width',2,'shade_alpha',0.3,'ylim_mode','auto','split_polarity',0);
    fn = fieldnames(def);
    for i = 1:numel(fn)
        if ~isfield(cfg,fn{i}), cfg.(fn{i}) = def.(fn{i}); end
    end
    h.cfg = cfg; guidata(h.figure,h);


    % Create new panel
    panelHeight = 0.88; panelBottom = 0.1;
    h.spikesPanel = uipanel('Parent', h.assess_spike_groups, ...
                            'Units','normalized', ...
                            'Position',[0, panelBottom, 1, panelHeight], ...
                            'BackgroundColor',[1 1 1], ...
                            'Title','Spike Waveforms');

    %  Store spike data for pagination 
    spikePlots = struct([]);
    for i = 1:total_tiles
        expIdx  = unique_combos(i,1);
        portIdx = unique_combos(i,2);
        chan    = unique_combos(i,3);

        sel_idx = find(spike_origin_e==expIdx & spike_origin_p==portIdx & all_channels==chan);
        wf = all_waveforms(sel_idx,:);

        %  Flip (standardise polarity) 
        flip_idx = abs(min(wf,[],2)) < abs(max(wf,[],2));
        wf(flip_idx,:) = -wf(flip_idx,:);
        
        %  Alignment 
        if ~strcmp(cfg.align_mode,'none')
            switch cfg.align_mode
                case 'min'
                    [~,align_idx] = min(wf,[],2);
                case 'max'
                    [~,align_idx] = max(wf,[],2);
            end
            center = round(size(wf,2)/2);
            for w = 1:size(wf,1)
                shift = center - align_idx(w);
                wf(w,:) = circshift(wf(w,:),shift);
            end
        end
        
        %  Central tendency 
        switch cfg.central_tendency
            case 'median'
                mean_wf = median(wf,1);
            otherwise
                mean_wf = mean(wf,1);
        end
        
        %  Spread 
        switch cfg.spread
            case 'sem'
                std_wf = std(wf,[],1) / sqrt(size(wf,1));
            otherwise
                std_wf = std(wf,[],1);
        end
        % mean_wf = mean(all_waveforms(sel_idx,:),1);
        % std_wf  = std(all_waveforms(sel_idx,:),1);

        spikePlots(i).mean = mean_wf;
        spikePlots(i).std  = std_wf;
        spikePlots(i).exp  = expIdx;
        spikePlots(i).port = portIdx;
        spikePlots(i).chan = chan;
    end

    h.spikePlots = spikePlots;
    h.maxPerPage = 12;
    h.currentPage = 1;
    h.totalPlots = numel(spikePlots);
    h.nPages = ceil(h.totalPlots / h.maxPerPage);

    %  Create navigation buttons 
    btnPrev = uicontrol(h.assess_spike_groups,'Style','pushbutton',...
        'String','<','Units','normalized','Position',[0.01 0.01 0.05 0.05],...
        'Callback',@(s,e) changePage_all(-1,h));

    btnNext = uicontrol(h.assess_spike_groups,'Style','pushbutton',...
        'String','>','Units','normalized','Position',[0.07 0.01 0.05 0.05],...
        'Callback',@(s,e) changePage_all(1,h));

    h.page_buttons = [btnPrev btnNext];
    guidata(h.figure,h);

    % Initial plot
    updateAxes_all(h);
    set_status(h.figure,"ready","Plotting Aggregated Spikes Complete...");

end

%%  Page switcher 
function changePage_all(delta,h)
    h = guidata(h.figure);
    h.currentPage = max(1, min(h.nPages, h.currentPage + delta));
    guidata(h.figure,h);
    updateAxes_all(h);
end

%%  Render current page 
function updateAxes_all(h)
    h = guidata(h.figure);
    cfg = h.cfg;
    % Clear old axes
    delete(findall(h.spikesPanel,'Type','axes'));

    % Fixed 3x4 layout (12 max)
    t = tiledlayout(h.spikesPanel,3,4,'TileSpacing','compact','Padding','compact');

    startIdx = (h.currentPage-1)*h.maxPerPage + 1;
    endIdx   = min(h.currentPage*h.maxPerPage, h.totalPlots);

    for i = startIdx:endIdx
        data = h.spikePlots(i);

        ax = nexttile(t);
        hold(ax,'on');

        x = linspace(-1,1,length(data.mean)); % waveform x-axis

        plot(ax,x,data.mean,'k','LineWidth',2);
        fill(ax,[x fliplr(x)],...
            [data.mean+data.std fliplr(data.mean-data.std)],...
            'b','FaceAlpha',cfg.shade_alpha,'EdgeColor','none');

        hold(ax,'off');

        % Safe fetch of port ID
        if iscell(h.figure.UserData)
            results = h.figure.UserData;
        else
            results = {h.figure.UserData};
        end

        title(ax,sprintf('Port %d | Ch %d | Exp %d',...
            results{data.exp}.ports(data.port).port_id,...
            data.chan,data.exp));
        set(ax,'TickDir','out')
        if strcmp(cfg.ylim_mode,'global')
            ylim(ax,h.global_ylim);
        end
        ylabel(ax,'Voltage (\muV)')
        box(ax,'off');
    end

    % Optional: page indicator
    title(t, sprintf('%d / %d', h.currentPage, h.nPages));
end