function plot_heatmap_callback(var, chans, Zlabel, x_coords, y_coords, img, hm_props, clims)

% 1. Default coordinates 
if nargin < 4
    x_coords = round([452 574 422 557 617 554 445 437 444 525 425 496 634 540 455 466 357 354 240 179 241 373 220 343 327 340 264 163 299 377 272 350]);
    y_coords = round([428 500 367 333 269 170 255 188 120 239 323 340 395 427 495 559 509 434 526 424 359 322 190 262 137 197 268 303 356 371 454 574]);
end

x_centers = x_coords;
y_centers = y_coords;
 
% 2. Define grid extents
 
padding = 100;
x_min = min(x_centers) - padding;
x_max = max(x_centers) + padding;
y_min = min(y_centers) - padding;
y_max = max(y_centers) + padding;

% 3. Load image if provided
if nargin > 5 && ~isempty(img)
    imagefile = imread(img);
    %imshow(imagefile, 'XData', [x_min x_max], 'YData', [y_min y_max]);
    imshow(imagefile)
    hold on
    [H,W,~] = size(imagefile);
    [Y,X] = ndgrid(1:H,1:W);
    col = 'w';
    % Create grid matching image
    %[Y,X] = ndgrid(1:size(imagefile,1),1:size(imagefile,2));
    heatmap = nan(size(X));
else
    % No image, create plain grid
    col = 'k';
    [Y, X] = ndgrid(y_min:y_max, x_min:x_max);
    heatmap = nan(size(X));
end

if nargin>6 && ~isempty(hm_props)
    col = hm_props.label_color;
    fsize = hm_props.font_size;
    cm = hm_props.colormap;
    alpha_value =  hm_props.topo_map_transparency;
else
    cm = 'turbo';
    alpha_value = 0.9;
    fsize = 5;
end

% 4. Build heatmap
radius = 10; % radius in pixels/units
radius_squared = radius^2;

for t = 1:length(chans)
    xc = x_centers(chans(t)+1);
    yc = y_centers(chans(t)+1);
    mask = (X - xc).^2 + (Y - yc).^2 <= radius_squared;
    heatmap(mask) = var(t);
end

 
% 5. Plot heatmap
if exist('W','var')
    hImg = imagesc([1 W], [1 H], heatmap);
else
    hImg = imagesc([x_min x_max], [y_min y_max], heatmap);
    axis square
end
colormap(cm);
hold on;

% Set transparency
alpha_data = ~isnan(heatmap);
set(hImg, 'AlphaData', alpha_data * alpha_value);


% 6. Colorbar
cs = colorbar('southoutside');
if nargin < 8 || isempty(clims)
    clims = [min(heatmap(:)), max(heatmap(:))];
end
cs.Limits = clims;
cs.Label.String = Zlabel;
cs.Label.Rotation = 0;
cs.Label.VerticalAlignment = 'top';
cs.Label.HorizontalAlignment = 'center';
cs.AxisLocation = 'out';
set(cs, 'TickDirection', 'out');

% 7. Electrode labels
for t = 1:length(chans)
    text(x_centers(chans(t)+1)+10, y_centers(chans(t)+1)+20, num2str(chans(t)), ...
        'Color', col, 'FontSize', fsize, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
end

% 8. Axis adjustments
axis off;
set(gca,'Color','none');

end