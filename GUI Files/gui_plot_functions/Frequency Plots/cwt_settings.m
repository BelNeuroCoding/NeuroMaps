function cwt_settings(h)
   h = guidata(h.figure);
    p.colormap = 'jet';
    p.fmin = 1;
    p.fmax = 300; 

    % Create Settings Figure
    f = uifigure('Name','Spectrogram Settings','Position',[100 100 300 250]);

    yPos = 200; deltaY = 40;

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
        p.fmin = ef_fmin.Value;
        p.fmax = ef_fmax.Value;
        p.colormap = dd_colormap.Value;

        h.cwt_props = p;
        guidata(h.figure,h);
        close(f);

        % Re-plot spectrogram
        plot_cwt(h);
    end
end