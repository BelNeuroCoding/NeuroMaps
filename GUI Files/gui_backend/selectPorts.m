function selectPorts(src, h)
% SELECTPORTS - Callback when user selects ports in the listbox
% src: handle to the port listbox
% h: GUI handles
h = guidata(h.figure);  

% Get the selected indices in the listbox
selectedIdx = src.Value;

% Get the mapping from listbox to actual [expIdx, portIdx]
mapping = src.UserData;  % Nx2 array: [expIdx, portIdx]

% Translate listbox selection to actual experiments and ports
selectedPorts = mapping(selectedIdx,:);  % each row = [expIdx, portIdx]

% Store in GUI for later use
h.selectedPorts = selectedPorts;

% Save updated handles
guidata(h.figure, h);
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]

% Format Toggle for First Selection
selected = map(idx,:);
expIdx = selected(1,1);
portIdx = selected(1,2);  
results = get(h.figure,'UserData'); 
if ~iscell(results), results = {results}; end
if isfield(results{expIdx},'signals')
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

T = size(results{expIdx}.signals(portIdx).raw, 1); %channels in experiments 
unique_ports = [results{expIdx}.ports(portIdx).port_id];
all_channels = [results{expIdx}.channels(portIdx).id];
set(h.series_slider, 'Max', T)
set(h.series_slider, 'SliderStep', [1/(T-1), 1/(T-1)])
set(h.series_slider, 'Value', 1)
SeriesNumber = 1;
sertxt = [num2str(unique_ports), ':', num2str(all_channels(SeriesNumber))];
set(h.series_slider, 'Value', SeriesNumber)
set(h.series_text,'String',sertxt)
set(h.series_slider, 'Visible', 'on')
set(h.series_text, 'Visible', 'on')
end
end
