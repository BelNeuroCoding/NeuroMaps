function load_data_callback(h)
% LOAD_DATA_CALLBACK: GUI callback for loading electrophysiology data files.
%
% This function handles data loading for multiple measurement systems (RHS,
% MCS, RHD) - only RHS and RHD have been tested.
% supporting both single and multiple file selections. It automatically:
%   - Opens a file selection dialog filtered by system-specific extensions.
%   - Reads data using the appropriate system-specific loader function.
%   - Concatenates multiple files if needed.
%   - Extracts timestamps, amplifier channels, and electrode impedance/phase.
%   - Calculates electrode capacitance from impedance and phase.
%   - Updates GUI elements including tables, sliders, and dynamically created 
%     radio buttons for ports and data formats.
%
% Robust error handling is included to alert the user if data cannot be loaded.
%
% The structure ensures modular support for different file types 
% and allows easy extension to additional measurement systems. Multiple-file 
% selection is handled efficiently using cell arrays and concatenation.

% Set file filter based on the selected measurement system
switch h.selectedSystem
    case 'RHS'
        filterSpec = {'*.rhs', 'RHS Files (*.rhs)'; '*.*', 'All Files (*.*)'};
    case 'h5'
        filterSpec = {'*.h5', 'H5 Files (*.h5)'; '*.*', 'All Files (*.*)'};
    case 'RHD'
        filterSpec = {'*.rhd', 'RHD Files (*.rhd)'; '*.*', 'All Files (*.*)'};
    otherwise
        error('Unknown measurement system.');
end

% % Let the user choose a file to analyze
[FileName, FilePath, FlagUp] = uigetfile(filterSpec, 'Choose Data File', 'MultiSelect', 'on');

% If the user didn't click "cancel", try to open the file
if FlagUp

    try
        switch h.selectedSystem
            case 'RHS'
                % Load RHS data
                disp('Loading data for RHS...');
                if ~ischar(FileName) % One file is usually stored in chars
                    % Initialize variables
                    AmpChs = [];
                    
                    % Preallocate cell arrays
                    rawCell = cell(1, length(FileName));
                    timesCell = cell(1, length(FileName));
                    % Loop through each file
                    for i = 1:length(FileName) % Multiple files stored in struct
                        [raw, AmpChs, times] = read_Intan_RHS2000_file(FileName{i}, FilePath);
                        rawCell{i} = raw;
                        timesCell{i} = times;
                    end
                    
                    % Concatenate data after the loop
                    RawData = [rawCell{:}];
                    TimeStamps = [timesCell{:}];
                    
                else
                    % Load single file
                    [RawData, AmpChs, TimeStamps] = read_Intan_RHS2000_file(FileName, FilePath);                    
                end
                    % Extract Experimental Names/Metadata

                if ~ischar(FileName)
                    Data.metadata.filename=FileName{i};
                    date_time_str = strsplit([FileName{i}(end-16:end-4)],'_');
                else
                    Data.metadata.filename=FileName;
                    date_time_str = strsplit([FileName(end-16:end-4)],'_');
                end
                Data.metadata.date = datetime(date_time_str{1}, 'InputFormat', 'yyMMdd');
                t= datetime(date_time_str{2}, 'InputFormat', 'HHmmss');
                Data.metadata.time = t-dateshift(t,'start','day');
                
              case 'h5'
                    % Load MCS data
                    disp('Loading data for MCS...');
                    if ~ischar(FileName)
                        % Initialize variables
                        RawData = [];
                        TimeStamps = [];
                        AmpChs = [];
                        
                        % Preallocate cell arrays
                        rawCell = cell(1, length(FileName));
                        timesCell = cell(1, length(FileName));
                        
                        % Loop through each file
                        for i = 1:length(FileName)
                            [raw, AmpChs,times,metadata] = read_MCS_h5_file(fullfile(FilePath, FileName{i}));
                            rawCell{i} = raw;
                            timesCell{i} = times;
                        end
                        
                        % Concatenate data after the loop
                        RawData = [rawCell{:}];
                        TimeStamps = [timesCell{:}];
                        
                    else
                        [RawData,AmpChs,TimeStamps,metadata] = read_MCS_h5_file(fullfile(FilePath, FileName));
                        
                    end
                    Data.metadata.filename = metadata;
                    Data.metadata.date = metadata;
                
            case 'RHD'
                % Load RHD data
                disp('Loading data for RHD...');
                if ~ischar(FileName)
                    % Initialize variables
                    AmpChs = [];
                    
                    % Preallocate cell arrays
                    rawCell = cell(1, length(FileName));
                    timesCell = cell(1, length(FileName));
                    
                    % Loop through each file
                    for i = 1:length(FileName)
                        [raw, AmpChs, times] = read_Intan_RHD2000_file(FileName{i}, FilePath);
                        rawCell{i} = raw;
                        timesCell{i} = times;
                    end
                    
                    % Concatenate data after the loop
                    RawData = [rawCell{:}];
                    TimeStamps = [timesCell{:}];
                    
                else
                    % Load single file
                    [RawData, AmpChs, TimeStamps] = read_Intan_RHD2000_file(FileName, FilePath);
                    
                end
                % Extract Experimental Names/Metadata

                if ~ischar(FileName)
                    Data.metadata.filename=FileName{i};
                    date_time_str = strsplit([FileName{i}(end-16:end-4)],'_');
                else
                    Data.metadata.filename=FileName;
                    date_time_str = strsplit([FileName(end-16:end-4)],'_');
                end
                Data.metadata.date = datetime(date_time_str{1}, 'InputFormat', 'yyMMdd');
                t= datetime(date_time_str{2}, 'InputFormat', 'HHmmss');
                Data.metadata.time = t-dateshift(t,'start','day');
                
            otherwise
                error('Unknown measurement system.');
        end
        
    catch 
        % Display error message if loading fails
        errordlg('Failed to load data. Please check the selected files.');
        return
    end


    % Extract recording parameters and electrode properties
    Data.fs = round(1/(TimeStamps(2)-TimeStamps(1)));
    Data.timestamps = TimeStamps;
    
    if isfield(AmpChs,'electrode_impedance_magnitude')
        all_impedance = [AmpChs.electrode_impedance_magnitude]/1000; %kohms
        all_phase = [AmpChs.electrode_impedance_phase];
        all_capacitance = -1000000./(2*pi()*Data.fs.*abs(all_impedance).*sind(all_phase)); %capacitance in nF
    end
    all_channels = [AmpChs.custom_order];
    ch_ports = [AmpChs.port_number];
    unique_ports = unique(ch_ports); 
    Data.metadata.ports =  unique_ports;

    % Categorise Data based on ports

    for i = 1:length(unique_ports)
        idx = find(ch_ports == unique_ports(i));
        % Calculate capacitance from impedance and phase
        Data.ports(i).port_id = unique_ports(i);
        if isfield(AmpChs,'electrode_impedance_magnitude')
            Data.electrical_properties(i).electrode_impedance =all_impedance(idx); % impedance in kOhms
            Data.electrical_properties(i).electrode_phase = all_phase(idx); % phase in degrees
            Data.electrical_properties(i).electrode_capacitance = all_capacitance(idx);
        end
        Data.signals(i).raw = RawData(idx,:);
        [T, N] = size(RawData(idx,:));
        Data.channels(i).id = all_channels(idx);
    end
    % Store Data
    set(h.figure,'UserData',Data)

    % Setup GUI
    h.expList.Value =1;
    portNames = arrayfun(@(p) sprintf('Port %d', p.port_id), Data.ports, 'UniformOutput', false);
    expIdx = 1;  % only one experiment
    mapping = []; % rows = [expIdx, portIdx]
    allLabels = {};
    for p = 1:numel(Data.ports)
        allLabels{end+1} = sprintf('Port %d', Data.ports(p).port_id);
        mapping(end+1,:) = [expIdx, p];
    end
    
    % Multi-select listbox
    h.portList = uicontrol('Parent', h.portsPanel, ...
                           'Style', 'listbox', ...
                           'String', allLabels, ...
                           'UserData', mapping, ...
                           'Max', numel(allLabels), ...
                           'Min', 0, ...
                           'FontSize',8,...
                           'Units','normalized',...
                           'Position',[0.05 0.05 0.9 0.8], ...
                           'Callback', @(src,~) selectPorts(src,h));
    
    % Select All / Deselect All buttons
    h.selectAllBtn = uicontrol('Parent', h.portsPanel, 'Style','pushbutton', ...
                                'String','Select All', ...
                                'Units','normalized','Position',[0.05 0.87 0.4 0.08], ...
                                'Callback', @(src,evt) set(h.portList,'Value',1:numel(allLabels)),'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    
    h.deselectAllBtn = uicontrol('Parent', h.portsPanel, 'Style','pushbutton', ...
                                  'String','Deselect All', ...
                                  'Units','normalized','Position',[0.50 0.87 0.50 0.08], ...
                                  'Callback', @(src,evt) set(h.portList,'Value',[]),'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    guidata(h.figure,h)
    % Plot and Update Summary Data
    updateSummary(h);
    % Create radio button for series      
    create_signal_tabs(h);
    
    h=guidata(h.figure);
    h.formatsPlot.Raw = uicontrol('Style', 'radiobutton', 'String', 'Raw', ...
    'Units', 'normalized', 'Position', [0.01, 0.1, 0.2, 0.8], ...
    'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    
    % % Set slider properties
    set(h.series_slider, 'Max', T)
    set(h.series_slider, 'SliderStep', [1/(T-1), 1/(T-1)]) 
    % % Update series number and text
    SeriesNumber = 1;
    sertxt = [num2str(unique_ports(SeriesNumber)), ':', num2str(all_channels(SeriesNumber))];
    set(h.series_slider, 'Value', SeriesNumber)
    set(h.series_text,'String',sertxt)
    set(h.series_slider, 'Visible', 'on')
    set(h.series_text, 'Visible', 'on')
    ind_pl = find(h.maps == all_channels(SeriesNumber));
    set(h.marker, 'XData', h.x_coords(ind_pl), 'YData', h.y_coords(ind_pl));
    guidata(h.figure,h)
   
    pop_graph_callback(h);
    drawnow()
    update_traces_tab(h);

    create_ZC_tabs(h)
    noise_plot_callback(h);
    drawnow limitrate
    if mean(all_impedance)>0
        create_ZC_tabs(h);
        Elec_plot_callback(h);
        drawnow limitrate;
        run_qc_callback(h);
        run_qc_plot(h);        
    end
    h=guidata(h.figure);
    update_power_spectrum_tab(h);
    plot_specgram(h);
end
end
