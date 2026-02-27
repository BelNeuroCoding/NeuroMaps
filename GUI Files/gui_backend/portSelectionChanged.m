function portSelectionChanged(~, eventdata)
    selectedPort = eventdata.NewValue.String;
    h = guidata(gcf);  % Retrieve handles structure
    % Update plots or data based on selected port
    
end