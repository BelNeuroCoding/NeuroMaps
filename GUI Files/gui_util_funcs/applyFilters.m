function applyFilters(h)
    idx = h.portList.Value;        % listbox indices
    map = h.portList.UserData;     % Nx2 mapping [expIdx, portIdx]
    selected = map(idx,:);
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    n=size(selected,1);
    set_status(h.figure,"loading","Step 2 (Filtering) Initiated...");

    % Setup waitbar
    wb = waitbar(0,'Preparing Filters...','Name','Filtering');
    cleanupObj = onCleanup(@() delete(wb));

    exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
    exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');

    % Loop through each selected exp/port
    for i = 1:size(selected,1)
        expIdx = selected(i,1);
        selected_idx = selected(i,2);
        baseProgress = (i-1)/n;
        portWeight   = 1/n;
        waitbar(baseProgress + 0.05*portWeight, wb, ...
        sprintf('Preparing port %d of %d...', i, n));
        drawnow limitrate

        % Pull results
        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end
        selectedport = results.ports(selected_idx).port_id;
        channels = [results.channels(selected_idx).id];
        mask = true(1,numel(channels));
        if exclude_impedance_chans_toggle || exclude_noisy_chans_toggle
        bad_impedance = results.channels(selected_idx).bad_impedance;
        noisy = results.channels(selected_idx).high_psd & results.channels(selected_idx).high_std;
        if exclude_impedance_chans_toggle
            mask = mask & ~bad_impedance;
        end
        if exclude_noisy_chans_toggle
            mask =mask & ~noisy;
        end
        end
        % Select which data to Filter
        if isfield(results.signals(selected_idx),'ref') && ~isempty(results.signals(selected_idx).ref) && i==1
            choice = questdlg(['Which data do you want to use for filtering on port ?'], ...
                              'Select Data', 'Raw', 'Referenced','Raw');
        else 
            choice = 'Raw';
        end
        % Make sure data is loaded
        if isempty(results)
            errordlg('No data loaded. Please load data first.','Filter Error');
            return;
        end
        switch choice
            case 'Raw'
                data = results.signals(selected_idx).raw(mask,:);
            case 'Referenced'
                data = results.signals(selected_idx).ref(mask,:);
        end
        if isempty(data)
            if size(selected,1)>1
                tit = ['Exp ' num2str(expIdx)];
            else
                tit = '';
            end
            errordlg(['Skipped Filtering Port ' num2str(selectedport)],'Filter Error');
        end
        Spike_data = zeros(numel(channels),size(data,2));
        LFP_data = zeros(numel(channels),size(data,2));
        ac_data = zeros(numel(channels),size(data,2));
        selectedport = results.ports(selected_idx).port_id;
        TimeStamps = results.timestamps;
        fs = round(results.fs);    
        filters = h.selectedFilters;
        if isfield(filters,'ACLineNoise')    
                waitbar(baseProgress + 0.20*portWeight, wb, ...
                sprintf('Powerline filtering port %d...', i));
                set_status(h.figure,"loading","Powerline Filtering...");
                drawnow limitrate
                notchHz = filters.ACLineNoise.NotchFreq_Hz__;
                bandwidth = filters.ACLineNoise.Bandwidth_;    % bandwidth
                if notchHz == 50
                    linefreq = [50;100; 150; 200;250;300; 350;400; 450;500; 550; 650; 750; 850;950;1150;1250;1450;1750;1850;4000];
                elseif notchHz == 60
                    linefreq = [60; 120; 180; 240; 300; 360; 420; 480; 540; 600; 660; 780; 900; 1020; 1140; 1380; 1500; 1740; 2100; 2220; 4800];
                end
                results.filt_params(selected_idx).powerline_freqs = linefreq;
                results.filt_params(selected_idx).bandwidth = bandwidth;
                ac_data(mask,:) = powerline_filter_gui(data, fs, linefreq,bandwidth);
                results.signals(selected_idx).raw = ac_data;
                data = ac_data(mask,:);
                currentText = get(h.summary_text,'String');
                % Append the new summary
                if ischar(currentText)
                    currentText = cellstr(currentText);
                end
                newMsg = sprintf('Performed Powerline Filtering on Raw Data - Port %s at: BW: %d Frequencies: %s Hz', ...
                                  num2str(selectedport), bandwidth,strjoin(string(linefreq(:)'), ', '));
                currentText{end+1} = newMsg;
                set(h.summary_text,'String',currentText);
                if isfield(h.formatsPlot,'Raw') && isvalid(h.formatsPlot.Raw)
                    delete(h.formatsPlot.Raw);  % remove the old one
                end
                h.formatsPlot.Raw = uicontrol('Style', 'radiobutton', 'String', 'AC Filtered', ...
                'Units', 'normalized', 'Position', [0.01, 0.1, 0.4, 0.8], ...
                'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);

        end
        if isfield(filters, 'Low_passFilter_LFP_')
            set_status(h.figure,"loading","Filtering lowpass data...");
             waitbar(baseProgress + 0.50*portWeight, wb, ...
             sprintf('Computing LFP port %d...', i));
             drawnow limitrate
             lfp_freq = filters.Low_passFilter_LFP_.Cutoff_Hz__;
             ds_freq  = filters.Low_passFilter_LFP_.DownsampledFrequency_;
             LFP_data(mask,:) = filt_lfp(data', fs, lfp_freq)';
             ds_factor = round(fs/ds_freq);
             results.filt_params(selected_idx).ds_factor = ds_factor;
             results.filt_params(selected_idx).lfp = lfp_freq;
             results.signals(selected_idx).lfp = LFP_data(:,1:ds_factor:end);
             results.resampled_time = TimeStamps(1:ds_factor:end);
             results.filt_params(selected_idx).ds_freq = ds_freq;
             if isfield(h.formatsPlot,'LFP') && isvalid(h.formatsPlot.LFP)
                delete(h.formatsPlot.LFP);  % remove the old one
            end
             h.formatsPlot.LFP = uicontrol('Style', 'radiobutton', 'String', 'LFP', ...
            'Units', 'normalized', 'Position', [0.53, 0.1, 0.2, 0.8], ...
            'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
        end
        if isfield(filters, 'BandpassFilter_Spikes_')
            set_status(h.figure,"loading","Bandpass filtering...");
            waitbar(baseProgress + 0.50*portWeight, wb, ...
            sprintf('Bandpass filtering spikes port %d...', i));
            drawnow limitrate
            lowCut = filters.BandpassFilter_Spikes_.Low_Hz__;
            highCut= filters.BandpassFilter_Spikes_.High_Hz__;
            order  = filters.BandpassFilter_Spikes_.Order_;
            results.filt_params(selected_idx).spikes = [lowCut highCut];
            Spike_data(mask,:) = filt_spikes(data', fs, [lowCut highCut], order)';
            results.signals(selected_idx).hpf = Spike_data; 
            if isfield(h.formatsPlot,'Spikes') && isvalid(h.formatsPlot.Spikes)
                delete(h.formatsPlot.Spikes);  % remove the old one
            end
            h.formatsPlot.Spikes = uicontrol('Style', 'radiobutton', 'String', 'Spikes', ...
            'Units', 'normalized', 'Position', [0.74, 0.1, 0.2, 0.8], ...
            'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
            set([h.std_textbox,h.std_value, h.stdmax_textbox,h.stdmax_value,h.std_button], 'Visible', 'on');

        end
        waitbar(baseProgress + portWeight, wb, ...
        sprintf('Finalising port %d...', i));
        set_status(h.figure,"ready","Step 2 (Filtering) complete...");
        drawnow limitrate
        delete(wb);

        wb = waitbar(0,'Updating interface...','Name','Finalizing');
        cleanupObj = onCleanup(@() delete(wb));
        waitbar(0.2,wb,'Saving results...');
        drawnow limitrate

        % Save back
        if iscell(h.figure.UserData)
            h.figure.UserData{expIdx} = results;
        else
            h.figure.UserData = results;
        end
        guidata(h.figure,h)
        waitbar(0.4,wb,'Updating traces...');
        drawnow limitrate
        init_traces_tab(h);
        update_traces_tab(h);
        waitbar(0.6,wb,'Building LFP tabs...');
        drawnow limitrate
        if isfield(filters, 'Low_passFilter_LFP_')
            create_lfp_tabs(h);
            h=guidata(h.figure);
            waitbar(0.8,wb,'Computing wavelet transform...');
            plot_cwt(h);
            drawnow limitrate
        end
        msgbox('Filters applied successfully.','Success');

    end
       set_status(h.figure,"ready","Step 2 (Filtering and plotting) complete...");

end
