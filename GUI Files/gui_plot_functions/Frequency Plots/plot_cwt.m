function plot_cwt(h,src)
    h = guidata(h.figure);

    %%  Get selected port 
    idx = h.portList.Value;              % positions in the listbox
    map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
    selected = map(idx,:);

    expIdx = selected(1,1);
    port_idx = selected(1,2);      

    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    resampled_time = results.resampled_time;
    %  Read start/end times from UI 
    if nargin>1
        time_plot = str2num(src.String);
    else
        time_plot = [min(resampled_time),min(max(resampled_time),60)];
    end
    % Validate times
    if isnan(time_plot(1)) || time_plot(1) < min(resampled_time)
        time_plot(1) = min(resampled_time);
    end
    if isnan(time_plot(2)) || time_plot(2) <= time_plot(1) || time_plot(2)>max(resampled_time)
        time_plot(2) = max(resampled_time);
    end
    if nargin>1
    src.String=num2str(time_plot);
    else
        set(h.timeBox_cwt,'String',num2str(time_plot));
    end
    
    exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
    exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
    bad_impedance = results.channels(port_idx).bad_impedance;
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if exclude_impedance_chans_toggle
        mask = mask & ~bad_impedance;
    end
    if exclude_noisy_chans_toggle
        mask =mask & ~noisy;
    end
    channels = channels(mask);

    %  Restrict signals to time range 
    tIdx = resampled_time >= time_plot(1) & resampled_time <= time_plot(2);
    resampled_time = resampled_time(tIdx);

    LFPData = results.signals(port_idx).lfp(mask,:);
    % Get Slider Position
    SeriesNumber = round(get(h.series_slider, 'Value')); % First figure, port number
    current_ch = channels(SeriesNumber); % Finds the corresponding channel name
    resampleFs = results.filt_params(port_idx).ds_freq;
    cla(h.cwt_plots_axes, 'reset'); 
    axes(h.cwt_plots_axes);

    LFPData = LFPData(:,tIdx);
    if ~isfield(h,'cwtCache') || ...
       h.cwtCache.expIdx ~= expIdx || ...
       h.cwtCache.port_idx ~= port_idx || ...
       h.cwtCache.SeriesNumber ~= SeriesNumber || ...
       any(h.cwtCache.time_plot ~= time_plot)
        
        [wt,f] = cwt(LFPData(SeriesNumber,:), resampleFs, ...
                     'FrequencyLimits',[0 300]);
        h.cwtCache.wt = wt;
        h.cwtCache.f = f;
        h.cwtCache.expIdx = expIdx;
        h.cwtCache.port_idx = port_idx;
        h.cwtCache.SeriesNumber = SeriesNumber;
        h.cwtCache.time_plot = time_plot;
    else
        wt = h.cwtCache.wt;
        f = h.cwtCache.f;
    end

    [minf maxf]=cwtfreqbounds(numel(LFPData(SeriesNumber, :)),resampleFs);
   % pick powers of 2 within [minf,maxf]
    yticks = 2.^round(log2(minf):log2(maxf));
    yticks = yticks(yticks>=minf & yticks<=maxf);
    set(h.cwt_plots_axes,'YTick',yticks, 'YScale','log');
    surface(resampled_time,f,abs(wt));
    shading flat
    axis tight
    % imagesc(T, F, pow2db(P));
    set(h.cwt_plots_axes,'YDir','normal')
    c=colorbar;
%    caxis([0 round(max(power_dB(:))*1.1)])
    c.Label.String='|Wavelet Coefficients|';
    c.FontSize = 12;
    xlabel(h.cwt_plots_axes, 'Time (s)', 'FontSize', 12);
    ylabel(h.cwt_plots_axes, 'Frequency (Hz)', 'FontSize', 12);
    %spectrogram(LFPData(SeriesNumber, :), spWindow, [], [], resampleFs, 'yaxis'); % compute spectrogram
    ylim(h.cwt_plots_axes, [1 300]);
    colormap(jet);
    axtoolbar({'datacursor','save','zoomin','zoomout','restoreview','pan'});
    title(['Port ' num2str(results.ports(port_idx).port_id) ' Ch ' num2str(current_ch)])


end