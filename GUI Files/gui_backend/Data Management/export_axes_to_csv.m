function export_axes_to_csv(ax, filename)
% EXPORT_AXES_TO_CSV Export NeuroMaps axes data to CSV.
%
% For grouped plots, exports in long format:
%   Object, x, Group, y
%
% For image/surface plots:
%   Object, x, y, value
%
% This avoids losing groups such as PRE / TTX / POST when each group has
% different x-coordinates.

if nargin < 1 || isempty(ax)
    ax = gca;
end

if nargin < 2 || isempty(filename)
    filename = 'neuromaps_export';
end

[~, filename, ~] = fileparts(filename);

children = flipud(get(ax, 'Children'));

rows_1d = table();
rows_2d = table();

usedNames = {};

% Get axis tick labels, e.g. PRE / TTX / POST
xt = get(ax, 'XTick');
xtlbl = get(ax, 'XTickLabel');

if ischar(xtlbl)
    xtlbl = cellstr(xtlbl);
end

for k = 1:numel(children)

    obj = children(k);
    typ = lower(get(obj, 'Type'));

    % Get object name
    if isprop(obj, 'DisplayName')
        tag = get(obj, 'DisplayName');
    else
        tag = '';
    end

    if isempty(tag) || all(isspace(tag))
        if isprop(obj, 'Tag')
            tag = get(obj, 'Tag');
        end
    end

    if isempty(tag) || all(isspace(tag))
        tag = sprintf('%s_%d', typ, k);
    end

    tag = matlab.lang.makeValidName(tag);
    tag = make_unique_name(tag, usedNames);
    usedNames{end+1} = tag; %#ok<AGROW>

    switch typ

        case {'scatter', 'bar'}

            x = get(obj, 'XData');
            y = get(obj, 'YData');

            [x, y] = clean_xy(x, y);

            if isempty(x)
                continue;
            end

            group = map_x_to_group_labels(x, xt, xtlbl);

            thisT = table( ...
                repmat(string(tag), numel(x), 1), ...
                x(:), ...
                group(:), ...
                y(:), ...
                'VariableNames', {'Object','x','Group','y'});

            rows_1d = [rows_1d; thisT]; %#ok<AGROW>

        case 'histogram'

            edges  = get(obj, 'BinEdges');
            counts = get(obj, 'Values');

            x = edges(1:end-1) + diff(edges)./2;
            y = counts;

            [x, y] = clean_xy(x, y);

            if isempty(x)
                continue;
            end

            group = map_x_to_group_labels(x, xt, xtlbl);

            thisT = table( ...
                repmat(string(tag), numel(x), 1), ...
                x(:), ...
                group(:), ...
                y(:), ...
                'VariableNames', {'Object','x','Group','y'});

            rows_1d = [rows_1d; thisT]; %#ok<AGROW>

        case {'image', 'surface'}

            cdata = get(obj, 'CData');

            if isempty(cdata)
                continue;
            end

            xd = get(obj, 'XData');
            yd = get(obj, 'YData');

            [ny, nx] = size(cdata);

            xvec = infer_axis_vector(xd, nx);
            yvec = infer_axis_vector(yd, ny);

            [X, Y] = meshgrid(xvec, yvec);

            X = X(:);
            Y = Y(:);
            V = cdata(:);

            valid = ~(isnan(X) | isnan(Y) | isnan(V));

            X = X(valid);
            Y = Y(valid);
            V = V(valid);

            if isempty(V)
                continue;
            end

            thisT = table( ...
                repmat(string(tag), numel(V), 1), ...
                X(:), ...
                Y(:), ...
                V(:), ...
                'VariableNames', {'Object','x','y','value'});

            rows_2d = [rows_2d; thisT]; %#ok<AGROW>

        otherwise
            continue;
    end
end

% Choose what to export
if ~isempty(rows_1d) && ~isempty(rows_2d)

    choice = questdlg( ...
        'This axes contains both 1D and 2D data. What do you want to export?', ...
        'Mixed data export', ...
        '1D data','2D data','Cancel','1D data');

    if isempty(choice) || strcmp(choice,'Cancel')
        return;
    elseif strcmp(choice,'1D data')
        T = rows_1d;
    else
        T = rows_2d;
    end

elseif ~isempty(rows_1d)

    T = rows_1d;

elseif ~isempty(rows_2d)

    T = rows_2d;

else

    warning('No compatible exportable objects found for export.');
    return;
end

[f, p] = uiputfile('*.csv', 'Save plot data', [filename '.csv']);

if ~isequal(f, 0)
    writetable(T, fullfile(p, f));
    msgbox(sprintf('Data saved:\n%s', f), 'Saved', 'help');
end

end


function [x, y] = clean_xy(x, y)
% CLEAN_XY Convert x/y to column vectors and remove NaNs.

x = x(:);
y = y(:);

n = min(numel(x), numel(y));

x = x(1:n);
y = y(1:n);

valid = ~(isnan(x) | isnan(y));

x = x(valid);
y = y(valid);

end


function group = map_x_to_group_labels(x, xt, xtlbl)
% MAP_X_TO_GROUP_LABELS Convert numeric x positions into axis tick labels.

group = strings(numel(x),1);

if isempty(xt) || isempty(xtlbl)
    return;
end

if ischar(xtlbl)
    xtlbl = cellstr(xtlbl);
end

for ii = 1:numel(x)

    % Use nearest tick rather than exact ismember, because scatter jitter or
    % floating point x-values can prevent exact matching.
    [dist, loc] = min(abs(xt(:) - x(ii)));

    if ~isempty(loc) && loc <= numel(xtlbl) && dist < 0.25
        group(ii) = string(xtlbl{loc});
    else
        group(ii) = "";
    end
end

end


function v = infer_axis_vector(data, n)
% INFER_AXIS_VECTOR Infer full axis vector from image/surface axis data.

if isempty(data)

    v = 1:n;

elseif numel(data) == n

    v = data(:).';

elseif numel(data) == 2

    v = linspace(data(1), data(2), n);

else

    v = 1:n;

end

end


function name = make_unique_name(name, usedNames)
% MAKE_UNIQUE_NAME Ensure table variable names are unique.

base = name;
idx = 2;

while any(strcmp(name, usedNames))
    name = sprintf('%s_%d', base, idx);
    idx = idx + 1;
end

end
