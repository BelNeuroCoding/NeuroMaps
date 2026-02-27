function bandpower_callback(h)
    h = guidata(h.figure);
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
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
    port_idx = selected(1,2);      
    
    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    bad_impedance = results.channels(port_idx).bad_impedance;
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if h.excl_imp_toggle.Value
        mask = mask & ~bad_impedance;
    end
    if h.excl_high_STD_toggle.Value
        mask =mask & ~noisy;
    end
    lfp_data = results.signals(port_idx).lfp(mask,:);
    channels = results.channels(port_idx).id(mask);
    num_channels = size(lfp_data,1);
    
    %  Default bands and labels 
    default_bands = {'1 4','4 8','8 12','12 30','30 100'};
    labels = {'Delta','Theta','Alpha','Beta','Gamma'};
    fs_lfp = results.filt_params(port_idx).ds_freq;

    %  User input for frequency bands 
    prompt = strcat(labels,' (Hz):');
    dlgtitle = 'Set Frequency Bands';
    dims = [1 20];
    answer = inputdlg(prompt, dlgtitle, dims, default_bands);
    if isempty(answer), return; end
    
    num_bands = length(labels);
    bands = zeros(num_bands,2);
    for b = 1:num_bands
        freq_range = str2num(answer{b}); %#ok<ST2NM>
        if isempty(freq_range) || length(freq_range) ~= 2
            warning('Invalid input for %s. Using default range.', labels{b});
            freq_range = str2num(default_bands{b}); %#ok<ST2NM>
        end
        bands(b,:) = freq_range;
    end

    %  Load probe coordinates for interpolation 
    probe_maps = get(h.probe_map, 'Data');   % cell array of file paths
    if ~isempty(probe_maps)
        matFile = probe_maps{2};   % second row (.mat file)
    else
        matFile = 'sparse_x_y_coords.mat';
    end
    load(matFile, 'x_coords', 'y_coords', 'maps');
    band_names = [{'Total'}, labels];

    if ~isfield(h,'band_tabgroup') || ~isvalid(h.band_tabgroup)
        h.band_tabgroup = uitabgroup('Parent', h.bandpower_tab, ...
                                     'Units','normalized', ...
                                     'Position',[0 0 1 1]);
        h.band_subtabs = gobjects(1,num_bands+1);
        h.band_axes = gobjects(1,num_bands+1);
        for b = 1:num_bands+1
            if b>1
                tit = 'Normalised ';
            else 
                tit = '';
            end
            h.band_subtabs(b) = uitab('Parent', h.band_tabgroup, ...
                                      'Title',[tit band_names{b}], ...
                                      'BackgroundColor',[1 1 1], ...
                                      'ForegroundColor',[0.1,0.4,0.6]);
            h.band_axes(b) = axes('Parent', h.band_subtabs(b), ...
                                  'Units','normalized', ...
                                  'Position',[0.08 0.2 0.85 0.75]);
        end
            h.bandpower_plot_button = uicontrol('Style', 'pushbutton','Parent', h.bandpower_tab,'String', 'Compute', ...
            'Units', 'normalized','Position', [0.80, 0.05, 0.18, 0.05], ... % Adjust position as needed
            'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
            'Callback', @(src, event) bandpower_callback(h));
            h.time_resolved_bandpower = uicontrol('Style', 'checkbox','Parent', h.bandpower_tab,'Units', 'normalized', ...
                'Position', [0.05 0.05 0.5 0.04], 'BackgroundColor', backgdcolor, 'ForegroundColor', accentcolor, ...
                'FontName', 'Cambria', 'FontSize', 11, 'String', 'Time-resolved', 'Value', 0); 
    else
        % Clear old plots only
        for b = 1:num_bands+1
            axes(h.band_axes(b));       % make it current
            cla(h.band_axes(b), 'reset');  % clears content **and** resets most axes properties
            colormap(h.band_axes(b), 'default');  
        end
    end
    
   

    if ~h.time_resolved_bandpower.Value
        %  Compute power 
        power_in_bands = zeros(num_channels, num_bands+1);  % col1 = total
        for ch = 1:num_channels
            [pxx,f] = pwelch(lfp_data(ch,:), hamming(2*fs_lfp), fs_lfp, 2^nextpow2(2*fs_lfp), fs_lfp);
            idx = f >= 1 & f < 300;
            power_in_bands(ch,1) = trapz(f(idx), pxx(idx));
            for b = 1:num_bands
                idx = f >= bands(b,1) & f < bands(b,2);
                power_in_bands(ch,b+1) = trapz(f(idx), pxx(idx))/power_in_bands(ch,1);
            end
        end
        for b=1:num_bands+1
            if b>2
                tit = 'Normalised ';
            else
                tit = '';
            end
            axes(h.band_axes(b))
            plot_interp_heatmap(power_in_bands(:,b), channels, [tit band_names{b}], x_coords, y_coords);
            axis(h.band_axes(b),'square');
        end
    else 
        %  Time-resolved mode 
        winLength = 2*fs_lfp;
        overlap   = fs_lfp;  % 50%
        numTimeWindows = floor((size(lfp_data,2)-winLength)/ (winLength-overlap)) + 1;
        
        bp = zeros(num_channels, num_bands+1, numTimeWindows);
        
        for ch = 1:num_channels
            [sxx,f,t] = spectrogram(lfp_data(ch,:), hamming(winLength), ...
                                    overlap, 2^nextpow2(winLength), fs_lfp);
            sxx = abs(sxx).^2 / winLength;
            idx = f >= 1 & f < 300;
            total_power = trapz(f(idx), sxx(idx,:));  
            bp(ch,1,:) = total_power;            
            for b = 1:num_bands
                idx = f >= bands(b,1) & f < bands(b,2);
                band_power =  trapz(f(idx), sxx(idx,:));
                bp(ch,b+1,:) = band_power./total_power;
            end
        end
        for b = 1:num_bands+1
            if b>2
                tit = 'Normalised ';
            else
                tit = '';
            end
            axes(h.band_axes(b));                 % select axes
            cla(h.band_axes(b), 'reset');         % clear old content
            M = squeeze(bp(:,b,:));                  % [channels x time]
            upper = prctile(M(:), 99);  % cap at 99th percentile
            imagesc(t, 1:num_channels, M);          % X=time, Y=channel
            axis xy                                 % channel 1 at bottom
            xlabel('Time (s)');
            ylabel('Channel');
            title([tit band_names{b}]);
            yticks(1:num_channels);          % row positions
            yticklabels(channels);            % show actual channel IDs
            clim([0 ceil(upper)]);
            colorbar;
        end
    end
    guidata(h.figure,h)
    %  Display table + save button 
    if exist('power_in_bands','var')
    T = array2table([channels' power_in_bands], 'VariableNames', [{'Channels'} band_names]);
    if isfield(h,'bandpower_table_fig') && isvalid(h.bandpower_table_fig)
        delete(h.bandpower_table_fig)
    end
    h.bandpower_table_fig = figure('Name','Bandpower Table','NumberTitle','off',...
                                   'MenuBar','figure','ToolBar','figure',...
                                   'Position',[100 100 400 600]);
    h.bandpower_table = uitable('Parent', h.bandpower_table_fig, ...
        'Data', T{:,:}, ...
        'ColumnName', T.Properties.VariableNames, ...
        'Units','normalized', ...
        'Position',[0.05 0.55 0.9 0.4]);
    h.save_table_btn = uicontrol('Style','pushbutton', ...
        'Parent', h.bandpower_table_fig, ...
        'String','Save Table', ...
        'Units','normalized', ...
        'Position',[0.4 0.5 0.2 0.05], ...
        'Callback', @(src,event) saveBandPowerTable(T));
    end
    %  Callback to save table 
    function saveBandPowerTable(T)
        [filename, pathname] = uiputfile('*.csv','Save Band Power Table As');
        if ischar(filename)
            writetable(T, fullfile(pathname, filename));
        end
    end
end
