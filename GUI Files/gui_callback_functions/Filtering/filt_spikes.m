function Sp = filt_spikes(data,fs,spike_freq,order)
%This function takes in channel data, sampling frequency, spike frequency range for high pass filter, and order
% Outputs: 
% Sp: bandpass filtered data ; LFP: low pass filtered data
if nargin<4
    order = 5;
end
if nargin<3
    spike_freq = [100,6000];
end

[b_high,a_high] = butter(order, 2*spike_freq/fs, 'bandpass'); % Order usually odd number 3, 5, etc..
Sp = filtfilt(b_high,a_high,data);

end