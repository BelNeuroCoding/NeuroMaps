function aggregate_spikes(h)
    %AGGREGATE_SPIKES Collects spike data across all selected experiments/ports
    %   Stores waveforms, channels, metrics, and origin info in h.cumulative_spikes

    h = guidata(h.figure);

    % Ensure ports are selected
    if ~isfield(h,'portList') || isempty(h.portList.Value)
        errordlg('No ports selected. Please select ports first.');
        return;
    end

    idx = h.portList.Value;           % positions in listbox
    map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
    selected = map(idx,:);

    % Initialize containers
    all_waveforms = [];
    all_channels = [];
    spike_origin_p = [];
    spike_origin_e = [];
    ptp_all = [];
    fwhm_all = [];
    rec_time_spike = [];
    all_spike_times = [];
    all_impedance = [];
    all_capacitance = [];
    all_offset = [];
    all_exponent = [];
    all_spec_chans = [];
    all_spec_p = [];
    all_spec_e = [];
    for p = 1:size(selected,1)
        expIdx = selected(p,1);
        portIdx = selected(p,2);

        res = h.figure.UserData{expIdx};
        recording_time = max(res.timestamps)-min(res.timestamps);
        if portIdx>numel(res.spike_results) || ~isfield(res,'spike_results')
            warndlg(sprintf('No spikes detected for Experiment %d, Port %d — skipping.', expIdx, res.ports(portIdx).port_id));
            continue;  % Skip this group
        end
        wf_all = res.spike_results(portIdx).waveforms_all;

        if ~isempty(wf_all)
            % Interpolate all waveforms to 200 points
            wf_mat = cell2mat(arrayfun(@(x) x.spike_shape(:)', wf_all,'UniformOutput',false)');
            x = 1:size(wf_mat,2);
            xq = linspace(1, size(wf_mat,2), 200);
            wf_interp = interp1(x, wf_mat.', xq, 'spline').';

            % Flip spikes so peak is positive
            max_vals = abs(wf_interp(:,round(size(wf_interp,2)/2)));
            max_minimas = abs(min(wf_interp,[],2));
            rows_to_flip = max_vals > max_minimas;
            wf_interp(rows_to_flip,:) = -wf_interp(rows_to_flip,:);

            % Store waveforms and metadata
            all_waveforms = [all_waveforms; wf_interp];
            ch_mat = cell2mat(arrayfun(@(x) x.channel, wf_all,'UniformOutput',false)');
            all_channels = [all_channels; ch_mat];
            spike_origin_p = [spike_origin_p; portIdx*ones(size(wf_interp,1),1)];
            spike_origin_e = [spike_origin_e; expIdx*ones(size(wf_interp,1),1)];
            spike_times = cell2mat(arrayfun(@(x) x.time_stamp, wf_all,'UniformOutput',false)');
            all_spike_times = [all_spike_times; spike_times];
            % Spike metrics
            ptp_all = [ptp_all; cell2mat(arrayfun(@(x) x.ptp_amplitude, wf_all,'UniformOutput',false)')];
            fwhm_all = [fwhm_all; cell2mat(arrayfun(@(x) x.fwhm, wf_all,'UniformOutput',false)')];
            rec_time_spike = [rec_time_spike ; recording_time*ones(size(wf_interp,1),1)];
            all_spec_chans = [all_spec_chans; [res.channels(portIdx).id]'];
            all_impedance = [all_impedance;[res.electrical_properties(portIdx).electrode_impedance]'];
            all_capacitance = [all_capacitance;[res.electrical_properties.electrode_capacitance]'];
             % Check if fields exist and are non-empty
            if isfield(res, 'foof_lfp') && length(res.foof_lfp) >= portIdx && isfield(res.foof_lfp(portIdx), 'foof_results') && ~isempty(res.foof_lfp(portIdx).foof_results)
                        if all(arrayfun(@(x) isfield(x, 'aperiodic_params'), res.foof_lfp(portIdx).foof_results))
        
                    aperiodic_params_mat = cell2mat(arrayfun(@(x) x.aperiodic_params, res.foof_lfp(portIdx).foof_results, 'UniformOutput', false)');
        
                    all_offset   = [all_offset;   aperiodic_params_mat(:,1)];
                    all_exponent = [all_exponent; aperiodic_params_mat(:,2)];
        
                    chans_spec = [res.channels(portIdx).id];
                    all_spec_p = [all_spec_p; portIdx*ones(length(chans_spec),1)];
                    all_spec_e = [all_spec_e; expIdx*ones(length(chans_spec),1)];
        
                        else
                            
                    warndlg(sprintf('Port %d missing "aperiodic_params" field in foof_results.', res.ports(portIdx).port_id));
                end
            else
                warndlg(sprintf('Port %d missing foof_lfp or foof_results.', res.ports(portIdx).port_id));
            end

        end
        
    end

    % Optionally store per-port summary metrics
    spike_rate_per_channel = [];
    mean_bursts_rate = [];
    std_bursts_rate = [];
    for p = 1:size(selected,1)
        expIdx = selected(p,1);
        portIdx = selected(p,2);
        res = h.figure.UserData{expIdx};
        if isfield(res.spike_results(portIdx),'set')
            set_data = res.spike_results(portIdx).set;
            if ~isempty(set_data)
            spike_rate_per_channel = [spike_rate_per_channel set_data.spike_rate_per_channel];
            mean_bursts_rate = [mean_bursts_rate set_data.mean_bursts_rate];
            std_bursts_rate = [std_bursts_rate set_data.std_bursts_rate];
            end
        end
    end

    % Save into h structure
    h.cumulative_spikes.all_waveforms    = all_waveforms;
    h.cumulative_spikes.channels         = all_channels;
    h.cumulative_spikes.spike_origin_p   = spike_origin_p;
    h.cumulative_spikes.spike_origin_e   = spike_origin_e;
    h.cumulative_spikes.ptp_amplitude    = ptp_all;
    h.cumulative_spikes.fwhm             = fwhm_all;
    h.cumulative_spikes.rec_time = rec_time_spike;
    h.cumulative_spikes.spike_times = all_spike_times;
    h.cumulative_spikes.impedance = all_impedance;
    h.cumulative_spikes.capacitance = all_capacitance;
    h.cumulative_spikes.offset = all_offset;
    h.cumulative_spikes.exponent = all_exponent;
    h.cumulative_spikes.spec_p = all_spec_p;
    h.cumulative_spikes.spec_e = all_spec_e;
    h.cumulative_spikes.spec_chans = all_spec_chans;

    guidata(h.figure,h);

    m= msgbox('Spike data aggregated successfully. Ready for clustering or plotting.','Success');
    pause(2);                      % wait 2 seconds (or do some computation)
    if ishandle(m)                  % check if the box is still open
        close(m);                   % close it
    end
end
