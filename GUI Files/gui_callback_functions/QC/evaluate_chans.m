function [good_channels, bad_chs] = evaluate_chans(channels, impedance,data, fs, checktype)
% evaluate_chans - Identify good and bad channels based on impedance and signal metrics.
%
% This function filters channels using measured impedance and statistical/spectral
% metrics (STD, MAD, PSD). It supports two modes:
%   checktype = 0 : detect bad channels only based on signal statistics
%   checktype = 1 : detect bad channels considering both impedance and signal statistics
%
% Inputs:
%   channels   - Vector of channel labels
%   impedance  - Vector of channel impedance values (kOhms)
%   data       - Matrix of recorded signals (channels x samples)
%   fs         - Sampling frequency in Hz
%   checktype  - (Optional) 0 or 1; default is 1
%
% Outputs:
%   good_channels - Channels deemed good after filtering
%   bad_chs       - Structure containing bad channels by metric:
%                   bad_chs.bad_channels_std, bad_chs.bad_channels_mad, bad_chs.bad_channels_psd
%
% Example:
%   [good_chs, bad] = evaluate_chans(channels, impedance, data, 30000, 1);
%
% Notes:
%   - Channels failing impedance or statistical checks are excluded from good_channels.
%   - Statistical checks include PSD, STD, and MAD thresholds determined in detect_bad_channels.

    % Default checktype to 0 if not provided
    if nargin < 5
        checktype = 1; % Default analysis mode: bad channels detected based on impedance AND PSD,STD,MAD Metrics
        disp('Default Analysis Mode Activated: Impedance and PSD/STD/MAD');
    end

    % Initialize bad channels structure
    bad_chs = struct();

    % Validate inputs
    if isempty(channels) || isempty(data)
        error('Channels and data must be provided.');
    end
    if ~isempty(impedance) && numel(channels') ~= numel(impedance)
        error('The number of channels must match the number of impedance values.');
    end

    % Load user config if available
    if exist('qc_config.mat','file')
        cfg = load('qc_config.mat');
        cfg = cfg.config;
    else
        % fallback defaults
        cfg.std_mad_threshold = 3.5;
        cfg.psd_hf_threshold = 0.02;
        cfg.dead_channel_threshold = -0.5;
        cfg.noisy_channel_threshold = 1.0;
        cfg.nyquist_threshold = 0.8;
        cfg.welch_window_s = 0.01;
        cfg.impedance_min = 10;
        cfg.impedance_max = 1000;
    end

    % Initialize good channels
    good_channels = channels; % Default all channels as good initially

    % Filter channels based on impedance if available
    if ~isempty(impedance) && mean(impedance) > 0
        valid_imp = impedance > cfg.impedance_min & impedance < cfg.impedance_max;
        good_channels = channels(valid_imp);% Impedance between 10 kOhms and 1 MOhm and noise <10 uV
    else
        % No valid impedance data; skip impedance filtering
        disp('No valid impedance data available. Skipping impedance filtering, default mode reactivated');
        med_noise = median(abs(data)/0.6745, 1);
        valid_idx = med_noise<100;
        good_channels = channels(valid_idx); % Assume all channels pass impedance filtering
        checktype = 1;
    end

    % Determine good channels based on the check type
    bad_channels_psd = [];
    bad_channels_std = [];
    bad_channels_mad = [];
    labels_psd = [];
   
    % Detect bad channels using statistical and spectral methods
    disp('Detecting bad channels...');
        % Parameters for thresholds

    % STD and MAD method
    std_devs = std(data, 0, 1);      % Calculate standard deviation for each channel
    mad_devs = mad(data, 1, 1);      % Calculate median absolute deviation for each channel

    median_std = median(std_devs);   % Median of standard deviations across channels
    median_mad = median(mad_devs);   % Median of mad deviations across channels
   % Thresholds for std and mad deviations
   
    bad_std = channels(std_devs > cfg.std_mad_threshold*median_std);
    bad_mad = channels(mad_devs > cfg.std_mad_threshold*median_mad);

    % Block-wise PSD calculation
    nSamples = size(data,1);
    nChannels = size(data,2);
    hf_psd = zeros(1, nChannels);
    
    nBlocks = 4;
    block_edges = round(linspace(1, nSamples+1, nBlocks+1));  % start and end indices
    
    win_len = floor(cfg.welch_window_s * fs);
    window = hanning(win_len);
    noverlap = 0;
    
    for b = 1:nBlocks
        start_idx = block_edges(b);
        end_idx = block_edges(b+1) - 1;
        block = data(start_idx:end_idx, :);
    
        [Pxx,F] = pwelch(block, window, noverlap, [], fs);  % freq x channels
        hf_freqs = F > fs/2 * cfg.nyquist_threshold;
        hf_psd = hf_psd + mean(Pxx(hf_freqs,:), 1);  % accumulate HF PSD per channel
    end
    
    hf_psd = hf_psd / nBlocks;  % average across blocks

    % Calculate coherence with the median channel
    median_data = median(data', 2);
    xcorr_with_median = sum(data' .* median_data, 2) ./ sum(median_data .^ 2);
    
    % Detect dead channels
    dead_channels_idx = find(xcorr_with_median < cfg.dead_channel_threshold);
    
    % Detect noisy channels
    noisy_channels_idx = find(hf_psd > cfg.psd_hf_threshold & xcorr_with_median > cfg.noisy_channel_threshold);
    bad_channels_psd = [bad_channels_psd; channels(noisy_channels_idx)];
    % Exclude bad channels from the low-impedance set
    bad_channels_combined = unique([bad_channels_psd, bad_channels_std, bad_channels_mad]);
    good_channels = setdiff(good_channels, bad_channels_combined);

    % Populate the bad channels structure
  %  bad_chs.bad_channels_psd = bad_channels_psd;
    bad_chs.bad_channels_std = bad_channels_std;
    bad_chs.bad_channels_mad = bad_channels_mad;
    bad_chs.bad_channels_psd = bad_channels_psd;
    bad_chs.bad_channels_impedance = channels(~ismember(channels,good_channels));
    bad_chs.channels_dead = channels(dead_channels_idx);
    % Display results
    fprintf('Filtering complete: %d good channels found.\n', numel(good_channels));
end
