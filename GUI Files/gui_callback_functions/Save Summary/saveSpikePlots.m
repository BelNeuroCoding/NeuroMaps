function saveSpikePlots()
 h = guidata(gcf);

    if h.totalPlots == 0
        warndlg('No spike plots to save.');
        return;
    end

    % Ask user for filename
    [file,path] = uiputfile({'*.fig','MATLAB Figure (*.fig)';
                             '*.png','PNG Image (*.png)';
                             '*.svg','SVG Vector Graphic (*.svg)'},...
                             'Save Spike Plots','spike_plots');
    if isequal(file,0), return; end

    % Create invisible figure
    f = figure('Visible','off');

    % Copy only axes (exclude buttons)
    axesToCopy = findobj(h.spikes_tab,'Type','axes');  % only axes
    copyobj(axesToCopy,f);
    

    % Save file
    [~,~,ext] = fileparts(file);
    fullFile = fullfile(path,file);

    switch lower(ext)
        case '.fig'
            savefig(f,fullFile);
        case '.png'
            exportgraphics(f,fullFile,'Resolution',300);
        case '.svg'
            print(f,fullFile,'-dsvg');   % <-- old-style SVG export
    end

    close(f);
end