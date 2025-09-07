function plot_heatmap_callback(var, chans, Zlabel,x_coords,y_coords,img,col,clims)

if nargin <4
    % Define Grid
    x_coords = [452.274319066148	574.247081712062	422.490272373541	557.227626459144	616.795719844358	554.391050583658	445.182879377432	436.673151750973	443.764591439689	524.607003891051	425.326848249027	496.241245136187	633.815175097276	540.208171206226	455.110894941634	466.457198443580	357.249027237354	354.412451361868	239.531128404669	178.544747081712	240.949416342412	372.850194552529	219.675097276265	343.066147859922	327.464980544747	340.229571984436	263.642023346304	162.943579766537	299.099221789883	377.105058365759	272.151750972763	350.157587548638];
    y_coords = [428.113813229572	500.446498054475	367.127431906615	333.088521400778	269.265564202335	169.985408560311	255.082684824903	188.423151750973	120.345330739300	239.481517509728	323.160505836576	340.179961089494	395.493190661479	426.695525291829	494.773346303502	558.596303501946	508.956225680934	433.786964980545	525.975680933852	423.858949416342	358.617704280156	321.742217898833	189.841439688716	262.174124513619	137.364785992218	196.932879377432	267.847276264591	303.304474708171	355.781128404669	371.382295719844	453.642996108949	574.197470817121];
    x_coords = round(x_coords);
    y_coords = round(y_coords);
end
    % Compute electrode grid dimensions
    x_min = round(min(x_coords)); x_max = round(max(x_coords)); 
    y_min = round(min(y_coords)); y_max = round(max(y_coords));
    grid_size_x = x_max - x_min + 200; grid_size_y = y_max - y_min + 200;
    col = 'k';

    [Y, X] = ndgrid(1:grid_size_y, 1:grid_size_x);
    X_shifted = X + x_min;
    Y_shifted = Y + y_min;
    
    % Precompute centers
    x_centers = x_coords;
    y_centers = y_coords;
    
    if nargin > 5
        % Load background image
        imagefile = imread(img);
    
        % Show image with correct scaling
        imshow(imagefile, 'XData', [x_min x_max], 'YData', [y_min y_max]);
        hold on;
    end
    
    % Initialise heatmap
    heatmap = nan(grid_size_y, grid_size_x);


    % Precompute the mask template
    radius_squared = 80;
    for t = 1:length(chans)
        x_center = x_centers(chans(t)+1)+100;
        y_center = y_centers(chans(t)+1)+100;
       % mask = ((X - x_center).^2 + (Y - y_center).^2) <= radius_squared;
        mask = ((X_shifted - x_center).^2 + (Y_shifted - y_center).^2) <= radius_squared;
        heatmap(mask) = var(t);
    end

    % Plot the heatmap
    hImg = imagesc(heatmap);
    cs = colorbar('southoutside');
    if nargin <8
        clims = [min(heatmap(:)), max(heatmap(:))];
    end
    cs.Limits = clims;
    % Set transparency
    colormap('turbo');
    cs.Label.String = Zlabel;
    % Move tick labels to bottom
    cs.AxisLocation = 'out';  % tick marks outside of colorbar
    set(cs, 'TickDirection', 'out');
    %cs.Label.Rotation = 270;
    %cs.Label.VerticalAlignment = 'bottom';
    cs.Label.Rotation = 0;    % horizontal orientation
    cs.Label.VerticalAlignment = 'top';   % align vertically along colorbar
    cs.Label.HorizontalAlignment = 'center'; % align horizontally
    alpha_value = 0.9; % 1 fully opaque, 0 transparent

    alpha_data = ~isnan(heatmap);
    set(hImg, 'AlphaData', alpha_data*alpha_value);
    % Scatter plot of original points
    hold on;
    %hScatter = scatter(x_centers(var>0), y_centers(var>0), 'b');

    % Plot channel numbers
    for t = 1:length(chans)
        text(x_centers(chans(t)+1)-x_min+ 130, y_centers(chans(t)+1)-y_min+100, num2str(chans(t)), 'Color', col, 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end

    % Adjust axis
    %set(gca, 'YDir', 'normal');
    axis tight;
    axis equal;
    axis off; % Super important
    box off;
    set(gca, 'Color', 'none'); 
    % Enable brush mode for selecting multiple points
    %brush on;
    %brushObj = brush(gcf);
    %set(brushObj, 'ActionPostCallback', @brush_callback);

    % Global variable to store selected indices
    %global selectedIndices;
    %selectedIndices = [];

    % Callback function to update opacity and store selected indices
    function brush_callback(~, ~)
        % Get the brushed data
        brushedIdx = logical(hScatter.BrushData);
        if any(brushedIdx)
            selectedPoints = find(brushedIdx);
            unselectedPoints = find(~brushedIdx);

            % Store the selected indices in the global variable
            selectedIndices = selectedPoints - 1; % Adjust for 0-based indexing if needed

            % Update the heatmap transparency
            selectedMask = false(size(heatmap));
            unselectedMask = false(size(heatmap));
            for t = selectedPoints
                x_center = x_centers(t);
                y_center = y_centers(t);
                mask = ((X - x_center).^2 + (Y - y_center).^2) <= radius_squared;
                selectedMask = selectedMask | mask;
            end
            for t = unselectedPoints
                x_center = x_centers(t);
                y_center = y_centers(t);
                mask = ((X - x_center).^2 + (Y - y_center).^2) <= radius_squared;
                unselectedMask = unselectedMask | mask;
            end
            set(hImg, 'AlphaData', selectedMask * 1 + unselectedMask * 0.1); % Adjust transparency levels here
        else
            % Reset to original transparency if nothing is selected
            set(hImg, 'AlphaData', alpha_data);

            % Clear the selected indices
            selectedIndices = [];
        end
    end

   % axtoolbar({'datacursor', 'save', 'zoomin', 'zoomout', 'restoreview', 'pan'});
end
