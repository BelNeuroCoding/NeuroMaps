function init_power_spectrum_tab(h)
    % Initialize Power Spectrum tab with panel, axes, and pre-created line objects
    h = guidata(h.figure);

    %% Ensure the panel exists
    if ~isfield(h,'ps_panel') || ~isvalid(h.ps_panel)
        h.ps_panel = uipanel(h.pspec_tab, ...
                             'Position',[0.05 0.08 0.9 0.9], ... 
                             'BackgroundColor',[1 1 1]);
    end

    %% Get selected experiment/port (only one allowed here)
    idx = h.portList.Value;
    map = h.portList.UserData;
    selected = map(idx,:);
    expIdx = selected(1,1);
    portIdx = selected(1,2);

    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    %% Apply channel masks
    mask = true(1,numel(results.channels(portIdx).id));
    if get(h.excl_imp_toggle,'Value')
        mask = mask & ~results.channels(portIdx).bad_impedance;
    end
    if get(h.excl_high_STD_toggle,'Value')
        noisy = results.channels(portIdx).high_psd & results.channels(portIdx).high_std;
        mask = mask & ~noisy;
    end
    channels = results.channels(portIdx).id(mask);
    numCh = numel(channels);

    %% Create/clear axes in the panel
    axesToDelete = findobj(h.ps_panel,'Type','axes');
    delete(axesToDelete);
    h.psAxes = axes('Parent',h.ps_panel);
    hold(h.psAxes,'on');

    %% Pre-create line objects for median PSD
    colorsMap = lines(numCh);
    h.psLines = gobjects(numCh,1);
    for ch = 1:numCh
        h.psLines(ch) = loglog(h.psAxes, nan, nan, ...
                                'Color', colorsMap(ch,:), ...
                                'LineWidth',1.5);
    end

    %% Pre-create line object for Welch PSD
    h.psLinesWelch = loglog(h.psAxes, nan, nan, 'r-.', 'LineWidth',1.5);

    %% Axis formatting
    xlabel(h.psAxes,'Frequency (Hz)');
    ylabel(h.psAxes,'Power Spectral Density (a.u.)');
    xlim(h.psAxes,[1 Inf]);  
    grid(h.psAxes,'on');
    axtoolbar(h.psAxes,{'save','zoomin','zoomout','restoreview','pan'});

    guidata(h.figure,h);
end