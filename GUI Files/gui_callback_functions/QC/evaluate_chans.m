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
%   data       - Matrix of recorded signals (samples x channels)
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

    % Default checktype to 1 if not provided
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
        cfg.n_neighbors = 3;

    end
    cfg.n_neighbors = 3;
    % Initialize good channels
    good_channels = channels; % Default all channels as good initially

    % Filter channels based on impedance if available
    if ~isempty(impedance) && mean(impedance) > 0
        valid_idx = impedance > cfg.impedance_min & impedance < cfg.impedance_max;
        good_channels = channels(valid_idx);% Impedance between 10 kOhms and 1 MOhm and noise <10 uV
        bad_chs.bad_channels_impedance = channels(~ismember(channels,good_channels));
    else
        % No valid impedance data; skip impedance filtering
        disp('No valid impedance data available. Skipping impedance filtering, default mode reactivated');
        med_noise = median(abs(data)/0.6745, 1);
        valid_idx = med_noise<100;
        good_channels = channels(valid_idx); % Assume all channels pass impedance filtering
        bad_chs.bad_channels_impedance = channels(~ismember(channels,good_channels));
        checktype = 1;
    end

    % Determine good channels based on the check type
    bad_channels_psd = [];
    bad_channels_std = [];
    bad_channels_mad = [];
    labels_psd = [];

    data = data(:,valid_idx);
    % Detect bad channels using statistical and spectral methods
    disp('Detecting bad channels...');
        % Parameters for thresholds

    % STD and MAD method
    std_devs = std(data, 0, 1);      % Calculate standard deviation for each channel
    mad_devs = mad(data, 1, 1);      % Calculate median absolute deviation for each channel

    median_std = median(std_devs);   % Median of standard deviations across channels
    median_mad = median(mad_devs);   % Median of mad deviations across channels
   % Thresholds for std and mad deviations
   
    bad_channels_std = good_channels(std_devs > cfg.std_mad_threshold*median_std);
    bad_channels_mad = good_channels(mad_devs > cfg.std_mad_threshold*median_mad);

    nSamples  = size(data, 1);   % samples x channels
    nChannels = size(data, 2);
    
    nBlocks     = 4;  
    block_edges = round(linspace(1, nSamples+1, nBlocks+1));  % start/end indices
    
    win_len  = floor(cfg.welch_window_s * fs);   % e.g. 0.01 s * fs = 10 ms window
    window   = hanning(win_len);
    noverlap = floor(win_len / 2);               %  50% overlap
    
    hf_psd = zeros(1, nChannels);  % will store mean HF PSD per channel
    
    for b = 1:nBlocks
        start_idx = block_edges(b);
        end_idx   = block_edges(b+1) - 1;
        block     = data(start_idx:end_idx, :);  % samples x channels, in uV
    
        [Pxx, F] = pwelch(block, window, noverlap, [], fs);  % freq x channels, PSD in uV^2/Hz
    
        hf_mask  = F > (fs/2 * cfg.nyquist_threshold);       % e.g. > 0.8 * Nyquist
        hf_psd_block = mean(Pxx(hf_mask, :), 1);             % 1 x nChannels
    
        hf_psd = hf_psd + hf_psd_block;
    end
    
    hf_psd = hf_psd / nBlocks;  % average HF PSD across blocks (uV^2/Hz)

    % ref = median(raw, axis=1)
    ref = median(data, 2);                 % N x 1
    ref = ref - mean(ref);                 % demean
    data_demeaned = data - mean(data,1);   % N x nChannels
    
    xcorr_with_median = sum(data_demeaned .* ref,1) ./ sum(ref.^2);  % 1 x nChannels
    ntap = ceil(cfg.n_neighbors / 2);

    % pad with edge values like IBL
    xf = [ones(1, ntap) * xcorr_with_median(1), xcorr_with_median, ones(1, ntap) * xcorr_with_median(end)];

    % median filter along the channel axis
    xf = medfilt1(xf, cfg.n_neighbors);   % requires Signal Processing Toolbox

    % remove padding
    xf = xf(ntap+1:end-ntap);

    % detrended coherence
    xcorr_neighbors = xcorr_with_median - xf;
    dead_channels_idx  = find(xcorr_neighbors < cfg.dead_channel_threshold);

    noisy_channels_idx = find(hf_psd > cfg.psd_hf_threshold & ...
                              xcorr_neighbors > cfg.noisy_channel_threshold);

    bad_channels_psd = [bad_channels_psd; good_channels(noisy_channels_idx)];
    % Exclude bad channels from the low-impedance set
    bad_channels_combined = unique([bad_channels_psd, bad_channels_std, bad_channels_mad]);
    good_channels = setdiff(good_channels, bad_channels_combined);

    % Populate the bad channels structure
  %  bad_chs.bad_channels_psd = bad_channels_psd;
    bad_chs.bad_channels_std = bad_channels_std;
    bad_chs.bad_channels_mad = bad_channels_mad;
    bad_chs.bad_channels_psd = bad_channels_psd;
    bad_chs.channels_dead = good_channels(dead_channels_idx);
    % Display results
    fprintf('Filtering complete: %d good channels found.\n', numel(good_channels));
end
