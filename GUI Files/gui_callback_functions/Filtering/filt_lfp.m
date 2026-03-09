function LFP = filt_lfp(data,fs,lfp_freq,order)
%This function takes in channel data, sampling frequency, LFP detection
% threshold, and filter order
% Outputs: 
% Sp: bandpass filtered data ; LFP: low pass filtered data
if nargin<3
    lfp_freq = 300; % Default frequency threshold for low pass filtering
end
if nargin<4
    order = 10; % Default filter order
end

[b_low,a_low] = butter(order, 2*lfp_freq/fs, 'low');
LFP = filtfilt(b_low,a_low,data);

end