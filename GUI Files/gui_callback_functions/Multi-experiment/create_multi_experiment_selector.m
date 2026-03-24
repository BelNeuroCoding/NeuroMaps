function create_multi_experiment_selector(h)
%% Create UI to select experiments and ports from multi-experiment results
backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
results = get(h.figure,'UserData'); 
if ~iscell(results), results = {results}; end
numExpts = numel(results);
set_status(h.figure,"loading","Setting up GUI...");

%  Experiment Listbox 
expNames = cellfun(@(r) r.metadata.filename, results, 'UniformOutput', false);
if isfield(h,'expList') && isvalid(h.expList), delete(h.expList); end
h.expPanel = uipanel('Parent',h.probe_map_tab,'Title','Experiments','Units','normalized','Position',[0.7 0.05 0.3 0.4],'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor);
h.expList = uicontrol('Parent', h.expPanel, ...
                      'Style', 'listbox', ...
                      'String', expNames, ...
                      'Value', 1, ...
                      'Max', numExpts, 'Min', 0, ...
                      'FontSize', 10, ...
                      'Units','normalized',...
                      'Position', [0.0 0.0 1 1], ...
                      'Callback', @(src,~) update_port_list(h));

%  Port Listbox 
h.portList = uicontrol('Parent', h.portsPanel, 'Style', 'listbox','String', {}, ...
                       'Value', 1, 'Max', 10, 'Min', 0, ...
                       'FontSize', 10, 'Units','normalized', ...
                       'Position', [0 0 1 1],'Callback',@(src,~) selectPorts(src,h));

% % Destroy old step panel if it exists
if isfield(h, 'stepPanel') && isvalid(h.stepPanel)
    delete(h.stepPanel);
end
h.stepPanel = uipanel('Parent', h.figure, ...
    'Units', 'normalized', ...
    'Position', [0.05 0.91 0.90 0.06], ...
    'BackgroundColor', backgdcolor, ...
    'BorderType', 'none');

stepNames = {'Select Experiments','Detect Spikes', 'Analyse LFPs','Validate Curated Spikes'};
nSteps = numel(stepNames);
pad = 0.01; 
btnW = (1 - pad*(nSteps-1))/nSteps; 
btnH = 0.7;

h.stepBtns = gobjects(1, nSteps);
for k = 1:nSteps
    h.stepBtns(k) = uicontrol('Parent', h.stepPanel, 'Style','pushbutton', ...
        'Units','normalized', ...
        'Position', [(k-1)*(btnW+pad), 0.05, btnW, btnH], ...
        'String', stepNames{k}, ...
        'FontName','Arial','FontSize',8, ...
        'BackgroundColor', [1 1 1], ...
        'ForegroundColor', [0.25 0.25 0.25], ...
        'Callback', @(src,evt) stepperGoMulti(k,h));
end

h.stepDone    = false(1,nSteps);
h.stepCurrent = 1;

stepperSet(h);
guidata(h.figure,h);

% Initial port update

update_port_list(h,1);

end

function update_port_list(h,ind)
h = guidata(h.figure);
%% Update port list based on selected experiments
results = get(h.figure,'UserData'); 
if ~iscell(results), results = {results}; end

selectedExpts = h.expList.Value;  % selected experiments
portLabels = {};
mapping = [];

for e = 1:numel(selectedExpts)
    expIdx = selectedExpts(e);
    ports = results{expIdx}.ports;
    for p = 1:numel(ports)
        portLabels{end+1} = sprintf('Exp %d, Port %d', expIdx, ports(p).port_id);
        mapping(end+1,:) = [expIdx, p]; % row = [experiment index, port index within that experiment]
    end
end

set(h.portList,'String',portLabels,'UserData',mapping,'Value',1,'Max',numel(portLabels));
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]

% Format Toggle for First Selection
selected = map(idx,:);
expIdx = selected(1,1);
portIdx = selected(1,2);  
if nargin>1
if isfield(results{expIdx},'signals')
    set_status(h.figure,"loading","Plotting Signals...");
    create_signal_tabs(h);
    h=guidata(h.figure);
    init_traces_tab(h);
    h=guidata(h.figure);
    init_power_spectrum_tab(h);
    h=guidata(h.figure);

    if isfield(results{expIdx}.signals(portIdx),'raw')
        h.formatsPlot.Raw = uicontrol('Style', 'radiobutton', 'String', 'Raw', ...
        'Units', 'normalized', 'Position', [0.01, 0.1, 0.2, 0.8], ...
        'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    end
    if isfield(results{expIdx}.signals(portIdx),'hpf')
        if isfield(h.formatsPlot,'Spikes') && isvalid(h.formatsPlot.Spikes)
                    delete(h.formatsPlot.Spikes);  % remove the old one
       end
       h.formatsPlot.Spikes = uicontrol('Style', 'radiobutton', 'String', 'Spikes', ...
        'Units', 'normalized', 'Position', [0.64, 0.1, 0.2, 0.8], ...
        'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    
    end
    if isfield(results{expIdx}.signals(portIdx),'lfp')
                if isfield(h.formatsPlot,'LFP') && isvalid(h.formatsPlot.LFP)
                    delete(h.formatsPlot.LFP);  % remove the old one
                end
                 h.formatsPlot.LFP = uicontrol('Style', 'radiobutton', 'String', 'LFP', ...
                'Units', 'normalized', 'Position', [0.43, 0.1, 0.2, 0.8], ...
                'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    end
    
    if isfield(results{expIdx}.signals(portIdx),'ref')
        if isfield(h.formatsPlot,'Ref') && isvalid(h.formatsPlot.Ref)
            delete(h.formatsPlot.Ref);  % remove the old one
        end
        h.formatsPlot.Ref = uicontrol('Style', 'radiobutton', 'String', 'Ref', ...
        'Units', 'normalized', 'Position', [0.22, 0.1, 0.2, 0.8], ...
        'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    end
    guidata(h.figure,h);
    pop_graph_callback(h);
    update_traces_tab(h);
    plot_specgram(h);
    noise_plot_callback(h);
end
if isfield(results{expIdx},'spike_results')
    create_spike_tabs(h);
    set_status(h.figure,"loading","Plotting Spike Results...");
    h=guidata(h.figure);
    update_spike_summary_tab(h);
    h=guidata(h.figure);
    set_status(h.figure,"loading","Plotting Spike Waveforms...");
    drawnow limitrate
    plot_spikes_callback(h);
    plot_fr_callback(h);
    plot_amphm_callback(h);
    plot_raster_callback(h);
    
    set_status(h.figure,"loading","Plotting Spike Features...");
    plot_isi_callback(h)
    plot_ibi_callback(h)
    plot_amplitudes_callback(h)
    plot_fwhm_callback(h)
    plot_dvdt_phase(h)
    pop_spiking_plot(h)

end
if isfield(results{expIdx},'foof_lfp')
    create_lfp_foof_tabs(h);
     set_status(h.figure,"loading","Plotting LFP Data...");

    h=guidata(h.figure);
end
if isfield(results{expIdx},'electrical_properties')
    create_ZC_tabs(h);
    set_status(h.figure,"loading","Plotting QC metrics...");
   % h=guidata(h.figure);
    Elec_plot_callback(h);
    run_qc_callback(h);
    run_qc_plot(h);
    h=guidata(h.figure);
end
end
create_cumulative_tabs(h);
h=guidata(h.figure);
unique_ports = [results{expIdx}.ports.port_id];
if isfield(results{expIdx},'channels')
all_channels = [results{expIdx}.channels(portIdx).id];
T = length(all_channels);
set(h.series_slider, 'Max', T)
set(h.series_slider, 'SliderStep', [1/(T-1), 1/(T-1)])
set(h.series_slider, 'Value', 1)
SeriesNumber = 1;
sertxt = [num2str(unique_ports(SeriesNumber)), ':', num2str(all_channels(SeriesNumber))];
set(h.series_slider, 'Value', SeriesNumber)
set(h.series_text,'String',sertxt)
set(h.series_slider, 'Visible', 'on')
set(h.series_text, 'Visible', 'on')
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
ind_pl = find(maps == all_channels(SeriesNumber));
plot(h.probe_map_axes, x_coords(ind_pl), y_coords(ind_pl), 'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'r');  % Red circles at current ch+1 - current_ch starts at 0.
hold(h.probe_map_axes, 'off');
set_status(h.figure,"ready","Ready...");

end


guidata(h.figure,h);
end
 function stepperGoMulti(idx,h)
    h=guidata(h.figure);
    switch idx
        case 1   % Load
            try openSystemSelectionDialog(h); catch, end
            % Focus a relevant tab
            try h.tabgroup1.SelectedTab = h.overview_main_tab; catch, end
        case 2   % Detect Spikes
            try run_spike_analysis(h); catch, end
            h=guidata(h.figure);
            try h.tabgroup1.SelectedTab = h.spike_detection_tab; catch, end
            try h.tabgroup2.SelectedTab = h.spikes_main_tab; catch, end
        case 3   % LFP Analysis
            try fooof_callback(h); catch, end
            h=guidata(h.figure);
        case 4 % Validate Curated Spikes
            try save_curated_spikes(h); catch,end
            h=guidata(h.figure);

    end
    % Track state
    h.stepCurrent = [h.stepCurrent, idx];          % current step index
    % Initial highlight
    stepperSet(h);
    guidata(h.figure,h)
 end
 function stepperSet(h)
% Visually highlight the active step, dim the others
    idx = unique(h.stepCurrent);
    for i = 1:numel(h.stepBtns)
        if ismember(i,idx)
            set(h.stepBtns(i), 'BackgroundColor', hAccent(), 'ForegroundColor',[1 1 1], ...
                'FontWeight','bold');
        else
            set(h.stepBtns(i), 'BackgroundColor', [0.94 0.94 0.94], ...
                'ForegroundColor', [0.25 0.25 0.25], 'FontWeight','normal');
        end
    end
    guidata(h.figure,h);
 end
 function c = hAccent()  
    c = [0.1 0.4 0.6];
end
