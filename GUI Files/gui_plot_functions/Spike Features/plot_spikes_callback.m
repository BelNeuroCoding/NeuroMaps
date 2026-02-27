function plot_spikes_callback(h)

    h = guidata(h.figure);
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    %% ---------------- DELETE OLD BUTTONS ----------------
    if isfield(h,'page_buttons')
        delete(h.page_buttons(ishandle(h.page_buttons)));
    end

    %% ---------------- LOAD CONFIG ----------------
    if exist('spike_config.mat','file')
        cfg = load('spike_config.mat');
        cfg = cfg.config;
        pre_time = cfg.pre_time; 
        post_time = cfg.post_time;
    else
        pre_time = 0.8;
        post_time = 0.8;
    end

    %% ---------------- GET SELECTED PORTS ----------------
    idx = h.portList.Value;           
    map = h.portList.UserData;        
    selected = map(idx,:);

    spikeData = [];  % store waveform data, not axes

    %% ---------------- LOOP PORTS ----------------
    for p = 1:size(selected,1)
        expIdx = selected(p,1);
        selected_idx = selected(p,2);

        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end

        if numel(results.spike_results) < selected_idx
            continue;
        end

        waveforms_all = results.spike_results(selected_idx).waveforms_all;

        %% ----- FILTER (Amp + FWHM only) -----
        ptp  = [waveforms_all.ptp_amplitude]';
        fwhm = [waveforms_all.fwhm]';

        if isfield(h,'spike_filter_ranges') && ~isempty(h.spike_filter_ranges)
            r = h.spike_filter_ranges;
            keep = ptp >= r.amp(1) & ptp <= r.amp(2) & ...
                   fwhm >= r.fwhm(1) & fwhm <= r.fwhm(2);
            waveforms_all = waveforms_all(keep);
        end

        if isempty(waveforms_all)
            continue;
        end

        %% ----- STORE DATA -----
        all_waveforms = cell2mat(arrayfun(@(x) x.spike_shape, waveforms_all, 'UniformOutput', false)');
        flip_idx = abs(min(all_waveforms,[],2)) < abs(max(all_waveforms,[],2));
        all_waveforms(flip_idx,:) = -all_waveforms(flip_idx,:);

        N_samples = size(all_waveforms,2);
        ts = linspace(-pre_time, post_time, N_samples);

        channels = cell2mat(arrayfun(@(x) x.channel, waveforms_all, 'UniformOutput', false)');
        unique_chans = unique(channels);

        for i = 1:numel(unique_chans)
            ch = unique_chans(i);
            ch_idx = channels == ch;
            mean_wf = mean(all_waveforms(ch_idx,:),1);
            std_wf  = std(all_waveforms(ch_idx,:),1);

            spikeData(end+1).ts = ts;
            spikeData(end).mean_wf = mean_wf;
            spikeData(end).std_wf  = std_wf;
            spikeData(end).title   = ['Ch: ' num2str(ch) ' | Port: ' num2str(results.ports(selected_idx).port_id)];
        end
    end

    h.spikeData = spikeData;
    h.maxPerPage = 14;
    h.totalPlots = numel(spikeData);
    if h.totalPlots == 0
        guidata(h.figure,h);
        return;
    end

    h.nPages = ceil(h.totalPlots / h.maxPerPage);
    h.currentPage = 1;

    % create buttons ONCE
    btnPrev = uicontrol(h.spikes_tab,'Style','pushbutton','String','<',...
        'Position',[10 2 30 30],...
        'Callback',@(src,evt) changePage(-1));
    btnNext = uicontrol(h.spikes_tab,'Style','pushbutton','String','>',...
        'Position',[50 2 30 30],...
        'Callback',@(src,evt) changePage(1));
    btnSave = uicontrol(h.spikes_tab,'Style','pushbutton','String','Save',...
    'Position',[90 2 50 30],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor,...
    'Callback',@(src,evt) saveSpikePlots());
    h.spike_plot_button = uicontrol('Style', 'pushbutton','Parent', h.spikes_tab,'String', 'Plot Spikes', ...
    'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
    'Callback', @(src, event) plot_spikes_callback(h));
    h.filter_spikes_button = uicontrol('Style', 'pushbutton','Parent', h.spikes_tab,'String', 'Filter Spikes', ...
    'Units', 'normalized','Position', [0.60, 0.0, 0.18, 0.05], 'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
    'Callback', @(src, event) filter_spikes_callback(h));


    h.page_buttons = [btnPrev btnNext btnSave];
    guidata(h.figure,h);

    updateAxes();

end

function changePage(delta)
    h = guidata(gcbf);
    h.currentPage = max(1,min(h.nPages,h.currentPage + delta));
    guidata(h.figure,h);
    updateAxes();
end

function updateAxes()
    h = guidata(gcf);

    % Clear old plots but keep buttons
    children = get(h.spikes_tab,'Children');
    buttons = h.page_buttons;
    delete(setdiff(children, [buttons,h.spike_plot_button,h.filter_spikes_button]));

    tl = tiledlayout(h.spikes_tab,4,4,'TileSpacing','compact','Padding','compact');

    startIdx = (h.currentPage-1)*h.maxPerPage + 1;
    endIdx   = min(h.currentPage*h.maxPerPage,h.totalPlots);

    % Small tiles indices (leave space for center)
    smallTiles = setdiff([1:16],[13,16]);

    k = 1;
    for i = startIdx:endIdx
        if k > numel(smallTiles), break; end
        ax = nexttile(tl,smallTiles(k));
        plot(ax,h.spikeData(i).ts,h.spikeData(i).mean_wf,'k','LineWidth',2);
        hold(ax,'on');
        fill(ax,[h.spikeData(i).ts fliplr(h.spikeData(i).ts)], ...
             [h.spikeData(i).mean_wf + h.spikeData(i).std_wf fliplr(h.spikeData(i).mean_wf - h.spikeData(i).std_wf)],...
             'b','FaceAlpha',0.3,'EdgeColor','none');
        hold(ax,'off');
        title(ax,h.spikeData(i).title);
        xlabel(ax,'Time (ms)'); ylabel(ax,'Voltage (\muV)'); box(ax,'off');
        k = k + 1;
    end


end