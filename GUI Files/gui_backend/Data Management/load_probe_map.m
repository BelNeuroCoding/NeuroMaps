function [x_coords, y_coords, maps,um_per_px] = load_probe_map(h)
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
    S = load(matFile);
    x_coords = S.x_coords;
    y_coords = S.y_coords;
    maps = S.maps;
    if isfield(S,'um_per_pixel')
        um_per_px = S.um_per_pixel;
    else
        um_per_px= 7.5; %default for Neuroweb spar_x_y_coords
    end

end
