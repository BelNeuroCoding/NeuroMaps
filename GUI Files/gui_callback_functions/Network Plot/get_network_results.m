function [results, selected_idx, unique_channels, sttc_matrix, latency_matrix] = get_network_results(h)
    h = guidata(h.figure);
    %%  Get selected port 
    idx = h.portList.Value;              % positions in the listbox
    map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
    selected = map(idx,:);
    
    % Only allow one experiment & port
    if size(selected,1) > 1
        uniqueExpts = unique(selected(:,1));
        uniquePorts = unique(selected(:,2));
        if numel(uniqueExpts) > 1 || numel(uniquePorts) > 1
            errordlg('Please select only 1 experiment and 1 port for plotting traces.');
            return
        end
    end
    
    expIdx = selected(1,1);
    selected_idx = selected(1,2);      
    
    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end

    unique_channels = results.network_analysis(selected_idx).unique_chans;

    sttc_matrix = results.network_analysis(selected_idx).sttc;
    latency_matrix = results.network_analysis(selected_idx).latency;
end
