function slider_callback(~,~,h)

h = guidata(h.figure);  

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

expIdx = selected(1,1);
port_idx = selected(1,2);      % single-experiment mode
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else 
    results =  h.figure.UserData;
end

SeriesNumber = round(get(h.series_slider, 'Value'));
exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
channels = results.channels(port_idx).id;
mask = true(1,numel(channels));

if exclude_impedance_chans_toggle
    bad_impedance = results.channels(port_idx).bad_impedance;
    mask = mask & ~bad_impedance;
end
if exclude_noisy_chans_toggle
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    mask =mask & ~noisy;
end
channels = channels(mask);
T = numel(channels);
% Set slider properties
set(h.series_slider, 'Max', T);
set(h.series_slider, 'SliderStep', [1/(T-1), 1/(T-1)]);
sertxt = [num2str(results.ports(port_idx).port_id),':',num2str(channels(SeriesNumber))];
set(h.series_slider, 'Value', SeriesNumber)
set(h.series_text, 'String', sertxt)
ind_pl = find(h.maps == channels(SeriesNumber));
set(h.marker, 'XData', h.x_coords(ind_pl), 'YData', h.y_coords(ind_pl));
guidata(h.figure,h)

activeTab = h.tabgroup1.SelectedTab;
if strcmp(activeTab.Title, 'Signal Traces')
    update_traces_tab(h);
end
if strcmp(activeTab.Title, 'Frequency Analysis')
    if strcmp(h.SpectralTabs.SelectedTab.Title,'CWT')
        plot_cwt(h);
    elseif strcmp(h.SpectralTabs.SelectedTab.Title,'Spectrogram')
        plot_specgram(h);
    elseif strcmp(h.SpectralTabs.SelectedTab.Title,'FOOOF Analysis')
        PlotFooof_callback(h);
    else
        update_power_spectrum_tab(h);
    end
end
end
