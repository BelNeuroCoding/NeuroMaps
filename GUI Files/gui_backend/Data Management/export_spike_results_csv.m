function export_spike_results_csv(h)
% EXPORT_SPIKE_RESULTS_CSV Export spike_results.waveforms_all and spike_results.set as CSV.
%
% Exports:
%   - spike_features.csv : scalar spike features
%   - spike_shapes.csv   : spike_shape waveforms, one spike per row
%   - spike_set.csv      : scalar fields from spike_results.set

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

for s = 1:numel(selIdx)

    expIdx = comboMap(selIdx(s), 1);
    portIdx = comboMap(selIdx(s), 2);

    res = results{expIdx};

    if ~isfield(res, 'spike_results') || isempty(res.spike_results)
        warning('%s has no spike_results field. Skipping.', comboList{selIdx(s)});
        continue;
    end

    label = sprintf('Exp_%d_Port_%d', ...
        expIdx, res.ports(portIdx).port_id);

    spike_results = res.spike_results;

    %  waveforms_all 
    if isfield(spike_results, 'waveforms_all') && ~isempty(spike_results.waveforms_all)

        S = spike_results.waveforms_all(:);
        T = struct2table(S);

        if ismember('spike_shape', T.Properties.VariableNames)

            spikeShapes = {S.spike_shape};
            T.spike_shape = [];

            % Save waveform samples separately
            try
                shapesMat = cell2mat(cellfun(@(x) x(:).', spikeShapes(:), ...
                    'UniformOutput', false));

                sampleNames = matlab.lang.makeValidName( ...
                    compose('sample_%d', 1:size(shapesMat, 2)));

                Ts = array2table(shapesMat, 'VariableNames', sampleNames);
                Ts.spike_index = (1:height(Ts)).';
                Ts = movevars(Ts, 'spike_index', 'Before', 1);

                writetable(Ts, fullfile(outDir, [label '_spike_shapes.csv']));

            catch
                warning('%s spike_shape could not be exported as CSV matrix.', label);
            end
        end

        % Add spike index
        T.spike_index = (1:height(T)).';
        T = movevars(T, 'spike_index', 'Before', 1);

        writetable(T, fullfile(outDir, [label '_spike_features.csv']));
    end

    %  set 
    if isfield(spike_results, 'set') && ~isempty(spike_results.set)

        try
            Tset = struct2table(spike_results.set(:));
            writetable(Tset, fullfile(outDir, [label '_spike_set.csv']));
        catch
            warning('%s spike_results.set could not be exported as CSV.', label);
        end
    end
end

set_status(h.figure, "ready", "Spike CSV Export Complete.");

msgbox(sprintf('Spike CSV export complete:\n%s', outDir), ...
    'Export Complete', 'help');

end