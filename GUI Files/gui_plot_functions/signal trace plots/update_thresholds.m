function update_thresholds(h)
    h=guidata(h.figure);    
    % Get selected ports from listbox
    idx = h.portList.Value;                  % selected rows in the listbox
    map = h.portList.UserData;               % Nx2 mapping [expIdx, portIdx]
    selected = map(idx,:);                   % rows correspond to each selected port
    expIdx = selected(1,1);
    port_idx = selected(1,2);
    SeriesNumber = round(get(h.series_slider, 'Value'));
    results = h.figure.UserData;
    if ~iscell(results), results = {results}; end
    results = results{expIdx};
    channels = [results.channels(port_idx).id];
    mask = true(1,numel(channels));
    if get(h.excl_imp_toggle,'Value')
        mask = mask & ~results.channels(port_idx).bad_impedance;
    end
    if get(h.excl_high_STD_toggle,'Value')
        noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
        mask = mask & ~noisy;
    end

    STDEVMIN = str2double(get(h.std_value,'String')); 
    STDEVMAX = str2double(get(h.stdmax_value,'String'));
    %  REF 
    if isfield(results.signals(port_idx),'ref')
        data_ref = results.signals(port_idx).ref; 
        series_ref = data_ref(mask,:);
        med_abs_ref = median(abs(series_ref(SeriesNumber,:))) / 0.6745;
        prange_ref = 1:size(series_ref,2);

        set(h.trLines.ref_thresh(1),'YData', STDEVMIN*med_abs_ref*ones(size(prange_ref)));
        set(h.trLines.ref_thresh(2),'YData', -STDEVMIN*med_abs_ref*ones(size(prange_ref)));
        set(h.trLines.ref_thresh(3),'YData', STDEVMAX*med_abs_ref*ones(size(prange_ref)));
        set(h.trLines.ref_thresh(4),'YData', -STDEVMAX*med_abs_ref*ones(size(prange_ref)));
    end

    %  HPF 
    if isfield(results.signals(port_idx),'hpf')
        data_hpf = results.signals(port_idx).hpf; 
        series_hpf = data_hpf(mask,:);
        med_abs_hpf = median(abs(series_hpf(SeriesNumber,:))) / 0.6745;
        prange_hpf = 1:size(series_hpf,2);

        set(h.trLines.hpf_thresh(1),'YData', STDEVMIN*med_abs_hpf*ones(size(prange_hpf)));
        set(h.trLines.hpf_thresh(2),'YData', -STDEVMIN*med_abs_hpf*ones(size(prange_hpf)));
        set(h.trLines.hpf_thresh(3),'YData', STDEVMAX*med_abs_hpf*ones(size(prange_hpf)));
        set(h.trLines.hpf_thresh(4),'YData', -STDEVMAX*med_abs_hpf*ones(size(prange_hpf)));
    end

    drawnow limitrate;
    set_status(h.figure,"ready","Thresholds Updated...");

end
