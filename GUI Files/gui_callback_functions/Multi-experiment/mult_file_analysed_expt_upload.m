function mult_file_analysed_expt_upload(h)
%% Load multiple previously saved experiment results and aggregate
h = guidata(h.figure);

% Let user select multiple .mat files
[FileNames, FilePath, FlagUp] = uigetfile('*.mat', ...
    'Select Experiment Result Files', 'MultiSelect', 'on');

if ~FlagUp
    disp('User cancelled file selection.');
    return;
end

if ischar(FileNames)
    FileNames = {FileNames}; % convert single selection to cell
end

allResults = {}; % preallocate cell array
hWait = waitbar(0, 'Loading files...');  % create waitbar
for i = 1:length(FileNames)
    fullFileName = fullfile(FilePath, FileNames{i});
    loaded = load(fullFileName);
    
    if isfield(loaded, 'resultsToSave')
        allResults{i} = loaded.resultsToSave;
    elseif isfield(loaded,'wclustered')
        allResults{i}.fs = loaded.wclustered.fs;
        allResults{i}.metadata.filename = loaded.wclustered.experimental_ID{1};
        allResults{i}.metadata.date = datestr(datetime(loaded.wclustered.experimental_ID{1}(1:end-7),'InputFormat','yyMMdd'),'dd-mmm-yyyy');
        allResults{i}.timestamps = loaded.wclustered.TimeStamps;
        for p = 1:numel(loaded.wclustered.clustered)
            allResults{i}.spike_results(p).waveforms_all =  loaded.wclustered.clustered{p};
            if isfield(allResults{i}.spike_results(p).waveforms_all,'cluster')
                [allResults{i}.spike_results(p).waveforms_all.clusters] = allResults{i}.spike_results(p).waveforms_all.cluster;
            end
            allResults{i}.ports(p).port_id = p;
        end
    else
        warning('File %s does not contain ''resultsToSave''. Skipping.', FileNames{i});
    end
    waitbar(i/length(FileNames), hWait, sprintf('Loading file %d of %d...', i, length(FileNames)));

end
close(hWait);

% Check if at least one experiment was loaded
if isempty(allResults)
    errordlg('No valid experiment results loaded.', 'Load Error');
    return;
end

% Update GUI
h.figure.UserData = allResults;

% Update experiment list for GUI if applicable
expNames = cellfun(@(r) r.metadata.filename, allResults, 'UniformOutput', false);
if isfield(h, 'expList') && ~isempty(h.expList)
    set(h.expList, 'String', expNames, 'Value', 1);
end

guidata(h.figure,h);
create_multi_experiment_selector(h);
m=msgbox(sprintf('Loaded %d experiments successfully.', length(allResults)), ...
       'Load Complete', 'help');
t= timer('StartDelay',2,'TimerFcn',@(~,~)delete(m));
start(t);
updateSummary(h);
end
