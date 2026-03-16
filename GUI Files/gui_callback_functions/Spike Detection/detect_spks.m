function [waveforms] = detect_spks(data, fs, pre_time, post_time,STDEV,chans)
% STDEV input as: [STDEVmin STDEVmax]
% data in format: channelxsignal

% Calculate Median and Threshold
window_size = 60*fs; % 1 minute
%Data Dimensions
[numchan,len] = size(data);
num_windows = ceil(len/window_size);

%Precompute Constants
pre_samples = round(pre_time) / 1000 * round(fs);
post_samples = round(post_time) / 1000 * round(fs);
recording_time_min = length(data)/(fs*60);
% Create a structure for waveforms
waveforms = struct();
hWaitbar = waitbar(0, 'Spike Detection in Progress...');

choice = questdlg('Would you like to exclude low amplitude spikes (<10 uV)?', ...
                  'Spike Exclusion', ...
                  'Yes', 'No','Yes');
switch choice
    case 'Yes'
        noise_thresh = 10;
    case 'No'
        noise_thresh = [];
end
% Identify Channels Exceeding the Threshold

valid_channels = chans;
%Iterate over valid channels
ts = -pre_samples:post_samples;
st_count = 1;

for chan = 1:length(valid_channels)
    all_locs = [];
    all_pks = [];
    all_w = [];
    waitbar(chan/numchan,hWaitbar,['Processing Channel ' num2str(chans(chan))])
    for win = 1:num_windows
        start_idx = (win-1)*window_size +1;
        end_idx = min(win*window_size,len);
        channel_data = data(chan,start_idx:end_idx);
        thresh = STDEV(1) *median(abs(channel_data))/0.6745;
        threshmax = STDEV(2) *median(abs(channel_data))/0.6745;
        if ~isempty(noise_thresh) && thresh<=10
            thresh = 10;
        end
        locs = [];
        pks = [];
        w = [];

        if any(abs(channel_data) > abs(thresh)) && length(channel_data)>0.003*fs % 1s for values above thresholdmin and below max_thresh
            [pks,locs,w] = findpeaks(abs(channel_data),'MinPeakHeight',thresh,'MinPeakDistance',0.003*fs,'WidthReference','halfheight'); %2 ms peak distance; -ve spikes
            if ~isempty(locs)
                locs= locs(pks<threshmax)+start_idx-1;
                pks= pks(pks<threshmax);
                w = w(pks<threshmax);
            end
        end

        all_locs = [all_locs,locs];
        all_pks = [all_pks,pks];
        all_w = [all_w, w];
    end

    [all_locs,sort_idx] = sort(all_locs);
    all_pks = all_pks(sort_idx);
    all_w = all_w(sort_idx);
    %% Check Refractory Violations
    count_locs = 1;
    refractory_samples = round(2e-3*fs);
    valid_locs= [];
    valid_pks = [];
    valid_w = [];
    while count_locs<length(all_locs)
        refractory_window = all_locs(count_locs):all_locs(count_locs)+refractory_samples;
        idx_locs =all_locs >= refractory_window(1) & all_locs<=refractory_window(end);
        locs_in_window = all_locs(idx_locs);
        peaks_in_window = all_pks(idx_locs);
        w_in_window = all_w(idx_locs);
        if numel(locs_in_window)<3
            [~,maxIdx] = max(peaks_in_window);
            valid_locs = [valid_locs;locs_in_window(maxIdx)];
            valid_pks = [valid_pks;peaks_in_window(maxIdx)];
            valid_w = [valid_w;w_in_window(maxIdx)];
            count_locs = find(all_locs>refractory_window(end),1); % skip window
        else
            count_locs=find(all_locs>refractory_window(end),1);
        end
        if isempty(count_locs),break;end
    end
    %%
    all_locs = valid_locs;
    all_pks = valid_pks;
    all_w = valid_w;
    prePeakTimes = all_locs-round(pre_samples); % window limits centered on spike minima
    posPeakTimes = all_locs+round(post_samples);
    prePeakTimes(prePeakTimes<1) = 1; % trim windows exceeding beyond zero
    posPeakTimes(posPeakTimes>len) =len; % trim windows exceeding beyond signal end
    act_chan = chans(chan);
   % if (length(all_locs)/recording_time_min)>5
    for i = 1:length(all_locs)
        %%if (length(prePeakTimes(i):posPeakTimes(i)))==length(ts) && pks(i)>thresholdmin(chan,1) && pks(i)<thresholdmax(chan,1) && (w(i)/fs*1000)<2 && (w(i)/fs*1000)>0.15
        if (length(prePeakTimes(i):posPeakTimes(i)))==length(ts)
            event_waveform = data(chan,prePeakTimes(i):posPeakTimes(i));
            consec_zeros = conv(double(event_waveform == 0),[1,1,1],'valid')==3; % Consecutive zeros = artefact
            if sum(consec_zeros)==0
                % Convert x-axis to ms
                x = (0:length(event_waveform)-1) / fs * 1000;
                
                % Interpolation (increase resolution)
                xq = linspace(min(x), max(x), 1000); 
                event_waveform_interp = interp1(x, event_waveform, xq, 'spline');
                
                % Find peak value and determine waveform polarity
                [max_val, max_idx] = max(event_waveform_interp);
                [min_val, min_idx] = min(event_waveform_interp);
                
                if abs(max_val) > abs(min_val)
                    peak_val = max_val;  % Positive waveform
                    peak_idx = max_idx;
                else
                    peak_val = min_val;  % Negative waveform
                    peak_idx = min_idx;
                end
                
                % Compute half-max (same polarity as peak)
                half_max = peak_val * 0.5;
                
                % Find intersections
                crossings = find(diff(sign(event_waveform_interp - half_max)));
                idx_before = find(xq(crossings) < xq(peak_idx), 1, 'last');
                idx_after  = find(xq(crossings) > xq(peak_idx), 1, 'first');
            
                if ~isempty(idx_before) && ~isempty(idx_after)
                    t1 = xq(crossings(idx_before));
                    t2 = xq(crossings(idx_after));
                    FWHM_ms = t2 - t1;
                else
                    FWHM_ms = NaN;
                end
                


               % if fwhm_ms<0.5 && fwhm_ms>0.15
                energy = sum(event_waveform.^2);
                %if (fwhm_ms < 1) && (fwhm_ms >0.17) 
                waveforms(st_count).channel = act_chan;
                waveforms(st_count).spike_shape = event_waveform;
                waveforms(st_count).time_stamp = all_locs(i)/fs;
                waveforms(st_count).ptp_amplitude = max(event_waveform)-min(event_waveform);
                waveforms(st_count).fwhm = FWHM_ms; % fwhm in ms
                waveforms(st_count).fwhm_findpeaks = all_w(i)*1000/fs;
                waveforms(st_count).skewness = abs(skewness(event_waveform));
                waveforms(st_count).energy = energy;
                st_count = st_count + 1;
            end
            end
        % end
    end
    end

  
close(hWaitbar) 

end

