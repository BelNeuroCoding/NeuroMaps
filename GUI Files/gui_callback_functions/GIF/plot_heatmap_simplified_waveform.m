function plot_heatmap_simplified_waveform(var, chans, Zlabel, tit, waveforms, time, img,x_coords,y_coords)
    % Inputs:
    % - var: Spike rate or other variable to plot in heatmap.
    % - chans: The channel numbers corresponding to the data.
    % - Zlabel: Label for the colorbar (e.g., 'Spike Rate (Hz)').
    % - tit: Title of the heatmap plot.
    % - waveforms: Cell array of spike waveforms for each channel.
    % - time: Time axis for plotting the waveforms.

    % Define Grid
    if nargin <7

    x_coords = [115.4919, 155.7933, 216.2454, 230.9005, 269.9807, 293.7951, 350.5835, 391.1902, 294.7111, 351.8048, ...
                 250.4406, 226.3208, 179.6078, 102.3634, 66.6416, 168.3111, 171.3643, 114.2706, 214.4135, ...
                 238.8386, 284.3304, 360.9642, 296.5430, 349.0569, 396.3806, 309.0608, 249.8299, 234.5642, ...
                 194.8735, 171.3643, 122.2088, 73.6639];
    y_coords = [195.9215, 242.5832, 186.5073, 227.0293, 302.7521, 247.9042, 269.5978, 208.6102, 202.0612, ...
                 270.0071, 184.8701, 259.7743, 295.3845, 263.0488, 200.8333, 198.3774, 144.3481, 76.4022, ...
                 159.9020, 85.4071, 51.0248, 83.3605, 147.2133, 148.8506, 144.3481, 101.7796, 158.6741, ...
                 118.1521, 44.8851, 97.2772, 142.3015, 135.7525];
    end
    % Compute electrode grid dimensions
    x_min = round(min(x_coords)); 
    x_max = round(max(x_coords)); 
    y_min = round(min(y_coords)); 
    y_max = round(max(y_coords));
    grid_size_x = x_max - x_min + 200;
    grid_size_y = y_max - y_min + 200;
    
    [Y, X] = ndgrid(1:grid_size_y, 1:grid_size_x);
    X_shifted = X + x_min;
    Y_shifted = Y + y_min;
    
    % Precompute centers
    x_centers = x_coords;
    y_centers = y_coords;
    
    if nargin > 6
        % Load background image
        rgb = imread(img);
        % Show image with correct scaling
        imshow(rgb);
        [imgHeight, imgWidth, ~] = size(rgb);
        hold on;
    end
    
    % Initialise heatmap
    heatmap = nan(grid_size_y, grid_size_x);

    % Plot channel numbers and waveforms
    for t = 1:length(chans)
        text(x_centers(chans(t) + 1)+10, y_centers(chans(t) + 1)+10, num2str(chans(t)), ...
            'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        % Plot the mean spike waveform as a small snippet
        if size(waveforms, 1) > 0
            % Normalize and scale the waveform
            wf = waveforms(t,:) ./ max(abs(waveforms(t,:))); % normalize
            scale = 10; % vertical scaling of waveform
            wfX = (time - mean(time))*10000 + x_coords(chans(t)+1); % spread waveform around channel x
            wfY = wf*scale + y_coords(chans(t)+1)-20;                % scale + shift vertically
            plot(wfX, wfY, 'w','LineWidth',1);
        end
    end
    hold on;
    % Create empty heatmap matrix
    heatmap = zeros(size(X));
    radius = 3; % Adjust for desired circle size

    for t = 1:length(chans)
        % Define x and y centers for the current channel
        x_center = x_centers(chans(t) + 1);
        y_center = y_centers(chans(t) + 1);
        
        % Compute distance from the center
        dist_squared = (X - x_center).^2 + (Y - y_center).^2;
        
        % Create a binary mask for the circle
        circle_mask = dist_squared <= radius^2;
        
        % Scale circle mask by spike rate (var(t))
        circle_intensity = var(t) * double(circle_mask);
        
        % Add this circle mask to the overall heatmap
        heatmap = heatmap + circle_intensity;
    end

    % Plot the heatmap using imagesc with interpolation
    % Heatmap aligned with image

    [Y, X] = ndgrid(1:imgHeight, 1:imgWidth);
    heatmap = zeros(imgHeight, imgWidth);
    
    radius = 10; % in pixels
    for t = 1:length(chans)
        dist2 = (X - x_coords(chans(t)+1)).^2 + (Y - y_coords(chans(t)+1)).^2;
        circle_mask = dist2 <= radius^2;
        heatmap = heatmap + var(t)*double(circle_mask);
    end
    
    hImg = imagesc(heatmap);
    set(hImg,'AlphaData',heatmap>0); 
    colormap(turbo);
    colorbar;

    set(hImg, 'Interpolation', 'bilinear');  % Smooth the transitions in imagesc

    % Set up colorbar
    cs = colorbar;
    cs.Label.String = Zlabel;
    cs.Label.Rotation = 270;
    cs.Label.VerticalAlignment = 'bottom';

    % Adjust axis properties
    xlim([min(X, [], 'all') max(X, [], 'all')]);
    pbaspect([(max(X,[],'all')-min(X,[],'all'))/(max(Y,[],'all')-min(Y,[],'all')) 1 1])
    axis off;
    box off;
    
    title(tit);
end
