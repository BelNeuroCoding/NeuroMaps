function update_slider(h,src)
    h = guidata(h.figure);  

    val = src.String;
    tokens = regexp(val, '(\d+):(\d+)', 'tokens');
    if isempty(tokens)
        % Bad input: reset to current slider value
        set(src, 'String', sprintf('%d:%d', h.currentPort, h.currentChan));
        return;
    end
    port = str2double(tokens{1}{1});
    chan = str2double(tokens{1}{2});
    results = get(h.figure,'UserData');
    Ports = [results.ports.port_id];
    port_idx = find(Ports==port);
    if isempty(port_idx)
        errordlg('Cannot find port')
        return;
    end
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
    exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
    if exclude_impedance_chans_toggle
        bad_impedance = results.channels(port_idx).bad_impedance;
        mask = mask & ~bad_impedance;
    end
    if exclude_noisy_chans_toggle
        noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
        mask =mask & ~noisy;
    end
    channels = channels(mask);
    SeriesNumber = find(channels == chan);
    if isempty(SeriesNumber)
        errordlg('Cannot find Channel');
        return;
    end
    set(h.series_slider,'Value',SeriesNumber);
    ind_pl = find(h.maps == channels(SeriesNumber));
    set(h.marker, 'XData', h.x_coords(ind_pl), 'YData', h.y_coords(ind_pl));
    guidata(h.figure,h)
    activeTab = h.tabgroup1.SelectedTab;
    if strcmp(activeTab.Title, 'Signal Traces')
        update_traces_tab(h);
    end
    if strcmp(activeTab.Title, 'Frequency Analysis')
        if strcmp(h.SpectralTabs.SelectedTab.Title,'CWT')
            plot_cwt(h);
        elseif strcmp(h.SpectralTabs.SelectedTab.Title,'Spectrogram')
            plot_specgram(h);
        elseif strcmp(h.SpectralTabs.SelectedTab.Title,'FOOOF Analysis')
            PlotFooof_callback(h);
        else
            update_power_spectrum_tab(h);
        end
    end
end