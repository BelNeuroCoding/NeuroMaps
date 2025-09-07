function init_traces_tab(h)
% Call this once when GUI loads or new data is loaded

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
tiled = tiledlayout(h.traces_tab, nPanels, 1, 'Padding','compact','TileSpacing','compact');

% - Raw -
if isfield(sig,'raw')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    h.trLines.raw = plot(h.adjusted_axes(panelIdx), nan, nan, 'k','LineWidth',1);
    ylabel('Voltage (\muV)');
    panelIdx = panelIdx+1;
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

end

% - Ref -
if isfield(sig,'ref')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    hold(h.adjusted_axes(panelIdx),'on');
    h.trLines.ref = plot(h.adjusted_axes(panelIdx), nan, nan, 'b','LineWidth',0.5);
    % Threshold lines
    h.trLines.ref_thresh = gobjects(4,1);
    for i=1:2
        h.trLines.ref_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, 'r','LineWidth',1,'Tag','ThresholdLine');
    end
    for i=3:4
        h.trLines.ref_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, 'b','LineWidth',1,'Tag','ThresholdLine');
    end
    ylabel('Voltage (\muV)');
    panelIdx = panelIdx+1;
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

end

% - Spike / HPF -
if isfield(sig,'hpf')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    hold(h.adjusted_axes(panelIdx),'on');
    h.trLines.hpf = plot(h.adjusted_axes(panelIdx), nan, nan, 'k','LineWidth',1);
    % Threshold lines
    h.trLines.hpf_thresh = gobjects(4,1);
    for i=1:2
        h.trLines.hpf_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, 'r','LineWidth',1,'Tag','ThresholdLine');
    end
    for i=3:4
        h.trLines.hpf_thresh(i) = plot(h.adjusted_axes(panelIdx), nan, nan, 'b','LineWidth',1,'Tag','ThresholdLine');
    end
    ylabel('Voltage (\muV)');
    panelIdx = panelIdx+1;
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

end

% - LFP -
if isfield(sig,'lfp')
    h.adjusted_axes(panelIdx) = nexttile(tiled,panelIdx);
    h.trLines.lfp = plot(h.adjusted_axes(panelIdx), nan, nan, 'k','LineWidth',1);
    ylabel('Voltage (\muV)'); xlabel('Time (s)');
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});

end

% Store updated handles
guidata(h.figure,h);
end
