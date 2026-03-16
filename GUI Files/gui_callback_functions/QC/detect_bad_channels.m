function [bad_channels_std, bad_channels_mad,bad_channels_psd] = detect_bad_channels(data, fs,channels)
    % Detect bad channels based on standard deviation (std), median absolute deviation (mad),
    % and power spectral density (PSD) with coherence.

    % Input:
    %   data: matrix with channels as rows and samples as columns
    %   fs: sampling frequency
    %   channels: array of channel labels
    
    % Output:
    %   bad_channels_std: channels identified as bad based on std deviation
    %   bad_channels_mad: channels identified as bad based on mad deviation
    %   bad_channels_psd: channels identified as bad based on PSD and coherence
    %   labels_psd: labels for each channel ("good", "dead", "noise", "out")

    
    % Parameters for thresholds
    std_mad_threshold = 3.5;           % Threshold multiplier for std and mad
    psd_hf_threshold = 0.02;         % Threshold for high-frequency power in PSD
    dead_channel_threshold = -0.5;   % Threshold for identifying dead channels based on coherence
    noisy_channel_threshold = 1.0;   % Threshold for identifying noisy channels based on coherence
    nyquist_threshold = 0.8;         % Frequency threshold for Nyquist frequency
    welch_window_s = 10 / 1000;      % Welch window size in seconds

    % STD and MAD method
    std_devs = std(data, 0, 2);      % Calculate standard deviation for each channel
    mad_devs = mad(data, 1, 2);      % Calculate median absolute deviation for each channel

    median_std = median(std_devs);   % Median of standard deviations across channels
    median_mad = median(mad_devs);   % Median of mad deviations across channels
   
    % Thresholds for std and mad deviations
    thresh_std = std_mad_threshold * median_std;
    thresh_mad = std_mad_threshold * median_mad;
    
    %bad_channels_std = channels(find(std_devs>100));
    % Identify bad channels based on std and mad thresholds
    bad_channels_std = channels(find(std_devs > thresh_std));
    bad_channels_mad = channels(find(mad_devs > thresh_mad));
    bad_channels_psd = [];

    if ~isempty(data)

    % Coherence + PSD method
    % Calculate power spectral density using Welch's method
    [Pxx, F] = pwelch(data', hanning(floor(welch_window_s * fs)), [], [], fs);
    Pxx = Pxx';  % Transpose Pxx to match original data orientation

    nyquist_freq = fs / 2;            % Nyquist frequency
    hf_freqs = F > nyquist_freq * nyquist_threshold;  % High-frequency components
    hf_psd = mean(Pxx(:, hf_freqs), 2);  % Mean high-frequency power for each channel

    % Calculate coherence with the median channel
    median_data = median(data, 2);
    xcorr_with_median = sum(data .* median_data, 2) ./ sum(median_data .^ 2);

    % Initialize output variables
    labels_psd = strings(size(data, 1), 1);
    labels_psd(:) = "good";  % Default label is "good"

    % Detect dead channels (low coherence with the median channel)
    dead_channels_idx = find(xcorr_with_median < dead_channel_threshold);
    labels_psd(dead_channels_idx) = "dead";
  %  bad_channels_psd = [bad_channels_psd; channels(dead_channels_idx)];

    % Detect noisy channels (high high-frequency power and high coherence with the median channel)
    noisy_channels_idx = find(hf_psd > psd_hf_threshold & xcorr_with_median > noisy_channel_threshold);
    labels_psd(noisy_channels_idx) = "noise";
    bad_channels_psd = [bad_channels_psd; channels(noisy_channels_idx)];
    end
    % Detect outside channels (low coherence with the median channel, redundant condition in this context)
    %outside_channels_idx = find(xcorr_with_median < dead_channel_threshold);
    %labels_psd(outside_channels_idx) = "out";
    %bad_channels_psd = [bad_channels_psd; channels(outside_channels_idx)];

end
