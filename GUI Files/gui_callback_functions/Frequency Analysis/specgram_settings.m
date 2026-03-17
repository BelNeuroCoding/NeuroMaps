function specgram_settings(h)
    h = guidata(h.figure);


    p.winLen = 2;       % seconds
    p.stepLen = 0.5;    % seconds
    p.colormap = 'jet';
    p.fmin = 1;
    p.fmax = 1000;

   

    % Create Settings Figure
    f = uifigure('Name','Spectrogram Settings','Position',[100 100 360 300]);

    yPos = 240; deltaY = 40;

    % Window length
    uilabel(f,'Position',[20 yPos 120 22],'Text','Window Length (s)');
    ef_win = uieditfield(f,'numeric','Value',p.winLen,'Limits',[0.1 20], ...
        'Position',[150 yPos 120 22], ...
        'Tooltip','Length of each segment for spectrogram. Longer windows = smoother frequency resolution, less temporal resolution.');
    yPos = yPos - deltaY;

    % Frequency min
    uilabel(f,'Position',[20 yPos 120 22],'Text','F min (Hz)');
    ef_fmin = uieditfield(f,'numeric','Value',p.fmin,'Position',[150 yPos 120 22]);
    yPos = yPos - deltaY;

    % Frequency max
    uilabel(f,'Position',[20 yPos 120 22],'Text','F max (Hz)');
    if isempty(p.fmax), p.fmax = 0; end
    ef_fmax = uieditfield(f,'numeric','Value',p.fmax,'Position',[150 yPos 120 22], ...
        'Tooltip','Leave 0 to use Nyquist frequency.');
    yPos = yPos - deltaY;

    % Step length
    uilabel(f,'Position',[20 yPos 120 22],'Text','Step Length (s)');
    ef_step = uieditfield(f,'numeric','Value',p.stepLen,'Limits',[0.01 10], ...
        'Position',[150 yPos 120 22], ...
        'Tooltip','Step size between segments. Smaller steps = more overlap, smoother average.');
    yPos = yPos - deltaY;

    % Colormap selection
    uilabel(f,'Position',[20 yPos 120 22],'Text','Colormap');
    dd_colormap = uidropdown(f,'Items',{'jet','parula','hot','hsv','gray'}, ...
        'Value',p.colormap,'Position',[150 yPos 120 22], ...
        'Tooltip','Select colormap for spectrogram display.');
    yPos = yPos - deltaY;

    % Apply button
    uibutton(f,'Text','Apply','Position',[120 20 100 35], ...
        'ButtonPushedFcn',@(btn,event) apply());

    % Callback function
    function apply()
        % Update settings struct
        p.winLen = ef_win.Value;
        p.fmin = ef_fmin.Value;
        p.fmax = ef_fmax.Value;
        p.stepLen = ef_step.Value;
        p.colormap = dd_colormap.Value;

        h.specgram_props = p;
        guidata(h.figure,h);
        close(f);

        % Re-plot spectrogram
        h = plot_specgram(h);
    end
end