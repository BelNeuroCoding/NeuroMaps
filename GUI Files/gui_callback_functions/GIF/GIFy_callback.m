function GIFy_callback(h,src)
h = guidata(h.figure);
set_status(h.figure,"loading","Generating GIF...");

%%  Get selected port 
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);

% Only allow one experiment & port
if size(selected,1) > 1
    uniqueExpts = unique(selected(:,1));
    uniquePorts = unique(selected(:,2));
    if numel(uniqueExpts) > 1 || numel(uniquePorts) > 1
        errordlg('Please select only 1 experiment and 1 port for plotting traces.');
        return
    end
end

expIdx = selected(1,1);
selected_idx = selected(1,2);   

% Load results
if iscell(h.figure.UserData)
    results = h.figure.UserData{expIdx};
else
    results = h.figure.UserData;
end
data = results.spike_results(selected_idx).waveforms_all;
fs = results.fs;
try
duration_sec = max(results.timestamps)-min(results.timestamps);
prompt = {'Visualise spikes every (s) (e.g. 1):',...
    'Time delay between produced frames (s)',...
    'Waveform Color (k for black)'};
dlg_title = 'Gif Time';
num_lines = 1;
default_ans = {'1','1','w'};
answer = inputdlg(prompt, dlg_title, num_lines, default_ans);
    if isempty(answer), return; end % user cancelled
time_window_sec = str2double(answer{1});
frame_delay = str2double(answer{2});
wf_col = answer{3};
cluster_num = get(h.clusterListBox,'Value');
isFirstFrame = true; 
% Ask user where to save the GIF
[filename, pathname] = uiputfile({'*.gif','GIF Files (*.gif)'}, ...
    'Save GIF As', ['spike_rate_evolution_' results.metadata.filename(1:end-4) '_cluster_' num2str(cluster_num) '.gif']);
if isequal(filename,0) || isequal(pathname,0)
    disp('User cancelled GIF save.');
    return;
end
output_gif = fullfile(pathname, filename);
num_windows = floor(duration_sec / time_window_sec);  % Number of 1-sec windows
probe_maps = get(h.probe_map, 'Data');   % cell array of file paths
if ~isempty(probe_maps)
matFile = probe_maps{2};   % second row (.mat file)
imgFile = probe_maps{1};
else
    matFile = 'sparse_x_y_coords.mat';
    imgFile = "sparseimg.tif";
end

load(matFile, 'x_coords', 'y_coords', 'maps');
% Check if organoid_num exists in clustered data
    if ~isempty(cluster_num)
        if isfield(data,'clusters')
        indices = find(ismember([data.clusters], cluster_num));
        data = data(indices);
        end
    end
    % Assuming the length of each spike waveform
    waveform_length = size([data(1).spike_shape],2);  % Adjust according to your data

    % Create the time axis for waveforms
    time_axis = (0:waveform_length-1) / fs;  % Time axis in seconds
    % Loop through the time windows within the recording
    f = figure('Units','normalized','OuterPosition',[0 0 1 1]);
    ax = axes('Parent', f,'Visible','off');
    for t = 1:num_windows
        window_start = (t-1) * time_window_sec;
        window_end = t * time_window_sec;

        % Extract spikes that fall within the current time window
        windowed_idx = find([data.time_stamp] >= window_start & [data.time_stamp] < window_end);
        windowed_channels = [data(windowed_idx).channel];
        % Get unique channels and calculate spike rates
        uniquech = unique(windowed_channels);

        % Calculate mean waveforms for the current time window
        cnt = 1;
        mean_waveforms = [];
        spike_rate = zeros(1, length(uniquech));
        for nch = 1:length(uniquech)
            spike_indices = find(windowed_channels == (uniquech(nch)));
            waveforms = [];
            if ~isempty(spike_indices)
                % Get the corresponding waveforms for the spikes in the current window
                for spkind = spike_indices
                waveforms = [data(spkind).spike_shape];  % Concatenate waveforms
                end
                mean_waveforms(cnt, :) = mean(waveforms, 1);  % Mean along the 1st dimension
                cnt = cnt+1;
            end
            spike_rate(nch) = sum(windowed_channels == uniquech(nch)) / time_window_sec;
        end
 
        % Exit early if figure closed mid-plot
        if ~isvalid(f) || ~isvalid(ax)
            msgbox('GIF generation stopped: figure was closed by user.');
            set_status(h.figure,"error","GIF stopped...");

            return;
        end
        % Generate heatmap with waveform snippets
       % figure(1)
       if time_window_sec<1
           ptp_amp = max(mean_waveforms,[],2)-min(mean_waveforms,[],2);
           plot_heatmap_simplified_waveform(ptp_amp, uniquech, 'Peak-to-peak Amplitude (\mu V)', ['Heatmap with Waveforms T ' num2str((t-1) * time_window_sec)], mean_waveforms, time_axis,imgFile,x_coords,y_coords,wf_col);
           caxis([0 1000]);
       else
            plot_heatmap_simplified_waveform(spike_rate, uniquech, 'Spike Rate (Hz)', ['Heatmap with Waveforms  T ' num2str((t-1) * time_window_sec)], mean_waveforms, time_axis,imgFile,x_coords,y_coords,wf_col);
             % Set color limits for heatmap (adjust if necessary)
             caxis([0 3]);
       end


        % Capture the plot as an image
        frame = getframe(f);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, 256);  % Convert image to indexed image

        % Write the frame to the GIF
        if isFirstFrame
            % Initialize GIF by writing the first frame
            imwrite(imind, cm, output_gif, 'gif', 'Loopcount', inf, 'DelayTime', frame_delay);
            isFirstFrame = false;  % Mark that the first frame has been written
        else
            % Append subsequent frames
            imwrite(imind, cm, output_gif, 'gif', 'WriteMode', 'append', 'DelayTime', frame_delay);
        end

        %close(gcf);  % Close the figure to save memory
    end
catch
         set_status(h.figure,"error","GIF generation cancelled...");
         return
end
 set_status(h.figure,"ready","GIF generation complete...");

end