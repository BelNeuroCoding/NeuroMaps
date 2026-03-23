function plot_spikes_callback(h)
%% --- Plot Spikes Callback (with Split Polarity) ---

    h = guidata(h.figure);
    set_status(h.figure,"loading","Spike waveform plot...");
    backgdcolor = [1,1,1]; accentcolor = [0.1,0.4,0.6];

    % DELETE OLD BUTTONS
    if isfield(h,'page_buttons')
        delete(h.page_buttons(ishandle(h.page_buttons)));
    end

    % LOAD CONFIG
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

    % SELECTED PORTS
    idx = h.portList.Value; map = h.portList.UserData; selected = map(idx,:);
    spikeData = [];

    for p = 1:size(selected,1)
        expIdx = selected(p,1); selected_idx = selected(p,2);

        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end
        
        if numel(results.spike_results) < selected_idx, continue; end

        waveforms_all = results.spike_results(selected_idx).waveforms_all;

        % FILTER
        ptp  = [waveforms_all.ptp_amplitude]';
        fwhm = [waveforms_all.fwhm]';
        if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)
            r = h.spike_filter_ranges;
            keep = ptp >= r.amp(1) & ptp <= r.amp(2) & fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
            waveforms_all = waveforms_all(keep);
        end
        if isempty(waveforms_all), continue; end

        % DATA MATRIX
        all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape,waveforms_all,'UniformOutput',false)');
        center = round(size(all_waveforms,2)/2);  % spike alignment center
        fs = results.fs;
        pre_samples  = round(cfg.pre_time_plot * fs)/1000;   % samples before spike
        post_samples = round(cfg.post_time_plot * fs)/1000;  % samples after spike
        start_idx = center - pre_samples + 1;
        end_idx   = center + post_samples;
        % Check for out-of-bounds
        if start_idx < 1 || end_idx > size(all_waveforms,2)
            % Compute actual window in samples we can use
            actual_start = max(1, start_idx);
            actual_end   = min(size(all_waveforms,2), end_idx);
            
            % Calculate actual time window (ms)
            actual_time_window = (actual_end - actual_start + 1)/fs*1000;
            
            % Show warning dialog
            warndlg(sprintf(['Requested pre/post window too large.\n' ...
                             'Automatically cropping to available data: %.2f ms'], ...
                             actual_time_window), 'Spike Plot Warning');
            
            start_idx = actual_start;
            end_idx   = actual_end;
        end
        all_waveforms = all_waveforms(:,start_idx:end_idx);
        ts = ((start_idx:end_idx) - center) / fs * 1000;
        channels = cell2mat(arrayfun(@(x) x.channel,waveforms_all,'UniformOutput',false)');
        unique_chans = unique(channels);

        if cfg.split_polarity
            min_vals = min(all_waveforms,[],2);
            max_vals = max(all_waveforms,[],2);
            neg_idx = abs(min_vals) >= abs(max_vals);
            pos_idx = ~neg_idx;
            center = round(size(all_waveforms,2)/2);

            % Align neg spikes
            if any(neg_idx)
                [~,idx_neg] = min(all_waveforms(neg_idx,:),[],2);
                rows = find(neg_idx);
                for w = 1:numel(rows)
                    shift = center - idx_neg(w);
                    all_waveforms(rows(w),:) = circshift(all_waveforms(rows(w),:),shift);
                end
            end
            % Align pos spikes
            if any(pos_idx)
                [~,idx_pos] = max(all_waveforms(pos_idx,:),[],2);
                rows = find(pos_idx);
                for w = 1:numel(rows)
                    shift = center - idx_pos(w);
                    all_waveforms(rows(w),:) = circshift(all_waveforms(rows(w),:),shift);
                end
            end

            % Populate spikeData for each channel/polarity
            for i = 1:numel(unique_chans)
                ch = unique_chans(i);

                % Neg
                ch_neg_idx = channels==ch & neg_idx;
                if any(ch_neg_idx)
                    wf_neg = all_waveforms(ch_neg_idx,:);
                    mean_wf = mean(wf_neg,1); std_wf = std(wf_neg,[],1);
                    if strcmp(cfg.central_tendency,'median'), mean_wf=median(wf_neg,1); end
                    if strcmp(cfg.spread,'sem'), std_wf=std(wf_neg,[],1)/sqrt(size(wf_neg,1)); end
                    spikeData(end+1).ts = ts;
                    spikeData(end).mean_wf = mean_wf; spikeData(end).std_wf = std_wf;
                    spikeData(end).title = ['Ch: ' num2str(ch) ' | Neg spikes'];
                end

                % Pos
                ch_pos_idx = channels==ch & pos_idx;
                if any(ch_pos_idx)
                    wf_pos = all_waveforms(ch_pos_idx,:);
                    mean_wf = mean(wf_pos,1); std_wf = std(wf_pos,[],1);
                    if strcmp(cfg.central_tendency,'median'), mean_wf=median(wf_pos,1); end
                    if strcmp(cfg.spread,'sem'), std_wf=std(wf_pos,[],1)/sqrt(size(wf_pos,1)); end
                    spikeData(end+1).ts = ts;
                    spikeData(end).mean_wf = mean_wf; spikeData(end).std_wf = std_wf;
                    spikeData(end).title = ['Ch: ' num2str(ch) ' | Pos spikes'];
                end
            end
        else
            % Original flip + alignment
            flip_idx = abs(min(all_waveforms,[],2)) < abs(max(all_waveforms,[],2));
            all_waveforms(flip_idx,:) = -all_waveforms(flip_idx,:);

            if ~strcmp(cfg.align_mode,'none')
                switch cfg.align_mode
                    case 'min', [~,align_idx] = min(all_waveforms,[],2);
                    case 'max', [~,align_idx] = max(all_waveforms,[],2);
                end
                center = round(size(all_waveforms,2)/2);
                for w=1:size(all_waveforms,1)
                    shift=center-align_idx(w);
                    all_waveforms(w,:) = circshift(all_waveforms(w,:),shift);
                end
            end

            % spikeData
            spikeData = [];
            for i = 1:numel(unique_chans)
                ch = unique_chans(i);
                ch_idx = channels==ch;
                wf = all_waveforms(ch_idx,:);
                mean_wf = mean(wf,1); std_wf = std(wf,[],1);
                if strcmp(cfg.central_tendency,'median'), mean_wf=median(wf,1); end
                if strcmp(cfg.spread,'sem'), std_wf=std(wf,[],1)/sqrt(size(wf,1)); end
                spikeData(end+1).ts = ts;
                spikeData(end).mean_wf = mean_wf; spikeData(end).std_wf = std_wf;
                spikeData(end).title = ['Ch: ' num2str(ch)];
            end
        end
    end

    % STORE AND PLOT
    h.spikeData = spikeData;
    h.maxPerPage = 12;
    h.totalPlots = numel(spikeData);
    if h.totalPlots==0, guidata(h.figure,h); return; end

    all_vals = [];
    for i=1:numel(spikeData)
        all_vals = [all_vals, spikeData(i).mean_wf+spikeData(i).std_wf, spikeData(i).mean_wf-spikeData(i).std_wf];
    end
    h.global_ylim = [min(all_vals), max(all_vals)];
    h.nPages = ceil(h.totalPlots/h.maxPerPage);
    h.currentPage = 1;

    % buttons
    btnPrev = uicontrol(h.spikes_tab,'Style','pushbutton','String','<','Position',[10 2 30 30],'Callback',@(s,e) changePage(-1));
    btnNext = uicontrol(h.spikes_tab,'Style','pushbutton','String','>','Position',[50 2 30 30],'Callback',@(s,e) changePage(1));
    btnSave = uicontrol(h.spikes_tab,'Style','pushbutton','String','Save','Position',[90 2 50 30],...
                        'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor,'Callback',@(s,e) saveSpikePlots());
    h.spike_plot_button = uicontrol('Style','pushbutton','Parent',h.spikes_tab,'String','Plot Spikes','Units','normalized','Position',[0.8,0.0,0.18,0.05],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor,'Callback',@(s,e) plot_spikes_callback(h));
    h.filter_spikes_button = uicontrol('Style','pushbutton','Parent',h.spikes_tab,'String','Filter Spikes','Units','normalized','Position',[0.6,0.0,0.18,0.05],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor,'Callback',@(s,e) filter_spikes_callback(h));
    h.plot_settings_spikes_button = uicontrol('Style','pushbutton','Parent',h.spikes_tab,'String','Plot Settings','Units','normalized','Position',[0.4,0.0,0.18,0.05],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor,'Callback',@(s,e) spike_snippet_settings(h));

    h.page_buttons = [btnPrev btnNext btnSave];
    guidata(h.figure,h);

    updateAxes(h);
    set_status(h.figure,"ready","Spike waveform plot complete...");

end
 
function changePage(delta)
    h = guidata(gcbf);
    h.currentPage = max(1,min(h.nPages,h.currentPage + delta));
    guidata(h.figure,h);
    updateAxes(h);
end

function updateAxes(h)
    h = guidata(h.figure);
    cfg = h.cfg;

    % Clear old plots but keep buttons
    children = get(h.spikes_tab,'Children');
    buttons = h.page_buttons;
    delete(setdiff(children, [buttons,h.spike_plot_button,h.filter_spikes_button,h.plot_settings_spikes_button]));

    tl = tiledlayout(h.spikes_tab,4,4,'TileSpacing','compact','Padding','compact');

    startIdx = (h.currentPage-1)*h.maxPerPage + 1;
    endIdx   = min(h.currentPage*h.maxPerPage,h.totalPlots);

    % Small tiles indices (leave space for center)
    smallTiles = setdiff([1:16],[13,16]);

    k = 1;
    for i = startIdx:endIdx
        if k > numel(smallTiles), break; end
        ax = nexttile(tl,smallTiles(k));
        plot(ax,h.spikeData(i).ts,h.spikeData(i).mean_wf,'k','LineWidth',cfg.line_width);
        hold(ax,'on');
        fill(ax,[h.spikeData(i).ts fliplr(h.spikeData(i).ts)],...
            [h.spikeData(i).mean_wf+h.spikeData(i).std_wf fliplr(h.spikeData(i).mean_wf-h.spikeData(i).std_wf)],...
            'b','FaceAlpha',cfg.shade_alpha,'EdgeColor','none');
        hold(ax,'off');
        title(ax,h.spikeData(i).title);
        xlabel(ax,'Time (ms)'); ylabel(ax,'Voltage (\muV)'); box(ax,'off');
        if strcmp(cfg.ylim_mode,'global')
            ylim(ax,h.global_ylim);
        end
        set(ax,'TickDir','out')
        k = k + 1;
    end


end