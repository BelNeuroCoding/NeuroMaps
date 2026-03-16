function fooof_callback(h)
    h = guidata(h.figure);
    set_status(h.figure,"loading","LFP Analysis Initiated");

    %% Ask user which steps to perform
    steps = {'Fit FOOOF', 'Plot FOOOF', 'Plot Oscillatory Power', 'Plot Exponent', 'Compute Bandpower'};
    [sel, ok] = listdlg('PromptString','Select steps to perform:', ...
                        'SelectionMode','multiple', ...
                        'ListString', steps, ...
                        'Name', 'LFP Analysis Steps');
    if ~ok || isempty(sel)
        set_status(h.figure,"error","LFP Analysis Cancelled");
        return; % user canceled
    end

    doFit        = ismember(1, sel);
    doPlotFooof  = ismember(2, sel);
    doPlotOsc    = ismember(3, sel);
    doPlotExp    = ismember(4, sel);
    doBandpower  = ismember(5, sel);

    %% Get selected ports
    idx = h.portList.Value;           % positions in the listbox
    map = h.portList.UserData;        % Nx2 mapping array [expIdx, portIdx]
    selected = map(idx,:);

    %% Initialize waitbar
    wb = waitbar(0,'Analysing LFP on selected data...','Name','LFP');
    cleanupObj = onCleanup(@() delete(wb));

    nSelected = size(selected,1);

    for i = 1:nSelected
        expIdx = selected(i,1);
        selected_idx = selected(i,2);

        %% Load results
        if iscell(h.figure.UserData)
            results = h.figure.UserData{expIdx};
        else
            results = h.figure.UserData;
        end

        lfp_filt = results.signals(selected_idx).lfp;           % filtered LFP
        fs_lfp   = results.filt_params(selected_idx).lfp;       % sampling rate

        %% Fit FOOOF
        if doFit
            set_status(h.figure,"loading",sprintf("Fitting FOOOF: Exp %d Port %d",expIdx,selected_idx));
            tic
            fooof_results_fitted = fit_lfps(lfp_filt', fs_lfp, results(selected_idx).filt_params);
            t_elapsed_fitting_lfp = toc;
            fprintf('Time Elapsed Fitting LFP: %.3f s \n', t_elapsed_fitting_lfp);
            results.foof_lfp(selected_idx).foof_results = fooof_results_fitted;
            set_status(h.figure,"ready",sprintf("FOOOF Complete: Exp %d Port %d",expIdx,selected_idx));
        end

        %% Save updated results
        if iscell(h.figure.UserData)
            allresults = h.figure.UserData;
            allresults{expIdx} = results;
            set(h.figure, 'UserData', allresults);
        else
            set(h.figure, 'UserData', results);
        end

        %% Update waitbar
        waitbar(i/nSelected, wb);
    end

    %% Create LFP tabs if needed
    if ~isfield(h,'lfp_main_tab') || ~isvalid(h.lfp_main_tab)
        create_lfp_foof_tabs(h);
    end

    h = guidata(h.figure);

    %% Call downstream analysis if selected
    if doPlotFooof
        set_status(h.figure,"loading","Plotting FOOOF...");
        PlotFooof_callback(h);
        set_status(h.figure,"ready","FOOOF Plot Complete.");
    end

    if doPlotOsc
        set_status(h.figure,"loading","Plotting Oscillations...");
        plot_osc_callback(h);
        set_status(h.figure,"ready","Oscillation Plot Complete.");
    end

    if doPlotExp
        set_status(h.figure,"loading","Plotting Experiment...");
        plot_exp_callback(h);
        set_status(h.figure,"ready","Experiment Plot Complete.");
    end

    if doBandpower
        set_status(h.figure,"loading","Computing Bandpower...");
        bandpower_callback(h);
        set_status(h.figure,"ready","Bandpower Complete.");
    end

    %% Save final guidata
    guidata(h.figure,h);
end