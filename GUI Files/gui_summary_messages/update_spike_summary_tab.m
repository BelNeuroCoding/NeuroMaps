function update_spike_summary_tab(h, analysedset)
% h: GUI handle
% analysedset: output from spike_feats_callback (optional if results loaded from UserData)

h = guidata(h.figure);  

% Get all results from UI
allResults = get(h.figure,'UserData');
if ~iscell(allResults)
    allResults = {allResults}; 
end
numExpts = length(allResults);

% Build summary as a cell array of lines
summaryLines = {};
summaryLines{end+1} = sprintf('Experiments Loaded: %d', numExpts);

for exps = 1:numExpts
    results = allResults{exps};
    if isfield(results,'spike_results') && isfield(results.spike_results,'set')
        for ports = 1:numel(results.spike_results)
        analysedset = results.spike_results(ports).set;

        % Per-experiment header
        summaryLines{end+1} = sprintf('\nExperiment: %d Port: %d', exps,results.ports(ports).port_id);

        % Main stats
        summaryLines{end+1} = sprintf('  Number of Active Channels: %d', analysedset.num_activechans);
        summaryLines{end+1} = sprintf('  Mean Spike Rate (Hz): %.2f ± %.2f', analysedset.mean_spike_rate, analysedset.std_spike_rate);
        summaryLines{end+1} = sprintf('  Mean Burst Rate (Hz): %.2f ± %.2f', analysedset.mean_bursts_rate, analysedset.std_bursts_rate);
        summaryLines{end+1} = sprintf('  Synchronicity Index (0–1): %.2f', analysedset.synchronicity);
        summaryLines{end+1} = sprintf('  Mean FWHM (ms): %.2f ± %.2f', analysedset.mean_fwhm, analysedset.std_fwhm);
        summaryLines{end+1} = sprintf('  Mean Peak-to-Peak Amplitude (µV): %.2f ± %.2f', analysedset.mean_ptp_amplitude, analysedset.std_ptp_amplitude);

        % Per-cluster stats
        if isfield(analysedset,'fwhm_per_cluster') && ~isempty(analysedset.fwhm_per_cluster)
            for j = 1:size(analysedset.fwhm_per_cluster,1)
                summaryLines{end+1} = sprintf( ...
                    '    Cluster %d:\n Spike Rate %.2f Hz, \n FWHM %.2f ± %.2f ms,\n PTP %.2f ± %.2f µV\n', ...
                    j, ...
                    analysedset.spike_rate_cluster(j), ...
                    analysedset.fwhm_per_cluster(j,1), analysedset.fwhm_per_cluster(j,2), ...
                    analysedset.ptp_amplitude_per_cluster(j,1), analysedset.ptp_amplitude_per_cluster(j,2));
            end
        end
        end
    end
end

% Update the GUI text box
set(h.spike_summary_text, 'String', summaryLines, ...
    'FontSize', 12, 'HorizontalAlignment', 'left');

end
