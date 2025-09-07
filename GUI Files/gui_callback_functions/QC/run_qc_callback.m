function run_qc_callback(h)
%% Perform QC on selected ports across experiments, plotting per port in tiled layout

h = guidata(h.figure);

% Get selected ports from listbox
idx = h.portList.Value;                  % selected rows in the listbox
map = h.portList.UserData;               % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);                   % rows correspond to each selected port

%  signal type
lab = get(h.formatToggleGroup, 'SelectedObject').String;
if isempty(lab)
    lab = questdlg('What would you like to perform QC on?', ...
                   'Plot Selection','Raw','Filtered','Referenced','Raw');

end

% Load all results
all_Results = get(h.figure,'UserData');
if ~iscell(all_Results)
    all_Results = {all_Results};
end

numTiles = size(selected,1);
wb = waitbar(0, 'Running QC...','Name','QC Progress');

%  Loop through selected ports 
for i = 1:numTiles
    expIdx = selected(i,1);
    portIdx = selected(i,2);

    results = all_Results{expIdx};
    port_chans = results.channels(portIdx).id;

    % Select signals
    switch lab
        case {'Raw','AC Filtered'}
            signals = results.signals(portIdx).raw;
        case 'LFP'
                    signals = results.signals(portIdx).lfp;
        case 'Spikes'
                    signals = results.signals(portIdx).hpf;           
        case 'Referenced'
            signals = results.signals(portIdx).ref;
        otherwise
            error('Unexpected toggle state.');
    end

    %  Compute QC 
    fs = round(results.fs);
    impedances = results.electrical_properties(portIdx).electrode_impedance;
    [good_channels,bad_chs] = evaluate_chans(port_chans, impedances, signals', fs, 1);

    results.channels(portIdx).bad_impedance = ismember(port_chans,bad_chs.bad_channels_impedance);
    results.channels(portIdx).high_psd = ismember(port_chans,bad_chs.bad_channels_psd);
    results.channels(portIdx).high_std = ismember(port_chans,[bad_chs.bad_channels_std,bad_chs.bad_channels_mad]);
    results.channels(portIdx).dead_chans = ismember(port_chans,[bad_chs.channels_dead]);
    all_Results{expIdx} = results; % store back

    %  Update waitbar 
    waitbar(i/numTiles, wb, sprintf('Processing %d of %d ports...', i, numTiles));
    % Save updated results
    if iscell(h.figure.UserData)
        allresults = h.figure.UserData;
        allresults{expIdx} = results;
        set(h.figure, 'UserData', allresults);
    else
        set(h.figure, 'UserData', results);
    end
end
delete(wb);

guidata(h.figure,h)
run_qc_plot(h)
end

