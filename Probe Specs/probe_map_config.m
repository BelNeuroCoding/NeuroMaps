function [x_coords, y_coords] = probe_map_config(image_file)
        % PROBE_MAP_CONFIG - Select electrode probe points on an image.
    %   If no image_file is provided, user is prompted to select one.
    %
    %   Usage:
    %       [x, y] = probe_map_config();               % Prompts for image
    %       [x, y] = probe_map_config('myimage.png');  % Loads given image

    % If no image_file provided, ask user to choose one
    if nargin < 1 || isempty(image_file)
        [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp','Image Files (*.png, *.jpg, *.jpeg, *.tif, *.bmp)'}, ...
                                 'Select an image for probe mapping');
        if isequal(file,0)
            disp('No file selected. Exiting.');
            x_coords = [];
            y_coords = [];
            return;
        end
        image_file = fullfile(path, file);
    end

    img = imread(image_file);
    figure
    hImg = imshow(img);
    title('Zoom/pan → Enter → Click electrode → Enter. Double Enter to finish.');
    hold on;

    % Initialize arrays to store plot and text objects for undo functionality
    x_coords = [];        % Store x-coordinates
    y_coords = [];        % Store y-coordinates
    points = [];          % Stores plot objects for points
    labels = [];          % Stores text objects for labels
    point_count = 0;      % Initialize counter for labeling points

    % Loop to capture points
    while true
        % Enable zoom functionality
        zoom on;
        pause
        % Wait for the user to click
        [x, y, button] = ginput(1);  % Get the position of the click
        
        % If Enter (ASCII 13) is pressed, finish collecting points
        if isempty(button) || button == 13
            break;
        elseif button == 8  % If Backspace (ASCII 8) is pressed, undo last point
            if ~isempty(points)
                delete(points(end));     % Remove last point plot
                delete(labels(end));     % Remove last label
                points(end) = [];        % Update points array
                labels(end) = [];        % Update labels array
                x_coords(end) = [];      % Update x-coordinates
                y_coords(end) = [];      % Update y-coordinates
                point_count = point_count - 1; % Decrement counter
            end
        else
            % Add the new point
            point_count = point_count + 1;
            x_coords(point_count) = x;
            y_coords(point_count) = y;

            % Plot the point and label it
            points(end+1) = plot(x, y, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
            labels(end+1) = text(x, y, num2str(point_count-1), 'Color', 'k', 'FontSize', 12, ...
                                 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
        end
        
    end

    hold off;
    % Show results in Command Window
    disp('Selected coordinates:');
    disp(table((0:point_count-1)', x_coords', y_coords', ...
        'VariableNames', {'Index', 'X', 'Y'}));
    T = table((0:point_count-1)', x_coords', y_coords', ...
    'VariableNames', {'Index', 'X', 'Y'});

    f = figure('Name','Selected Coordinates','NumberTitle','off');
    uitable('Parent',f, 'Data',T{:,:}, 'ColumnName',T.Properties.VariableNames, ...
            'Units','normalized','Position',[0 0 1 1]);


    % Save to MAT file
    [img_path, ~, ~] = fileparts(image_file);
    save(fullfile(img_path, 'sparse_x_y_coords.mat'), 'x_coords', 'y_coords');

end
