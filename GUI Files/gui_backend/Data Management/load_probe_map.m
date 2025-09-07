function [x_coords, y_coords, maps] = load_probe_map(h)
    if isfield(h,'probe_map')
        probe_maps = get(h.probe_map, 'Data');
    else 
        probe_maps = [];
    end
    if ~isempty(probe_maps)
        matFile = probe_maps{2};   % second row
    else
        matFile = 'sparse_x_y_coords.mat';
    end
    S = load(matFile, 'x_coords', 'y_coords', 'maps');
    x_coords = S.x_coords;
    y_coords = S.y_coords;
    maps = S.maps;
end
