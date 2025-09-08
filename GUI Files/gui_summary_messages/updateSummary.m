function updateSummary(h)
    % This function updates the data log summary
    
    % Get all results from UI
    h = guidata(h.figure);  
    allResults = get(h.figure,'UserData');
    if ~iscell(allResults)
        allResults = {allResults}; 
    end
    numExpts = length(allResults);

    % Initialise summary string
    summaryStr = sprintf('Experiments Loaded: %d\n', numExpts);

    % Loop through experiments
    for j = 1:numExpts
        results = allResults{j};
        Ports = [results.ports.port_id];
        % Loop through ports
        for i = 1:length(Ports)
            % Safe access with fallbacks
            filename = '';
            if isfield(results, 'metadata') && isfield(results.metadata, 'filename')
                filename = results.metadata.filename;
            end
            
            dateStr = '';
            if isfield(results, 'metadata') && isfield(results.metadata, 'date')
                dateStr = char(results.metadata.date);
            end
            
            fs = NaN;
            if isfield(results, 'fs')
                fs = round(results.fs);
            end
            
            port_id = 'NaN';
            if isfield(results, 'ports') && length(results.ports) >= i && isfield(results.ports(i), 'port_id')
                port_id = results.ports(i).port_id;
            end
            
            numChannels = 'NaN';
            if isfield(results, 'channels') && length(results.channels) >= i && isfield(results.channels(i), 'id')
                numChannels = length(results.channels(i).id);
            end
            
            minImp = 'NaN'; maxImp = 'NaN';
            if isfield(results, 'electrical_properties') && length(results.electrical_properties) >= i ...
                    && isfield(results.electrical_properties(i), 'electrode_impedance')
                minImp = min(results.electrical_properties(i).electrode_impedance);
                maxImp = max(results.electrical_properties(i).electrode_impedance);
            end
            
            % Append to summary
            summaryStr = [summaryStr, sprintf([ ...
                'Data Summary:\n' ...
                '-----------------------------\n' ...
                'File Name: %s\n' ...
                'Date: %s\n' ...
                'Sampling Frequency (Hz): %s\n' ...
                'Port: %s\n' ...
                'Number of Channels: %s\n' ...
                'Minimum Impedance: %s kOhms\n' ...
                'Max Impedance: %s kOhms \n'], ...
                string(filename), ...
                string(dateStr), ...
                string(fs), ...
                string(port_id), ...
                string(numChannels), ...
                string(minImp), ...
                string(maxImp))];
            
            % Update summary text in GUI
            set(h.summary_text, 'String', summaryStr);
        end

    end

    % Helper function
    function str = logical2str(val)
        if val
            str = 'Yes';
        else
            str = 'No';
        end
    end
end
