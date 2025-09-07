function fooof_callback(h)
h = guidata(h.figure);
%%  Get selected port 
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);


wb = waitbar(0,'Analysing LFP on all selected data..','Name','LFP');
cleanupObj = onCleanup(@() delete(wb));
% Loop through each selected exp/port
for i = 1:size(selected,1)
    expIdx = selected(i,1);
    selected_idx = selected(i,2);      
    
    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    
    lfp_filt = results.signals(selected_idx).lfp; % LFP filtered dataset (chans x timepoints)
    fs_lfp = results.filt_params(selected_idx).lfp;
    
    fooof_results_fitted = fit_lfps(lfp_filt',fs_lfp,results(selected_idx).filt_params);
    results.foof_lfp(selected_idx).foof_results = fooof_results_fitted;
    % Save updated results
    if iscell(h.figure.UserData)
        allresults = h.figure.UserData;
        allresults{expIdx} = results;
        set(h.figure, 'UserData', allresults);
    else
        set(h.figure, 'UserData', results);
    end
end
if ~isfield(h,'lfp_main_tab') || ~isvalid(h.lfp_main_tab)
create_lfp_foof_tabs(h)
end
h = guidata(h.figure);
guidata(h.figure,h)
PlotFooof_callback(h)
plot_osc_callback(h)
plot_exp_callback(h)
bandpower_callback(h)
end