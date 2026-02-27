function save_summary_text(h)

    % Get text from UI
    spikeSummaryText = get(h.spike_summary_text,'String');

    % Convert to cell array if needed
    if ischar(spikeSummaryText)
        spikeSummaryText = cellstr(spikeSummaryText);
    end

    % Ask user where to save
    [file, path] = uiputfile('*.txt', 'Save Spike Summary As');

    if isequal(file,0)
        return; % user cancelled
    end

    fullFileName = fullfile(path,file);

    % Open file safely
    fid = fopen(fullFileName,'w');
    if fid == -1
        errordlg('Could not create file.');
        return;
    end

    % Write main summary

    fprintf(fid, '\n\n=== SPIKE SUMMARY ===\n\n');

    % Write spike summary
    for i = 1:numel(spikeSummaryText)
        fprintf(fid, '%s\n', spikeSummaryText{i});
    end

    fclose(fid);

    msgbox('Summary saved successfully.');

end