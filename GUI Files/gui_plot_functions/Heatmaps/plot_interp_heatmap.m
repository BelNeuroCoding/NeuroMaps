function plot_interp_heatmap(var, chans, Zlabel,x_coords,y_coords)
    % Inputs:
    % - var: Spike rate or other variable to plot in heatmap.
    % - chans: The channel numbers corresponding to the data.
    % - Zlabel: Label for the colorbar (e.g., 'Spike Rate (Hz)').
    % x_coords, y_coords
    
    % Define Grid
     if nargin< 6 || isempty(range)
         min_rate = floor(min(var));
         max_rate = ceil(max(var));
     else
         min_rate = range(1);
         max_rate = range(2);
     end
     if nargin < 4
        x_coords = [115.4919, 155.7933, 216.2454, 230.9005, 269.9807, 293.7951, 350.5835, 391.1902, 294.7111, 351.8048, ...
                     250.4406, 226.3208, 179.6078, 102.3634, 66.6416, 168.3111, 171.3643, 114.2706, 214.4135, ...
                     238.8386, 284.3304, 360.9642, 296.5430, 349.0569, 396.3806, 309.0608, 249.8299, 234.5642, ...
                     194.8735, 171.3643, 122.2088, 73.6639];
        y_coords = [195.9215, 242.5832, 186.5073, 227.0293, 302.7521, 247.9042, 269.5978, 208.6102, 202.0612, ...
                     270.0071, 184.8701, 259.7743, 295.3845, 263.0488, 200.8333, 198.3774, 144.3481, 76.4022, ...
                     159.9020, 85.4071, 51.0248, 83.3605, 147.2133, 148.8506, 144.3481, 101.7796, 158.6741, ...
                     118.1521, 44.8851, 97.2772, 142.3015, 135.7525];
        x_coords = round(x_coords);
        y_coords = round(y_coords);
     end
     
    % Initialize the heatmap
    % Determine the grid size
    x_min = round(min(x_coords));
    x_max = round(max(x_coords));
    y_min = round(min(y_coords));
    y_max = round(max(y_coords));
    grid_size_x = x_max - x_min + 200;
    grid_size_y = y_max - y_min + 200;

    % Precompute centers and grid

    transp_scale = 1;

    [Y, X] = ndgrid(1:grid_size_y, 1:grid_size_x);

    hold on;
    cmap = turbo(256); % Generate 256 colors

    % Heatmap setup
    heatmap = zeros(size(X));
    radius = 8; % Adjust circle size

        % Assuming your electrode positions (x_coords, y_coords) are provided:
        % Assuming x_coords, y_coords, var, X, and Y are defined
        % Calculate the outermost radius of the electrodes
        if ~isempty(var)
        INTERP_POINTS = 300;
        
        % Compute the mean center of the electrodes
        center_x = mean(x_coords);
        center_y = mean(y_coords);
        
        % Compute the outer radius as the max radial distance from the center
        outer_radius = max(sqrt((x_coords - center_x).^2 + (y_coords - center_y).^2));
        
        % Define the extended radius for smooth interpolation beyond the outer electrodes
        extended_radius = outer_radius + 100;  % Extend by 10 units
        
        % Generate additional points outside the outer radius for smooth interpolation
        theta = linspace(0, 2*pi, 50);  % 8 points around the circle
        [add_x, add_y] = pol2cart(theta, extended_radius);
        add_x = add_x + center_x;
        add_y = add_y + center_y;

        try
         % Compute values for additional points using nearest neighbor interpolation
          add_values = compute_nearest_values([add_x(:), add_y(:)], [x_coords(chans+1)', y_coords(chans+1)'], var(:), 4);  % 4 nearest neighbors
        catch
          errordlg('Please load correct map for mapping functionalities');
          return;
        
        end
        % Create a grid centered around the electrode region
        linear_grid_x = linspace(center_x - extended_radius, center_x + extended_radius, INTERP_POINTS);
        linear_grid_y = linspace(center_y - extended_radius, center_y + extended_radius, INTERP_POINTS);
        [interp_x, interp_y] = meshgrid(linear_grid_x, linear_grid_y);
        
        % Perform grid interpolation
        interp_z = griddata([x_coords(chans+1), add_x], [y_coords(chans+1), add_y], [var(:); add_values(:)], interp_x, interp_y, 'natural');
        
        % Create a circular mask based on the extended radius
        mask = sqrt((interp_x - center_x).^2 + (interp_y - center_y).^2) <= extended_radius;
        interp_z(~mask) = NaN;  % Mask points outside the extended circular region
        
        % Plot the final interpolation
       % h = pcolor(interp_x, interp_y, interp_z);
        hImg = imagesc(linear_grid_x, linear_grid_y, interp_z);
       % shading interp;  % Smooth shading
        cs=colorbar('southoutside');  % Add colorbar
        colormap(jet);  % Optional: Choose color map
      %  cs.Ticks = 50;

        alpha_data = ~isnan(interp_z).* rescale(interp_z, transp_scale, 1);
        set(hImg, 'AlphaData', alpha_data);
        set(hImg, 'Interpolation','bilinear');
        hold on;
        var(var>max_rate) = max_rate;
        fr_color = interp1(linspace(min_rate, max_rate, size(cmap, 1)), cmap, var); % Map normalized values to colormap
        for i = 1:length(chans)
            scatter(x_coords(chans(i)+1), y_coords(chans(i)+1), 25, fr_color(i,:), 'filled'); % Adjust size (100) and color ('w' for white)
        end
        end

    clim([min_rate max_rate])
    % Colorbar
    %cs = colorbar('south');
    cs.Label.String = Zlabel;
   % cs.Label.Rotation = 270;
   % cs.Label.VerticalAlignment = 'bottom';
    cs.AxisLocation = 'out';  % tick marks outside of colorbar
    set(cs, 'TickDirection', 'out');
    cs.Label.Rotation = 0;    % horizontal orientation
    cs.Label.VerticalAlignment = 'top';   % align vertically along colorbar
    cs.Label.HorizontalAlignment = 'center'; % align horizontally

    for t = 1:length(chans)
        chan_id = chans(t);

        x_center = x_coords(chan_id + 1);
        y_center = y_coords(chan_id + 1);
        
        text(x_center + 20, y_center, num2str(chan_id), ...
            'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    
    
    axis tight, axis off; box off;

end
