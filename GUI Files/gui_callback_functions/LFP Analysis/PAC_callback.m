function PAC_callback(h)
    h = guidata(h.figure);

    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    %%  Get selected port 
    idx = h.portList.Value;              % positions in the listbox
    map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
    selected = map(idx,:);
        %  1. User input dialog 
    prompt = {'Channels (comma-separated, e.g., 1,2,3):', ...
              'Delta [Hz] (low high):', ...
              'Theta [Hz] (low high):', ...
              'Alpha [Hz] (low high):', ...
              'Beta [Hz] (low high):', ...
              'Gamma [Hz] (low high):', ...
              'Low Gamma [Hz] (low high):', ...
              'High Gamma [Hz] (low high):', ...
              'Number of bins for MI:'};
    dlg_title = 'PAC/MI Settings';
    num_lines = 1;
    default_ans = {'1,2', '0.5 4', '4 8', '8 13', '13 30', '30 50', '100 200', '200 400', '18'};
    answer = inputdlg(prompt, dlg_title, num_lines, default_ans);
    if isempty(answer), return; end % user cancelled

    analysis_chans = str2num(answer{1}); %#ok<ST2NM>
    bands.delta = str2num(answer{2});
    bands.theta = str2num(answer{3});
    bands.alpha = str2num(answer{4});
    bands.beta = str2num(answer{5});
    bands.gamma = str2num(answer{6});
    bands.low_gamma = str2num(answer{7});
    bands.high_gamma = str2num(answer{8});
    nBins = str2double(answer{9});

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
    all_chans = results.channels(port_idx).id;
    mask = true(1,numel(all_chans));
    if h.excl_imp_toggle.Value
        mask = mask & ~bad_impedance;
    end
    if h.excl_high_STD_toggle.Value
        mask =mask & ~noisy;
    end
    all_chans = all_chans(mask);    
    if ~all(ismember(analysis_chans,all_chans))
        missing = analysis_chans(~ismember(analysis_chans, all_chans));
        warndlg(sprintf('Channel: %d not available for analysis ',missing));
        return;
    end

    lfp = results.signals(port_idx).lfp(mask,:); % LFP data: time x channels
    fs_lfp = results.filt_params(port_idx).ds_freq; % sampling freq

        
    %  2. Filter and compute envelope/phase 
    lfp_features = struct();
    for ch = analysis_chans
        for b = fieldnames(bands)'
            band_name = b{1};
            band_range = bands.(band_name);
            idx = find(all_chans==ch);
            filt_signal = eegfilt(lfp(idx,:), fs_lfp, band_range(1), band_range(2))';
            lfp_features.(band_name)(idx,:) = filt_signal;
            lfp_features.([band_name '_env'])(idx,:) = abs(hilbert(filt_signal));
            lfp_features.([band_name '_ph'])(idx,:) = angle(hilbert(filt_signal));
        end
    end

    %  3. Define PAC pairs (phase -> amplitude) 
    phase_bands = {'delta', 'theta'};          % user can expand
    amp_bands = {'gamma', 'low_gamma', 'high_gamma'};
    
    MI_results = struct();
    
    %  4. Compute MI for each pair 
    for ph_band = phase_bands
        ph_name = ph_band{1};
        for amp_band = amp_bands
            amp_name = amp_band{1};
            for ch1 = analysis_chans
                for ch2 = analysis_chans
                    idx1 = find(all_chans==ch1);
                    idx2 = find(all_chans==ch2);
                    phase = lfp_features.([ph_name '_ph'])(idx1, :);
                    amp_env = lfp_features.([amp_name '_env'])(idx2,:);
                    [MI, ~, amplP, binCenters] = modulationIndex(phase, amp_env, nBins);
                    
                    MI_results.(ph_name).(amp_name)(idx1,idx2) = MI;
                    MI_results.([ph_name '_' amp_name '_binCenters']) = binCenters;
                    MI_results.([ph_name '_' amp_name '_amplP']) = amplP;
                end
            end
        end
    end

    %  5. Plot dynamically in GUI subtabs 
    if isfield(h,'PAC_tabgroup') && isvalid(h.PAC_tabgroup)
        delete(h.PAC_tabgroup);
    end
    
    h.PAC_tabgroup = uitabgroup('Parent', h.PAC_tab, ...
                                 'Units','normalized', ...
                                 'Position',[0 0 1 1]);


    for ph_band = phase_bands
        ph_name = ph_band{1};
        for amp_band = amp_bands
            amp_name = amp_band{1};
            subtab_title = sprintf('%s %s', ph_name, amp_name);
            
            subtab = uitab(h.PAC_tabgroup, 'Title', subtab_title,'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor);
            h.PAC_plot_button = uicontrol('Style', 'pushbutton','Parent', subtab,'String', 'Compute', ...
            'Units', 'normalized','Position', [0.80, 0.0, 0.18, 0.05], ... % Adjust position as needed
            'BackgroundColor',backgdcolor,'ForegroundColor',accentcolor, ...
            'Callback', @(src, event) PAC_callback(h));
            k = 1;
            for ch1 = analysis_chans
                for ch2 = analysis_chans
                    ax = subplot(length(analysis_chans), length(analysis_chans), k, 'Parent', subtab);
                    binCenters = MI_results.([ph_name '_' amp_name '_binCenters']);
                    amplP = MI_results.([ph_name '_' amp_name '_amplP']);
                    bar(ax, [rad2deg(binCenters)+200 rad2deg(binCenters+2*pi)+200], [amplP amplP]);

                    title(ax, sprintf('Ch %d : Ch %d', ch1, ch2));
                    ylabel(ax, 'MI');
                    xlabel(ax,'Phase (Degrees)')
                    k = k + 1;
                end
            end
        end
    end

    disp('PAC/MI computation complete.');
end
