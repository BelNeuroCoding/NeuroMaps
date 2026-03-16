function init_traces_tab(h)
h = guidata(h.figure);

% Get results
results = h.figure.UserData;
if ~iscell(results), results = {results}; end

% Choose default experiment and port
expIdx = 1;
port_idx = 1;

% Determine which panels exist
sig = results{expIdx}.signals(port_idx);
nPanels = 0;
if isfield(sig,'raw'), nPanels = nPanels + 1; end
if isfield(sig,'ref'), nPanels = nPanels + 1; end
if isfield(sig,'hpf'), nPanels = nPanels + 1; end
if isfield(sig,'lfp'), nPanels = nPanels + 1; end

% Create axes only once
h.adjusted_axes = gobjects(1,nPanels);
h.trLines = struct(); % store line handles

panelIdx = 1;
tiled = tiledlayout(h.traces_tab, nPanels, 1, ...
    'Padding','compact','TileSpacing','compact');

% Define publication-ready defaults
lw.main  = 1.25;
lw.thresh = 0.75;
fs.labels = 11;
fs.ticks  = 9;

% - Raw -
if isfield(sig,'raw')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    h.trLines.raw = plot(h.adjusted_axes(panelIdx), nan, nan, ...
        'Color','k','LineWidth',lw.main);
    ylabel('Voltage (\muV)','FontSize',fs.labels);
    set_pubstyle(h.adjusted_axes(panelIdx),fs);
    h.trTitles.raw = title(h.adjusted_axes(panelIdx), '');
    panelIdx = panelIdx+1;

end

% - Ref -
if isfield(sig,'ref')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    hold(h.adjusted_axes(panelIdx),'on');
    h.trLines.ref = plot(h.adjusted_axes(panelIdx), nan, nan, ...
        'Color',[0 0.2 0.7],'LineWidth',lw.main);
    % Threshold lines
    h.trLines.ref_thresh = gobjects(4,1);
    for i=1:2
        h.trLines.ref_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, ...
            'Color',[0.8 0 0],'LineWidth',lw.thresh,'Tag','ThresholdLine');
    end
    for i=3:4
        h.trLines.ref_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, ...
            'Color',[0.2 0.4 0.8],'LineWidth',lw.thresh,'Tag','ThresholdLine');
    end
    ylabel('Voltage (\muV)','FontSize',fs.labels);
    set_pubstyle(h.adjusted_axes(panelIdx),fs);
    h.trTitles.ref = title(h.adjusted_axes(panelIdx), '');
    panelIdx = panelIdx+1;


else
    xlabel('Time (s)','FontSize',fs.labels);
end

% - Spike / HPF -
if isfield(sig,'hpf')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    hold(h.adjusted_axes(panelIdx),'on');
    h.trLines.hpf = plot(h.adjusted_axes(panelIdx), nan, nan, ...
        'Color','k','LineWidth',lw.main);
    h.trLines.hpf_thresh = gobjects(4,1);
    for i=1:2
        h.trLines.hpf_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, ...
            'Color',[0.8 0 0],'LineWidth',lw.thresh,'Tag','ThresholdLine');
    end
    for i=3:4
        h.trLines.hpf_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, ...
            'Color',[0.2 0.4 0.8],'LineWidth',lw.thresh,'Tag','ThresholdLine');
    end
    ylabel('Voltage (\muV)','FontSize',fs.labels);
    set_pubstyle(h.adjusted_axes(panelIdx),fs);
    h.trTitles.hpf = title(h.adjusted_axes(panelIdx), '');
    panelIdx = panelIdx+1;


end

% - LFP -
if isfield(sig,'lfp')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    h.trLines.lfp = plot(h.adjusted_axes(panelIdx), nan, nan, ...
        'Color','k','LineWidth',lw.main);
    ylabel('Voltage (\muV)','FontSize',fs.labels);
    xlabel('Time (s)','FontSize',fs.labels);
    set_pubstyle(h.adjusted_axes(panelIdx),fs);
    h.trTitles.lfp = title(h.adjusted_axes(panelIdx), '');

end

xlabel('Time (s)','FontSize',fs.labels);

% Store updated handles
guidata(h.figure,h);
end

%  Helper: Apply publication style formatting
function set_pubstyle(ax,fs)
    set(ax,'Box','off','TickDir','out','LineWidth',0.75, ...
        'FontSize',fs.ticks,'FontName','Arial');
    axtoolbar(ax,{'save','zoomin','zoomout','restoreview','pan'});
end
