function run_spike_analysis(h)
h = guidata(h.figure);  
set_status(h.figure,"loading","Spike Analysis in Progress...");

% Get selected ports
idx = h.portList.Value;        % listbox indices
map = h.portList.UserData;     % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);

if size(selected,1) > 1
    choicesStr = cell(size(selected,1),1);
    for i = 1:size(selected,1)
        expIdxTmp = selected(i,1);
        portIdxTmp = selected(i,2);
        if iscell(h.figure.UserData)
            resultsTmp = h.figure.UserData{expIdxTmp};
        else
            resultsTmp = h.figure.UserData;
        end
        portID = resultsTmp.ports(portIdxTmp).port_id;
        choicesStr{i} = sprintf('Exp %d, Port %d', expIdxTmp, portID);
    end

    % Ask user which one to use
    sel = listdlg('PromptString','Multiple experiments/ports selected. Choose one:', ...
                  'SelectionMode','single', 'ListString', choicesStr);
    if isempty(sel)
        return; % user cancelled
    end
    expIdx = selected(sel,1);
    selected_idx = selected(sel,2);
else
    expIdx = selected(1,1);
    selected_idx = selected(1,2);
end

%  Load results 
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else
    results = h.figure.UserData;
end
selectedport = results.ports(selected_idx).port_id;
Channels = results.channels(selected_idx).id;

try
    if isfield(results.signals,'ref')
        %  Ask user what to analyse (Filtered or Referenced) 
        choice = questdlg('Which data do you want to use for spike analysis?', ...
                          'Spike Analysis Data', ...
                          'Filtered', 'Referenced', 'Filtered');
        switch choice
            case 'Filtered'
                filteredObservations = results.signals(selected_idx).hpf;
            case 'Referenced'
                if isfield(results.signals(selected_idx), 'ref')
                    filteredObservations = results.signals(selected_idx).ref;
                else
                    errordlg('No referenced signals available for this dataset.');
                    return;
                end
            otherwise
                disp('User cancelled spike analysis.');
                return;
        end
    else
        choice = 'Filtered';
        filteredObservations = results.signals(selected_idx).hpf;
    end
catch
    errordlg('No Signal Detected. Filter and Try Again')
    set_status(h.figure,"error","Spike Analysis Error");

    return;
end

[num_channels, N] = size(filteredObservations);

% Convert STDEV string to a number
STDEVmin = str2double(get(h.std_value,'String'));
STDEVmax = str2double(get(h.stdmax_value,'String'));

% Compute the threshold observations using vectorized operations
if exist('spike_config.mat','file')
    cfg = load('spike_config.mat');
    cfg = cfg.config;  % unpack struct
else
    % fallback defaults
    cfg.pre_time = 0.8;
    cfg.post_time = 0.8;
end

fs = round(results.fs);

% Check if the user wants to analyze only good channels
exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');

bad_impedance = results.channels(selected_idx).bad_impedance;
noisy = results.channels(selected_idx).high_psd & results.channels(selected_idx).high_std;
mask = true(1,numel(Channels));
if exclude_impedance_chans_toggle
    mask = mask & ~bad_impedance;
end
if exclude_noisy_chans_toggle
    mask =mask & ~noisy;
end
set_status(h.figure,"loading","Detection in progress...");

% Spike detection
waveforms = detect_spks(filteredObservations(mask,:), fs, cfg.pre_time, cfg.post_time,[STDEVmin, STDEVmax], Channels(mask));
if numel(waveforms)<2
    warndlg('No spikes were detected for the selected settings.', ...
            'Spike Analysis');
    return; % stop here, don’t run the rest
end

% Store results if spikes exist
results.spike_results(selected_idx).waveforms_all = waveforms;

% Save updated results
if iscell(h.figure.UserData)
    allresults = h.figure.UserData;
    allresults{expIdx} = results;
    set(h.figure, 'UserData', allresults);
else
    set(h.figure, 'UserData', results);
end

%% Main Spike Tabs
if ~isfield(h,'spike_detection_tab') || ~isvalid(h.spike_detection_tab)
create_spike_tabs(h)
end
h=guidata(h.figure);
%% Plot Functions
set_status(h.figure,"loading","Computing Spike Features...");
spike_feats_callback(h);
h=guidata(h.figure);
update_spike_summary_tab(h);
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
compute_sttc_latency(h)

set_status(h.figure,"loading","Computing Network Connectivity...");

currentText = get(h.summary_text,'String');
if ischar(currentText)
    currentText = cellstr(currentText);
end

% Build summary
excludedChans = sum(~mask); % number of channels excluded
newMsg = sprintf(['Performed Spike Analysis on %s Data - Port %s\n' ...
                  'STDEV thresholds: [%g, %g], Number of Channels excluded: %d'], ...
                  choice, num2str(selectedport), STDEVmin, STDEVmax, excludedChans);

% Append to summary
currentText{end+1} = newMsg;
set(h.summary_text,'String',currentText);
guidata(h.figure,h)
set_status(h.figure,"ready","Spike Detection Step Complete...");

end
