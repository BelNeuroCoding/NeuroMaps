function pspec_settings_callback(h)
    h = guidata(h.figure);

    % Defaults (or previous settings)
    if isfield(h,'pspec_props')
        p = h.pspec_props;
    else
        p.fmin = 1;
        p.fmax = 1000;
        p.xscale = 'log';
        p.yscale = 'log';
        p.showWelch = true;
        p.linewidth = 1.5;
        p.winLen = 2;       % seconds
        p.stepLen = 0.5;    % seconds
    end

    % Create Settings Figure
    f = uifigure('Name','PSD Settings','Position',[100 100 360 400]);

    yPos = 350; deltaY = 40;

    % Frequency range
    uilabel(f,'Position',[20 yPos 120 20],'Text','F min (Hz)');
    ef_fmin = uieditfield(f,'numeric','Value',p.fmin,'Position',[150 yPos 120 22]);
    yPos = yPos - deltaY;
    uilabel(f,'Position',[20 yPos 120 20],'Text','F max (Hz)');
    ef_fmax = uieditfield(f,'numeric','Value',p.fmax,'Position',[150 yPos 120 22]);
    yPos = yPos - deltaY;

    % Scale dropdowns
    uilabel(f,'Position',[20 yPos 120 20],'Text','X Scale (log/linear)');
    dd_xscale = uidropdown(f,'Items',{'log','linear'},'Value',p.xscale,'Position',[150 yPos 120 22]);
    yPos = yPos - deltaY;
    uilabel(f,'Position',[20 yPos 120 20],'Text','Y Scale (log/linear)');
    dd_yscale = uidropdown(f,'Items',{'log','linear'},'Value',p.yscale,'Position',[150 yPos 120 22]);
    yPos = yPos - deltaY;

    % Welch PSD checkbox
    cb_welch = uicheckbox(f,'Text','Show Welch PSD','Value',p.showWelch,'Position',[150 yPos 150 22]);
    yPos = yPos - deltaY;

    % Line width
    uilabel(f,'Position',[20 yPos 120 20],'Text','Line Width');
    ef_lw = uieditfield(f,'numeric','Value',p.linewidth,'Limits',[0.5 10],'Position',[150 yPos 120 22]);
    yPos = yPos - deltaY;

    % Window length
    uilabel(f,'Position',[20 yPos 120 20],'Text','Window Length (s)');
    ef_win = uieditfield(f,'numeric','Value',p.winLen,'Limits',[0.1 20],'Position',[150 yPos 120 22],...
        'Tooltip','Length of each segment for PSD calculation. Longer windows = smoother frequency resolution, less temporal resolution.');
    yPos = yPos - deltaY;

    % Step length
    uilabel(f,'Position',[20 yPos 120 20],'Text','Step Length (s)');
    ef_step = uieditfield(f,'numeric','Value',p.stepLen,'Limits',[0.01 10],'Position',[150 yPos 120 22],...
        'Tooltip','Step size between segments for PSD calculation. Smaller steps = more overlap, smoother average.');
    yPos = yPos - deltaY;

    % Apply Button
    uibutton(f,'Text','Apply','Position',[120 20 100 35], ...
        'ButtonPushedFcn',@(btn,event) apply());

    % Callback
    function apply()
        % Update settings struct
        p.fmin = ef_fmin.Value;
        p.fmax = ef_fmax.Value;
        p.xscale = dd_xscale.Value;
        p.yscale = dd_yscale.Value;
        p.showWelch = cb_welch.Value;
        p.linewidth = ef_lw.Value;
        p.winLen = ef_win.Value;
        p.stepLen = ef_step.Value;

        % Save in guidata
        h.pspec_props = p;
        guidata(h.figure,h);
        close(f)

        % Re-plot
        update_power_spectrum_tab(h);
    end
end