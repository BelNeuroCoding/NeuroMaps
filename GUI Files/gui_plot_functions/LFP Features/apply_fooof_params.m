function apply_fooof_params(h)
    % Read edit boxes
    h.settings.peak_width_limits = str2num(h.peak_width.String); %#ok<ST2NM>
    h.settings.max_n_peaks = str2double(h.max_peaks.String);
    h.settings.min_peak_height = str2double(h.min_peak_height.String);
    h.settings.peak_threshold = str2double(h.peak_thresh.String);
    h.settings.aperiodic_mode = h.aperiodic_mode.String{h.aperiodic_mode.Value};
    h.settings.verbose = h.verbose.Value;

    % Optional: validate
    if numel(h.settings.peak_width_limits) ~= 2 || any(h.settings.peak_width_limits <= 0)
        warndlg('Peak width must be two positive numbers [min,max].','Invalid Input');
        return;
    end
    if h.settings.min_peak_height < 0
        warndlg('Min peak height must be >= 0','Invalid Input');
        return;
    end
    % Update handles
    guidata(h.figure,h);
    msgbox('FOOOF parameters applied.','Success');
end