function export_spike_results_csv(h)
% EXPORT_SPIKE_RESULTS_CSV Export spike_results.waveforms_all and spike_results.set as CSV.
%
% Per selected Exp/Port, exports:
%
%   *_spike_features.csv
%       Scalar spike-level features from waveforms_all.
%
%   *_spike_shapes.csv
%       spike_shape waveform samples, one spike per row.
%
%   *_spike_set_summary.csv
%       Scalar summary fields from spike_results.set.
%
%   *_spike_rate_per_channel.csv
%       Per-channel spike rate.
%
%   *_spike_analysis.csv
%       Per-channel spike_analysis struct fields where CSV-compatible.
%
%   *_cluster_metrics.csv
%       Per-cluster FWHM and PTP amplitude.

h = guidata(h.figure);

results = get(h.figure, 'UserData');

if ~iscell(results)
    results = {results};
end

if isempty(results)
    errordlg('No results available to export.');
    return;
end

% Build Exp/Port list
comboList = {};
comboMap = [];

for expIdx = 1:numel(results)

    res = results{expIdx};

    if isfield(res, 'ports') && ~isempty(res.ports)

        for portIdx = 1:numel(res.ports)

            comboList{end+1} = sprintf('Exp %d Port %d', ...
                expIdx, res.ports(portIdx).port_id); %#ok<AGROW>

            comboMap(end+1, :) = [expIdx, portIdx]; %#ok<AGROW>
        end
    end
end

if isempty(comboList)
    errordlg('No experiment/port combinations found.');
    return;
end

[selIdx, tf] = listdlg( ...
    'ListString', comboList, ...
    'SelectionMode', 'multiple', ...
    'Name', 'Select Spike Results', ...
    'PromptString', 'Choose Exp/Port spike results to export:');

if ~tf
    return;
end

outDir = uigetdir(pwd, 'Choose folder for spike CSV export');

if isequal(outDir, 0)
    return;
end

set_status(h.figure, "loading", "Exporting Spike CSV...");

hWait = waitbar(0, 'Exporting spike CSV files...');

try

    for s = 1:numel(selIdx)

        expIdx = comboMap(selIdx(s), 1);
        portIdx = comboMap(selIdx(s), 2);

        res = results{expIdx};

        label = sprintf('Exp %d Port %d', ...
            expIdx, res.ports(portIdx).port_id);

        waitbar((s - 1) / numel(selIdx), hWait, ...
            sprintf('Exporting %s...', label));

        if ~isfield(res, 'spike_results') || isempty(res.spike_results)
            warning('%s has no spike_results field. Skipping.', comboList{selIdx(s)});
            continue;
        end

        spike_results = res.spike_results;

        % 1. Export waveforms_all
        if isfield(spike_results, 'waveforms_all') && ~isempty(spike_results.waveforms_all)

            export_waveforms_all_csv( ...
                spike_results.waveforms_all, ...
                fullfile(outDir, [label '_spike_features.csv']), ...
                fullfile(outDir, [label '_spike_shapes.csv']));
        else
            warning('%s has no spike_results.waveforms_all field.', label);
        end

    
        % 2. Export spike_results.set
        if isfield(spike_results, 'set') && ~isempty(spike_results.set)

            export_spike_set_csv( ...
                spike_results.set, ...
                outDir, ...
                label);
        else
            warning('%s has no spike_results.set field.', label);
        end
    end

    waitbar(1, hWait, 'Finished exporting.');
    pause(0.3);

    if isvalid(hWait)
        close(hWait);
    end

    set_status(h.figure, "ready", "Spike CSV Export Complete.");

    msgbox(sprintf('Spike CSV export complete:\n%s', outDir), ...
        'Export Complete', 'help');

catch ME

    if exist('hWait', 'var') && isvalid(hWait)
        close(hWait);
    end

    set_status(h.figure, "error", "Spike CSV Export Failed.");

    errordlg(sprintf('Error exporting spike CSV:\n%s', ME.message), ...
        'Export Error');
end

end


function export_waveforms_all_csv(waveforms_all, featureFile, shapeFile)
% EXPORT_WAVEFORMS_ALL_CSV Export spike scalar features and spike shapes.

if isempty(waveforms_all)
    return;
end

S = waveforms_all(:);

T = struct2table(S);

% Extract spike_shape separately
hasSpikeShape = ismember('spike_shape', T.Properties.VariableNames);

if hasSpikeShape
    spikeShapes = {S.spike_shape};
    T.spike_shape = [];
end

% Keep only CSV-friendly feature columns
T = keep_csv_friendly_columns(T);

% Add spike index
spike_index = (1:height(T)).';
T = addvars(T, spike_index, 'Before', 1, 'NewVariableNames', 'spike_index');

% Export scalar features
writetable(T, featureFile);

% Export spike shapes
if hasSpikeShape

    try
        shapesMat = cell2mat(cellfun(@(x) x(:).', spikeShapes(:), ...
            'UniformOutput', false));

        sampleNames = matlab.lang.makeValidName( ...
            compose('sample_%d', 1:size(shapesMat, 2)));

        Ts = array2table(shapesMat, 'VariableNames', sampleNames);

        spike_index = (1:height(Ts)).';
        Ts = addvars(Ts, spike_index, 'Before', 1, 'NewVariableNames', 'spike_index');

        writetable(Ts, shapeFile);

    catch
        warning('spike_shape could not be exported as a uniform matrix. Exporting long-format spike shapes.');

        export_variable_length_shapes_csv(spikeShapes, shapeFile);
    end
end

end


function export_spike_set_csv(setData, outDir, label)
% EXPORT_SPIKE_SET_CSV Export spike_results.set into CSV-friendly files.

% 1. Scalar summary metrics
summaryFields = {
    'num_activechans'
    'synchronicity'
    'mean_bursts_rate'
    'std_bursts_rate'
    'mean_spike_rate'
    'std_spike_rate'
    'spike_rate_cluster'
    'mean_fwhm'
    'std_fwhm'
    'mean_ptp_amplitude'
    'std_ptp_amplitude'
};

summary = struct();

 for i = 1:numel(summaryFields)

    fld = summaryFields{i};

    if isfield(setData, fld)

        val = setData.(fld);

        if isnumeric(val) && isscalar(val)
            summary.(fld) = val;

        elseif islogical(val) && isscalar(val)
            summary.(fld) = val;
        end
    end
end

if ~isempty(fieldnames(summary))

    Tsummary = struct2table(summary);

    writetable(Tsummary, ...
        fullfile(outDir, [label '_spike_set_summary.csv']));
end


% 2. Per-channel spike rate
if isfield(setData, 'channels') && isfield(setData, 'spike_rate_per_channel')

    channels = setData.channels(:);
    spikeRate = setData.spike_rate_per_channel(:);

    n = min(numel(channels), numel(spikeRate));

    channels = channels(1:n);
    spikeRate = spikeRate(1:n);

    valid = ~(isnan(channels) | isnan(spikeRate));

    Tchan = table( ...
        channels(valid), ...
        spikeRate(valid), ...
        'VariableNames', {'channel', 'spike_rate'} ...
    );

    writetable(Tchan, ...
        fullfile(outDir, [label '_spike_rate_per_channel.csv']));
end


% 3. Per-channel spike_analysis
if isfield(setData, 'spike_analysis') && ~isempty(setData.spike_analysis)

    try
        Ta = struct2table(setData.spike_analysis(:));

        Ta = keep_csv_friendly_columns(Ta);

        if ~isempty(Ta.Properties.VariableNames)

            writetable(Ta, ...
                fullfile(outDir, [label '_spike_analysis.csv']));
        end

    catch ME
        warning('%s spike_analysis could not be exported: %s', label, ME.message);
    end
end


% 4. Cluster metrics
hasFwhm = isfield(setData, 'fwhm_per_cluster');
hasPtp  = isfield(setData, 'ptp_amplitude_per_cluster');

if hasFwhm || hasPtp

    if hasFwhm
        fwhm = setData.fwhm_per_cluster;
    else
        fwhm = [];
    end

    if hasPtp
        ptp = setData.ptp_amplitude_per_cluster;
    else
        ptp = [];
    end

    n = max(size(fwhm,1), size(ptp,1));

    cluster = (1:n).';

    Tcluster = table(cluster, 'VariableNames', {'cluster'});

    if hasFwhm
        Tcluster.fwhm = nan(n, 2);
        Tcluster.fwhm = fwhm;
    end

    if hasPtp
        Tcluster.ptp_amplitude = nan(n, 2);
        Tcluster.ptp_amplitude = ptp;
    end

    writetable(Tcluster, ...
        fullfile(outDir, [label '_cluster_metrics.csv']));
end

end


function export_variable_length_shapes_csv(spikeShapes, outFile)
% EXPORT_VARIABLE_LENGTH_SHAPES_CSV Export variable-length waveforms as:
%   spike_index,sample_index,value

rows = {};

for i = 1:numel(spikeShapes)

    shape = spikeShapes{i};

    if isempty(shape)
        continue;
    end

    shape = shape(:);

    valid = ~isnan(shape);

    sampleIdx = find(valid);
    values = shape(valid);

    for j = 1:numel(values)

        rows(end+1, :) = { ...
            i, ...
            sampleIdx(j), ...
            values(j)}; %#ok<AGROW>
    end
end

if isempty(rows)
    warning('No spike shape data available to export.');
    return;
end

T = cell2table(rows, ...
    'VariableNames', {'spike_index', 'sample_index', 'value'});

writetable(T, outFile);

end


function T = keep_csv_friendly_columns(T)
% KEEP_CSV_FRIENDLY_COLUMNS Remove nested/vector columns unsuitable for CSV.
%
% Keeps:
%   - numeric/logical/string/categorical vectors
%   - cellstr
%   - cells containing scalar numeric/logical/string/char values
%
% Removes:
%   - nested structs
%   - cell arrays containing vectors/matrices
%   - numeric matrices with multiple columns

vars = T.Properties.VariableNames;
keep = true(1, numel(vars));

for i = 1:numel(vars)

    col = T.(vars{i});

    if isnumeric(col) || islogical(col)

        if isvector(col) || size(col, 2) == 1
            keep(i) = true;
        else
            keep(i) = false;
        end

    elseif isstring(col) || iscategorical(col)

        keep(i) = true;

    elseif iscellstr(col)

        keep(i) = true;

    elseif iscell(col)

        keep(i) = all(cellfun(@is_scalar_csv_value, col));

        if keep(i)
            T.(vars{i}) = cellfun(@scalar_to_char, col, ...
                'UniformOutput', false);
        end

    else

        keep(i) = false;
    end
end

T = T(:, keep);

end


function tf = is_scalar_csv_value(x)
% IS_SCALAR_CSV_VALUE True if a cell content can be written as one CSV cell.

tf = isempty(x) || ...
     (isnumeric(x) && isscalar(x)) || ...
     (islogical(x) && isscalar(x)) || ...
     ischar(x) || ...
     (isstring(x) && isscalar(x));

end


function s = scalar_to_char(x)
% SCALAR_TO_CHAR Convert scalar cell content to char for CSV writing.

if isempty(x)

    s = '';

elseif isnumeric(x) || islogical(x)

    s = num2str(x);

elseif isstring(x)

    s = char(x);

elseif ischar(x)

    s = x;

else

    s = '';
end

end