function [x_coords, y_coords] = probe_map_config(image_file)
        % PROBE_MAP_CONFIG - Select electrode probe points on an image.
    %   If no image_file is provided, user is prompted to select one.
    %
    %   Usage:
    %       [x, y] = probe_map_config();               % Prompts for image
    %       [x, y] = probe_map_config('myimage.png');  % Loads given image

    % If no image_file provided, ask user to choose one
    clc;
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
    hFig = figure('Name','Probe Mapping','NumberTitle','off');
    
    % Create axes explicitly
    hAx = axes('Parent', hFig);
    img = imread(image_file);
    hImg = imshow(img, 'Parent', hAx);
    axis(hAx,'on');           % Show axes
    axis(hAx,'image');        % Keep aspect ratio correct
    grid(hAx,'on');           % Show grid
    grid(hAx,'minor');
    hold(hAx,'on');
    title(hAx,'Zoom/pan → Enter → Select point → Enter → Double Enter to finish.');
    hold(hAx,'on');

     %% CALIBRATION STEP
    n_cal = 3;
    um_per_pixel_all = zeros(1,n_cal);
    
    msgbox('The first step is calibration. You will select two points three times to calibrate pixel to micron ratio.');
    k = 1;
    cal_handles = gobjects(0);
    while k <= n_cal
    
        redo_points = true;
    
        while redo_points
    
            redo_points = false;
    
            %  collect points 
            x_cal = zeros(1,2);
            y_cal = zeros(1,2);
            cal_points = gobjects(0);
    
            title(hAx,sprintf('Calibration line %d/%d',k,n_cal));
            xlabel(hAx,'Zoom/pan → Enter → Select point → Enter → Point 2 → Backspace to Undo');    

            drawnow expose    
    
            p = 1;
            while p <= 2
                zoom on
                pause
    
                [x,y,button] = ginput(1);
    
                if isempty(button) || button == 13
                    return
                elseif button == 8
                    if p > 1
                        delete(cal_points(end))
                        cal_points(end) = [];
                        p = p - 1;
                    end
                    continue
                end
    
                x_cal(p) = x;
                y_cal(p) = y;
                h1 = plot(hAx,x,y,'ro','MarkerSize',10,'LineWidth',2);
                cal_points(end+1) = h1;
                cal_handles(end+1) = h1;    
                p = p + 1;
            end
            h2 = line(hAx,x_cal,y_cal,'Color','g','LineWidth',2);
            cal_points(end+1) = h2;
            cal_handles(end+1) = h2;
    
            % --- distance input loop ---
            while true
    
                answer = inputdlg({'Enter distance (μm):'},'Calibration',[1 35],{'100'});
    
                if isempty(answer)
                    choice = questdlg('Cancel this calibration line?', ...
                                     'Calibration', ...
                                     'Redo points','Abort','Redo points');
    
                    if strcmp(choice,'Abort')
                        return
                    else
                        redo_points = true;
                        break
                    end
                end
    
                known_distance_um = str2double(answer{1});
    
                if isnan(known_distance_um) || known_distance_um <= 0
                    uiwait(warndlg('Enter a valid number'));
                    continue
                end
    
                choice = questdlg(['Use ',num2str(known_distance_um),' μm?'], ...
                                  'Confirm', ...
                                  'OK','Redo points','OK');
    
                if strcmp(choice,'Redo points')
                    redo_points = true;
                    break
                else
                    pixel_distance = hypot(diff(x_cal), diff(y_cal));
                    um_per_pixel_all(k) = known_distance_um / pixel_distance;
                    break
                end
            end
    
            if redo_points
                delete(cal_points)
                cal_handles = setdiff(cal_handles, cal_points);
            end
    
        end
    
        k = k + 1;
    
    end
    
    um_per_pixel = mean(um_per_pixel_all);
    
    msgbox(['Average calibration factor: 1 pixel = ', num2str(um_per_pixel), ' μm']);
    delete(cal_handles(ishandle(cal_handles)))

    zoom off
    title(hAx,'Select Electrodes from 0 to N.');
    xlabel(hAx,'Zoom/pan → press Enter → click point 1 → Enter → Double Enter when all electrodes are complete');    
    drawnow expose    
    pause(0.05)
    hold on

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
            choice = questdlg('Have you finished selecting all electrodes?', ...
                      'Confirm Finish', ...
                      'Yes','No','No');
            if strcmp(choice,'Yes')
                break;
            else
                continue; % Go back to point selection
            end
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
            maps(point_count) = point_count-1;
            % Plot the point and label it
            points(end+1) = plot(hAx,x, y, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
            labels(end+1) = text(hAx,x, y, num2str(point_count-1), 'Color', 'k', 'FontSize', 12, ...
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


    % Prompt user to select output path and filename
    [filename, pathname] = uiputfile('*.mat', 'Save coordinates as');
    if isequal(filename,0) || isequal(pathname,0)
        msgbox('Save operation canceled by user.', 'Info', 'warn');
    else
        save(fullfile(pathname, filename), 'x_coords', 'y_coords','maps','um_per_pixel');
        msgbox(['Coordinates saved to: ', fullfile(pathname, filename)], 'Success', 'help');
    end

end
