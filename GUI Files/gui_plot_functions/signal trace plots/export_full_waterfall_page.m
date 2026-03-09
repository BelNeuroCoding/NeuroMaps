function export_full_waterfall_page(h)
    % Ask user for filename
    [file, path] = uiputfile({'*.png';'*.pdf'}, 'Save Waterfall Page As', 'waterfall_page.png');
    if isequal(file,0), return; end
    filename = fullfile(path,file);

    % Find all waterfall axes
    axesList = findall(h.waterfall_tab,'Type','axes');
    if isempty(axesList)
        msgbox('No waterfall plots to export','Info');
        return
    end

    fig = figure();
    figWidth = 1200; % fixed width
    figHeight = 0;

    % First, compute total vertical size needed
    for k = 1:length(axesList)
        ax = axesList(k);
        % Estimate full height based on number of lines/channels
        numChannels = length(ax.Children); % each line + text counts, might adjust
        channelHeight = 60; 
        figHeight = figHeight + numChannels*channelHeight + 50; % padding
    end
    fig.Position = [100 100 figWidth figHeight];

    % Stack axes vertically
    yPos = figHeight;
    for k = 1:length(axesList)
        ax = axesList(k);
        % Retrieve original data
        lines = findall(ax,'Type','line');
        texts = findall(ax,'Type','text');

        % Determine full time range
        xMin = min(arrayfun(@(l) min(l.XData), lines));
        xMax = max(arrayfun(@(l) max(l.XData), lines));

        % Compute full height
        numChannels = length(lines);
        height = max(numChannels*60,50);

        % Create axes in export figure
        hold on;

        % Copy lines
        for li = 1:length(lines)
            plot(lines(li).XData, lines(li).YData, 'Color', lines(li).Color);
        end

        % Copy texts (labels, scale bars)
        for ti = 1:length(texts)
            t = texts(ti);
            text(t.Position(1), t.Position(2), t.String, ...
                 'Color', t.Color, 'FontSize', t.FontSize, ...
                 'HorizontalAlignment', t.HorizontalAlignment, ...
                 'VerticalAlignment', t.VerticalAlignment);
        end

        hold off
        axis off

        yPos = yPos - height - 20; % padding between tiles
    end

    % Export to file
    exportgraphics(fig, filename);
    close(fig);

    msgbox(['Waterfall page exported to: ' filename],'Success');
end