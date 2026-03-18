function run_referencing_pipeline(h)
h = guidata(h.figure);  
 set_status(h.figure,"loading","Referencing Signal...");

% Get selected port indices
idx = h.portList.Value;           % positions in the listbox
map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);            % rows correspond to each selected port

% Check if the user wants to analyze only good channels
exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');
n = size(selected,1);
wb = waitbar(0,'Referencing all selected data..','Name','Referencing');
cleanupObj = onCleanup(@() delete(wb));
tic
% Loop over all selected ports
for i = 1:size(selected,1)
    expIdx = selected(i,1);
    portIdx = selected(i,2);

    % Load experiment results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    selectedport = results.ports(portIdx).port_id;

    % Select which data to reference
    if isfield(results.signals(portIdx),'hpf') && ~isempty(results.signals(portIdx).hpf) && i==1
        choice = questdlg(['Which data do you want to use for referencing on Port ' num2str(selectedport) '?'], ...
                          'Select Data', 'Raw', 'Filtered','Raw');
    else 
        choice = 'Raw';
    end

    switch choice
        case 'Raw'
            Data = results.signals(portIdx).raw;
            lab = 'Broadband';
        case 'Filtered'
            Data = results.signals(portIdx).hpf;
            lab = 'Filtered';
    end

    % Determine referencing method
    reftype = get(h.referenced_data_options, 'Data');
    operator = get(h.referenced_data_options, 'UserData');
    Channels = results.channels(portIdx).id;

    bad_impedance = results.channels(portIdx).bad_impedance;
    noisy = results.channels(portIdx).high_psd & results.channels(portIdx).high_std;
    mask = true(1,numel(Channels));
    if exclude_impedance_chans_toggle
        mask = mask & ~bad_impedance;
    end
    if exclude_noisy_chans_toggle
        mask =mask & ~noisy;
    end
    referenced_signal = zeros(size(Data));

    if strcmpi(reftype{1}, 'global')
        switch lower(operator{1})
            case 'median (recommended)'
                referenced_signal(mask,:) = Data(mask,:) - median(Data(mask,:),1);
            case 'average'
                referenced_signal(mask,:) = Data(mask,:) - mean(Data(mask,:),1);
            otherwise
                error('Invalid operator selected.');
        end
    else
        msgbox('Only Global Functionality Available Now', 'Warning', 'warn');
        continue;
    end
    results.signals(portIdx).ref = referenced_signal;
    % Save updated results
    if iscell(h.figure.UserData)
        allresults = h.figure.UserData;
        allresults{expIdx} = results;
        set(h.figure, 'UserData', allresults);
    else
        set(h.figure, 'UserData', results);
    end

    % Update GUI
    if isfield(h.formatsPlot,'Ref') && isvalid(h.formatsPlot.Ref)
        delete(h.formatsPlot.Ref);  % remove the old one
    end
    h.formatsPlot.Ref = uicontrol('Style', 'radiobutton', 'String', 'Ref', ...
    'Units', 'normalized', 'Position', [0.3, 0.1, 0.2, 0.8], ...
    'Parent', h.formatToggleGroup,'BackgroundColor',[1 1 1],'ForegroundColor',[0.1, 0.4, 0.6]);
    currentText = get(h.summary_text,'String');
    if ischar(currentText), currentText = cellstr(currentText); end
    newMsg = sprintf('Performed %s referencing on %s data using %s operator - Port %s', ...
                     reftype{1}, lab, operator{1}, num2str(selectedport));
    currentText{end+1} = newMsg;
    set(h.summary_text,'String',currentText);
    waitbar(i/n,wb,sprintf('Referencing port %d of %d',i,n));
end
delete(wb);
t_refs = toc;
disp(['Referencing took: ' num2str(t_refs)])
 set_status(h.figure,"ready","Referencing Complete...");

h=guidata(h.figure);
guidata(h.figure, h);
init_traces_tab(h);
update_traces_tab(h);
end
