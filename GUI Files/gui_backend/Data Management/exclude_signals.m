function exclude_signals(h)
wb = waitbar(0,'Excluding channels...');
drawnow;


h = guidata(h.figure);  

idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);

expIdx = selected(1,1);
port_idx = selected(1,2); 
if size(selected,1)>1 && ~isfield(h, 'warnedMultiplePorts')
    h.warnedMultiplePorts = true;
    warningdlg(sprintf('Multiple ports selected, using first port only.'));
    guidata(h.figure,h)
end
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
    port = results.ports(port_idx).port_id;
else
    results = h.figure.UserData;
    port = results.ports(port_idx).port_id;
end

 % Check if the user wants to analyze only good channels
exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
channels = results.channels(port_idx).id;
mask = true(1,numel(channels));
if exclude_noisy_chans_toggle || exclude_impedance_chans_toggle
bad_impedance = results.channels(port_idx).bad_impedance;
noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
if exclude_impedance_chans_toggle
    mask = mask & ~bad_impedance;
end
if exclude_noisy_chans_toggle
    mask =mask & ~noisy;
end
channels = channels(mask);
T = numel(channels);
% Set slider properties
set(h.series_slider, 'Max', T);
set(h.series_slider, 'SliderStep', [1/(T-1), 1/(T-1)]);
% Update series number and text
SeriesNumber = 1;
sertxt = [num2str(port), ':', num2str(channels(SeriesNumber))];
set(h.series_slider, 'Value', SeriesNumber);
set(h.series_text,'String',sertxt);
waitbar(0.5, wb, 'Updating traces...');
update_traces_tab(h)
waitbar(0.9, wb, 'Generating plots...');
pop_graph_callback(h)
delete(wb);
end
end