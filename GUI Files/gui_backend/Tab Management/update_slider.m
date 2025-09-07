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
    update_traces_tab(h)
    update_power_spectrum_tab(h)
    plot_specgram(h)
    % Load probe design + coords from what user selected at startup
    probe_maps = get(h.probe_map, 'Data');   % cell array of file paths
    if ~isempty(probe_maps)
    imgFile = probe_maps{1};   % first row (image file)
    matFile = probe_maps{2};   % second row (.mat file)
    else
        imgFile = 'sparseimg.tif';
        matFile = 'sparse_x_y_coords.mat';
    end
    elecdesign = imread(imgFile);
    set(h.probe_map_axes, 'Visible', 'on');
    imshow(elecdesign, 'Parent', h.probe_map_axes);
    hold(h.probe_map_axes, 'on');
    
    load(matFile, 'x_coords', 'y_coords', 'maps');
    
    % Plot markers on the image at specified points
    ind_pl = find(maps == channels(SeriesNumber));
    plot(h.probe_map_axes, x_coords(ind_pl), y_coords(ind_pl), 'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'r');  % Red circles at current ch+1 - current_ch starts at 0.
    hold(h.probe_map_axes, 'off');
    PlotFooof_callback(h)

end