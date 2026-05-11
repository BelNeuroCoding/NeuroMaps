function export_axes_to_csv(ax, filename)
% EXPORT_AXES_TO_CSV  Export NeuroMaps axes data to one CSV without NaNs.
%
% Exports compatible line/scatter/bar/histogram objects as:
%   x, object1, object2, object3
%
% Exports compatible image/surface objects as:
%   x, y, object1, object2, object3
%
% Notes:
%   - NaNs are omitted before export.
%   - Objects are only combined if their coordinates match.
%   - Mixed 1D and 2D data are not combined.
%   - Histogram x-values are exported as bin centres.

if nargin < 1 || isempty(ax)
    ax = gca;
end

if nargin < 2 || isempty(filename)
    filename = 'neuromaps_export';
end

[~, filename, ~] = fileparts(filename);

children = flipud(get(ax, 'Children'));

usedNames = {};

commonCoords = [];
coordNames = {};
dataCols = {};
headers = {};

for k = 1:numel(children)

    obj = children(k);
    typ = lower(get(obj, 'Type'));

    % Some objects, e.g. Image, do not have DisplayName.
    if isprop(obj, 'DisplayName')
        tag = get(obj, 'DisplayName');
    else
        tag = '';
    end

    % Fallback to Tag if available.
    if isempty(tag) || all(isspace(tag))
        if isprop(obj, 'Tag')
            tag = get(obj, 'Tag');
        end
    end

    % Final fallback.
    if isempty(tag) || all(isspace(tag))
        tag = sprintf('%s_%d', typ, k);
    end

    tag = matlab.lang.makeValidName(tag);
    tag = make_unique_name(tag, usedNames);
    usedNames{end+1} = tag; %#ok<AGROW>

    switch typ

        case {'line', 'scatter', 'bar'}

            x = get(obj, 'XData');
            y = get(obj, 'YData');

            [x, y] = clean_xy(x, y);

            if isempty(x)
                continue;
            end

            coords = x;
            thisCoordNames = {'x'};

            if isempty(commonCoords)
                commonCoords = coords;
                coordNames = thisCoordNames;
            end

            if coords_match(commonCoords, coords)
                headers{end+1} = tag; %#ok<AGROW>
                dataCols{end+1} = y;  %#ok<AGROW>
            else
                warning('Skipping %s because its coordinates do not match the first exported object.', tag);
            end

        case 'histogram'

            edges  = get(obj, 'BinEdges');
            counts = get(obj, 'Values');

            % Use bin centres as x-values.
            x = edges(1:end-1) + diff(edges)./2;
            y = counts;

            [x, y] = clean_xy(x, y);

            if isempty(x)
                continue;
            end

            coords = x;
            thisCoordNames = {'x'};

            if isempty(commonCoords)
                commonCoords = coords;
                coordNames = thisCoordNames;
            end

            if coords_match(commonCoords, coords)
                headers{end+1} = tag; %#ok<AGROW>
                dataCols{end+1} = y;  %#ok<AGROW>
            else
                warning('Skipping %s because its coordinates do not match the first exported object.', tag);
            end

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

            coords = [X, Y];
            thisCoordNames = {'x', 'y'};

            if isempty(commonCoords)
                commonCoords = coords;
                coordNames = thisCoordNames;
            end

            if coords_match(commonCoords, coords)
                headers{end+1} = tag; %#ok<AGROW>
                dataCols{end+1} = V;  %#ok<AGROW>
            else
                warning('Skipping %s because its coordinates do not match the first exported object.', tag);
            end

        otherwise

            % Ignore annotations, legends, colorbars, etc.
            continue;
    end
end

if ~isempty(dataCols)

    T = array2table(commonCoords, 'VariableNames', coordNames);

    for j = 1:numel(dataCols)
        T.(headers{j}) = dataCols{j};
    end

    [f, p] = uiputfile('*.csv', 'Save plot data', [filename '.csv']);

    if ~isequal(f, 0)
        writetable(T, fullfile(p, f));
        msgbox(sprintf('Data saved:\n%s', f), 'Saved', 'help');
    end

else
    warning('No compatible exportable objects found for export.');
end

end


function [x, y] = clean_xy(x, y)
%CLEAN_XY  Convert x/y to column vectors and remove NaNs.

x = x(:);
y = y(:);

n = min(numel(x), numel(y));

x = x(1:n);
y = y(1:n);

valid = ~(isnan(x) | isnan(y));

x = x(valid);
y = y(valid);

end


function tf = coords_match(a, b)
%COORDS_MATCH  True if coordinate arrays have same size and values.

tf = size(a, 1) == size(b, 1) && ...
     size(a, 2) == size(b, 2) && ...
     isequaln(a, b);

end


function v = infer_axis_vector(data, n)
%INFER_AXIS_VECTOR  Infer full axis vector from image/surface axis data.

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
%MAKE_UNIQUE_NAME  Ensure table variable names are unique.

base = name;
idx = 2;

while any(strcmp(name, usedNames))
    name = sprintf('%s_%d', base, idx);
    idx = idx + 1;
end

end