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
ind_pl = find(maps == channels(SeriesNumber));
plot(h.probe_map_axes, x_coords(ind_pl), y_coords(ind_pl), 'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'r');  % Red circles at current ch+1 - current_ch starts at 0.
hold(h.probe_map_axes, 'off');
update_traces_tab(h);
update_power_spectrum_tab(h);
guidata(h.figure,h)

end
