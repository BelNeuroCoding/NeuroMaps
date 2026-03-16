function PlotFooof_callback(h)
h = guidata(h.figure);
set_status(h.figure,"loading","Computing FOOOF...");

%%  Get selected port 
idx = h.portList.Value;              % positions in the listbox
map = h.portList.UserData;           % Nx2 mapping array [expIdx, portIdx]
selected = map(idx,:);

if size(selected,1) > 1 || h.fooof_toggle.Value % If user chooses to plot global data
    all_psds = {};
    all_fooofed_spectrum = {};
    all_apfit = {};
    all_freqs = {};
    port_labels = {};


for selIdx = 1:size(selected,1)
    expIdx = selected(selIdx,1);
    port_idx = selected(selIdx,2);      
    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    bad_impedance = results.channels(port_idx).bad_impedance;
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if h.excl_imp_toggle.Value
        mask = mask & ~bad_impedance;
    end
    if h.excl_high_STD_toggle.Value
        mask =mask & ~noisy;
    end
    channels = channels(mask);
    if isfield(results,'foof_lfp')
        fooofed_results_fitted = results.foof_lfp(port_idx).foof_results(mask);
        % Extract spectra
        freqs = cell2mat(arrayfun(@(x) x.freqs, fooofed_results_fitted, 'UniformOutput', false)');
        psd = cell2mat(arrayfun(@(x) x.power_spectrum, fooofed_results_fitted, 'UniformOutput', false)');
        fooofed_spectrum = cell2mat(arrayfun(@(x) x.fooofed_spectrum, fooofed_results_fitted, 'UniformOutput', false)');
        apfit = cell2mat(arrayfun(@(x) x.ap_fit, fooofed_results_fitted, 'UniformOutput', false)');
    
        all_freqs{end+1} = freqs;  % should be same across channels/ports
        all_psds{end+1} = psd;
        all_fooofed_spectrum{end+1} = fooofed_spectrum;
        all_apfit{end+1} = apfit;
        port_labels{end+1} = sprintf('Exp%d Port%d', expIdx, results.ports(port_idx).port_id);
    
    end
end
%%  Plot FOOOF results for multiple ports 
children = allchild(h.foof_tab); 
delete(findobj(children, 'Type', 'axes'));  % clear previous axes

h.fooofed_axes(1) = subplot(2,1,1, 'Parent', h.foof_tab); hold on;
h.fooofed_axes(2) = subplot(2,1,2, 'Parent', h.foof_tab); hold on;

nPorts = numel(all_psds);                 % number of selected ports
colors = lines(nPorts);                    % one color per port

hold(h.fooofed_axes(1), 'on');
hold(h.fooofed_axes(2), 'on');
set_status(h.figure,"loading","Plotting FOOOF...");


for p = 1:nPorts
    psd = all_psds{p};
    fooofed_spectrum = all_fooofed_spectrum{p};
    apfit = all_apfit{p};
    freqs = all_freqs{p};

    % Average across channels per port
    avg_psd = mean(psd, 1, 'omitnan');
    avg_fooofed = mean(fooofed_spectrum, 1, 'omitnan');
    avg_apfit = mean(apfit, 1, 'omitnan');

    % Oscillatory power
    osc_power = avg_fooofed - avg_apfit;

    % Top plot: oscillatory power
    plot(h.fooofed_axes(1), freqs(1,:), osc_power, 'Color', colors(p,:), ...
         'LineWidth', 1.5, 'DisplayName', port_labels{p});

    % Bottom plot: PSD + fits
    hLinePSD(p) = plot(h.fooofed_axes(2), freqs(1,:), avg_psd, 'Color', colors(p,:), 'LineWidth', 1.5);
    plot(h.fooofed_axes(2), freqs(1,:), avg_fooofed, '--', 'Color', colors(p,:), 'LineWidth', 1.5);
    plot(h.fooofed_axes(2), freqs(1,:), avg_apfit, ':', 'Color', colors(p,:), 'LineWidth', 1.5);
end

% Top plot finalization
xlabel(h.fooofed_axes(1), 'Frequency (Hz)');
ylabel(h.fooofed_axes(1), 'Oscillatory Power (\muV^2/Hz)');
title(h.fooofed_axes(1), 'Oscillatory Power by Port');
legend(h.fooofed_axes(1), 'show', 'Location', 'northeast');
grid(h.fooofed_axes(1), 'on');
pbaspect(h.fooofed_axes(1), [2 1 1]);

% Bottom plot finalization
xlabel(h.fooofed_axes(2), 'Frequency (Hz)');
ylabel(h.fooofed_axes(2), 'Power (\muV^2/Hz)');
title(h.fooofed_axes(2), 'PSD and FOOOF Fits by Port');
legend(h.fooofed_axes(2), hLinePSD, port_labels, 'Location', 'northeast'); % only PSD lines
set(h.fooofed_axes(2), 'XScale', 'linear', 'YScale', 'linear', 'TickDir','out');
grid(h.fooofed_axes(2), 'on');
pbaspect(h.fooofed_axes(2), [2 1 1]);

hold(h.fooofed_axes(1), 'off');
hold(h.fooofed_axes(2), 'off');


else
    expIdx = selected(1,1);
    port_idx = selected(1,2);      
    % Load results
    if iscell(h.figure.UserData)
        results = h.figure.UserData{expIdx};
    else
        results = h.figure.UserData;
    end
    bad_impedance = results.channels(port_idx).bad_impedance;
    noisy = results.channels(port_idx).high_psd & results.channels(port_idx).high_std;
    channels = results.channels(port_idx).id;
    mask = true(1,numel(channels));
    if h.excl_imp_toggle.Value
        mask = mask & ~bad_impedance;
    end
    if h.excl_high_STD_toggle.Value
        mask =mask & ~noisy;
    end
    channels = channels(mask);
    if isfield(results,'foof_lfp')
    fooofed_results_fitted = results.foof_lfp(port_idx).foof_results(mask);
    all_freqs = cell2mat(arrayfun(@(x) x.freqs, fooofed_results_fitted, 'UniformOutput', false)');
    all_psds = cell2mat(arrayfun(@(x) x.power_spectrum, fooofed_results_fitted, 'UniformOutput', false)');
    all_fooofed_spectrum = cell2mat(arrayfun(@(x) x.fooofed_spectrum, fooofed_results_fitted, 'UniformOutput', false)');
    all_apfit = cell2mat(arrayfun(@(x) x.ap_fit, fooofed_results_fitted, 'UniformOutput', false)');
    oscillatory_power = all_fooofed_spectrum- all_apfit;
    
    SeriesNumber = round(get(h.series_slider, 'Value')); % First figure, port number
    set_status(h.figure,"loading","Plotting FOOOF...");

    children = allchild(h.foof_tab); % Get all children of h.tab4
    delete(findobj(children, 'Type', 'axes')); % Delete only the axes
    h.fooofed_axes(1) = subplot(2,1,1, 'Parent', h.foof_tab);    
    total_oscillatory_power = trapz(all_freqs(SeriesNumber,:), oscillatory_power(SeriesNumber,:));  
    plot(h.fooofed_axes(1),all_freqs(SeriesNumber,:), oscillatory_power(SeriesNumber,:), 'k', 'LineWidth', 1.5);
    %ylim(h.fooofed_axes(1),[0 2])
    pbaspect(h.fooofed_axes(1),[2 1 1])
    title(h.fooofed_axes(1),['Ch: ' num2str(channels(SeriesNumber)) ' Total Oscillatory Power: ' num2str(round(total_oscillatory_power,2))]);
    xlabel('Frequency (Hz)');
    ylabel('Osc. Power (\muV^2/Hz)');
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    
    h.fooofed_axes(2) = subplot(2,1,2, 'Parent', h.foof_tab);
    plot(h.fooofed_axes(2),all_freqs(SeriesNumber,:), all_psds(SeriesNumber,:), 'k','LineWidth',1.5);
    hold on
    % Plot the full model fit
    plot(h.fooofed_axes(2),all_freqs(SeriesNumber,:),all_fooofed_spectrum(SeriesNumber,:),'r--','LineWidth',1.5);
    hold on
    % Plot the aperiodic fit
    plot(h.fooofed_axes(2),all_freqs(SeriesNumber,:), all_apfit(SeriesNumber,:), 'b--','LineWidth',1.5);
    hold on
    %xlim(h.fooofed_axes(2),[1, 200]); % Keep x-axis consistent
    %ylim([0, 1]); % Ensure valid range for linear scale
    set(h.fooofed_axes(2), 'XScale', 'linear', 'YScale', 'linear'); 
    set(h.fooofed_axes(2), 'TickDir', 'out')
    xlabel(h.fooofed_axes(2),'Frequency (Hz)')
    grid on
    grid minor
    ylabel(h.fooofed_axes(2),'Log(Power) (dB/Hz)')
    %ylim(h.fooofed_axes(2),[-2 2])
    pbaspect(h.fooofed_axes(2),[2 1 1])
    legend('Original Spectrum', 'Full Model Fit', 'Aperiodic Fit','Location','northeast')
    hold off;
    axtoolbar({'save','zoomin','zoomout','restoreview','pan'});
    end
end
set_status(h.figure,"ready","FOOOF Complete...");

end