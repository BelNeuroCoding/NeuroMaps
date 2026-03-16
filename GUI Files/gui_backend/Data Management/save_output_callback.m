function save_output_callback(h)
    % SAVE_OUTPUT_CALLBACK Save selected fields from one or more experiment/port results

    results = get(h.figure,'UserData');
    set_status(h.figure,"loading","Saving Data...");

    % Ensure results is a cell array
    if ~iscell(results)
        results = {results};
    end
    
    if isempty(results)
        errordlg('No results available to save.');
        return;
    end
    
    % Build list of all Exp/Port combinations
    comboList = {};
    comboMap = []; % Map back to exp/port indices
    for expIdx = 1:numel(results)
        res = results{expIdx};
        if isfield(res,'ports') && ~isempty(res.ports)
            for portIdx = 1:numel(res.ports)
                comboList{end+1} = sprintf('Exp %d Port %d', expIdx, res.ports(portIdx).port_id); %#ok<AGROW>
                comboMap(end+1,:) = [expIdx portIdx]; %#ok<AGROW>
            end
        end
    end
    
    % Ask user which Exp/Port combos to save
    [selIdx, tf] = listdlg('ListString', comboList, ...
                            'SelectionMode','multiple', ...
                            'Name','Select Exp/Port Combinations', ...
                            'PromptString','Choose which Exp/Port combos to save:');
    if ~tf
        disp('User cancelled selection.');
        return;
    end
        % Define mandatory fields
    mandatoryFields = {'metadata','fs','timestamps','ports','electrical_properties','channels','filt_params','resampled_time','network_analysis','foof_lfp'}; % adjust as needed

    % Loop through selected Exp/Port combos
    for s = 1:numel(selIdx)
        expIdx = comboMap(selIdx(s),1);
        portIdx = comboMap(selIdx(s),2);
        res = results{expIdx};
        
        % Ask user which fields to save for this port
        fldNames = fieldnames(res);
        [fldIdx, tfFld] = listdlg('ListString', fldNames, ...
                                  'SelectionMode', 'multiple', ...
                                  'Name', ['Fields for ' comboList{selIdx(s)}], ...
                                  'PromptString', 'Choose fields to include in saved file:');
        if ~tfFld
            fprintf('User skipped %s\n', comboList{selIdx(s)});
            continue;
        end
        % Always include mandatory fields (if they exist in struct)
        selectedFields = fldNames(fldIdx);
        for mf = 1:numel(mandatoryFields)
            if isfield(res, mandatoryFields{mf}) && ~ismember(mandatoryFields{mf}, selectedFields)
                selectedFields{end+1} = mandatoryFields{mf};
            end
        end
        totalSteps = numel(selIdx) * numel(selectedFields);

        % Build struct to save
        resultsToSave = struct();
        for i = 1:numel(selectedFields)
            if s == 1 && i==1
                hWait = waitbar(0,'Preparing data for saving...');
            end
            resultsToSave.(selectedFields{i}) = res.(selectedFields{i});
        end

        % Default filename
        fname = strrep(comboList{selIdx(s)}, ' ', '_');  % 'Exp_2_Port_4'
        defaultFileName = sprintf('%s_Results.mat', fname);

        
        % Ask where to save
        [fileName, filePath] = uiputfile(defaultFileName, ['Save as: ' defaultFileName]);
        if isequal(fileName,0) || isequal(filePath,0)
            fprintf('User cancelled save for %s\n', comboList{selIdx(s)});
            continue;
        end
        fullFileName = fullfile(filePath, fileName);
        
        % Save
        try
            waitbar(0.5,hWait,'Saving MAT File. Please Wait...');
            save(fullFileName, 'resultsToSave', '-v7.3');
            waitbar(1,hWait,'Finished saving.');
            pause(0.5)
            close(hWait)
            msgbox(sprintf('%s saved to %s', comboList{selIdx(s)}, fullFileName), ...
                   'Save Complete', 'help');
        catch ME
            errordlg(sprintf('Error saving %s: %s', comboList{selIdx(s)}, ME.message), 'Save Error');
        end
    end
        set_status(h.figure,"ready","Data Saved Successfully...");


end
