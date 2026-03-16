function openSystemSelectionDialog(h)
    backgdcolor = [1, 1, 1]; % Background Colours RGB - default white
    accentcolor = [0.1, 0.4, 0.6]; % Accent Colours RGB
    h = guidata(h.figure);
    % Define the dialog height
    dialogHeight = 200;  

    % Create the dialog
    d = dialog('Position', [300, 300, 300, dialogHeight], 'Name', 'Select Measurement Type','Color',backgdcolor);
    
    % Define the options
    options = {'RHS', 'MCS H5', 'RHD','Analysed Dataset'};
    
    % Create radio buttons for each option
    numOptions = length(options);
    hButtonGroup = uibuttongroup('Parent', d, ...
        'Position', [0 0.1 1 0.9], ...
        'BackgroundColor', backgdcolor, ...
        'BorderType', 'none');
    radioButtons = gobjects(1, numOptions);  % Preallocate array for radio buttons
    % Store the selected system in the handles structure
    h.selectedSystem = '';
    for i = 1:numOptions
        radioButtons(i) = uicontrol('Parent', hButtonGroup, ...
            'Style', 'radiobutton', ...
            'Units', 'normalized', ...
            'Position', [0.1, 0.8 - (i-1) * 0.2, 0.8, 0.1], ...
            'String', options{i}, ...
            'Fontsize', 9, ...
            'BackgroundColor', backgdcolor,...
            'ForegroundColor',accentcolor);
    end
    

    % Create a confirm button
    uicontrol('Parent', d, ...
        'Style', 'pushbutton', ...
        'Position', [115, 20, 70, 25], ...
        'String', 'Confirm', ...
        'Callback', @(src, event) confirmSystemSelection(h,d, radioButtons,options));


function confirmSystemSelection(h, d, radioselection, options)
    h = guidata(h.figure);
    % Initialize selectedSystem as empty
    h.selectedSystem = [];

    % Loop through the radio buttons to find the selected one
    for i = 1:length(radioselection)
        if get(radioselection(i), 'Value') == 1
            h.selectedSystem = options{i}; % Assign the selected system
            break; % Exit the loop once the selected option is found
        end
    end

    % Check if a selection was made
    if isempty(h.selectedSystem)
        % Display a message if no option was selected
        msgbox('Please select a measurement system.', 'Error', 'error');
        delete(d)
    else
        delete(d)
        if strcmp(h.selectedSystem,'Analysed Dataset')
            mult_file_analysed_expt_upload(h);
        else
        % Call the load_data_callback function with the selected system
        load_data_callback(h);
        end
    end
end
end