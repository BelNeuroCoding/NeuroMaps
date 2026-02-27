function updateclusternumValue(src, handles)
    % Callback function to update STD value
    new_val = get(src, 'Value');
    set(handles.clusternums_value, 'String', num2str(new_val, '%.1f'));
    % Update your processing with the new STD value if necessary
end