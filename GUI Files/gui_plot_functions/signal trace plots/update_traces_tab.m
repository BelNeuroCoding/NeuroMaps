function update_traces_tab(h)
% Update all plots without recreating anything
set_status(h.figure,"loading","Trace Plot...");

h = guidata(h.figure);
% Get selected ports from listbox
idx = h.portList.Value;                  % selected rows in the listbox
map = h.portList.UserData;               % Nx2 mapping [expIdx, portIdx]
selected = map(idx,:);                   % rows correspond to each selected port
expIdx = selected(1,1);
port_idx = selected(1,2);
SeriesNumber = round(get(h.series_slider, 'Value')); 
% Get results
results = h.figure.UserData;
if ~iscell(results), results = {results}; end
results = results{expIdx};
% Mask channels based on toggles
channels = [results.channels(port_idx).id];
mask = true(1,numel(channels));
if get(h.excl_imp_toggle,'Value')
    mask = mask & ~results.channels(port_idx).bad_impedance;
end
if get(h.excl_high_STD_toggle,'Value')
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    mask = mask & ~noisy;
end
channels = channels(mask);

Observations = results.signals(port_idx).raw(mask,:);
Timestamps = results.timestamps;
prange = 1:size(Observations,2);

% - Raw -
if isfield(results.signals(port_idx),'raw')
    set(h.trLines.raw, 'XData', Timestamps(prange), ...
                       'YData', Observations(SeriesNumber,prange));
    set(h.trTitles.raw, 'String', ['Broadband Signal Ch: ' num2str(channels(SeriesNumber))]);
end

% - Ref -
if isfield(results.signals(port_idx),'ref')
    referencedData = results.signals(port_idx).ref(mask,:);
    set(h.trLines.ref, 'XData', Timestamps(prange), 'YData', referencedData(SeriesNumber,:));
    
    STDEVMIN = str2double(get(h.std_value,'String')); 
    STDEVMAX = str2double(get(h.stdmax_value,'String'));
    med_abs = median(abs(referencedData(SeriesNumber,:))) / 0.6745;
    
    % Update threshold lines
    set(h.trLines.ref_thresh(1),'YData', STDEVMIN*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trLines.ref_thresh(2),'YData', -STDEVMIN*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trLines.ref_thresh(3),'YData', STDEVMAX*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trLines.ref_thresh(4),'YData', -STDEVMAX*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trTitles.ref, 'String', ['Reference Signal Ch: ' num2str(channels(SeriesNumber))]);end

% - HPF -
if isfield(results.signals(port_idx),'hpf')
    SpikeData = results.signals(port_idx).hpf(mask,:);
    set(h.trLines.hpf,'XData', Timestamps(prange), 'YData', SpikeData(SeriesNumber,:));
    
    STDEVMIN = str2double(get(h.std_value,'String')); 
    STDEVMAX = str2double(get(h.stdmax_value,'String'));
    med_abs = median(abs(SpikeData(SeriesNumber,:)))/ 0.6745;
    
    set(h.trLines.hpf_thresh(1),'YData', STDEVMIN*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trLines.hpf_thresh(2),'YData', -STDEVMIN*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trLines.hpf_thresh(3),'YData', STDEVMAX*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trLines.hpf_thresh(4),'YData', -STDEVMAX*med_abs*ones(size(prange)), 'XData', Timestamps(prange));
    set(h.trTitles.hpf, 'String', ['High Freq Signal Ch: ' num2str(channels(SeriesNumber))]);
end

% - LFP -
if isfield(results.signals(port_idx),'lfp')
    LFPData = results.signals(port_idx).lfp(mask,:);
    set(h.trLines.lfp,'XData', results.resampled_time, 'YData', LFPData(SeriesNumber,:));
    set(h.trTitles.lfp, 'String', ['LFP Signal Ch: ' num2str(channels(SeriesNumber))]);
end

drawnow limitrate;
guidata(h.figure,h);
set_status(h.figure,"ready","Trace Plot Complete...");

end
