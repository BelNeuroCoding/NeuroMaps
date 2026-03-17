function plot_interpclust_heatmap(var, chans, Zlabel, x_coords, y_coords, mean_waveforms,img)


if nargin < 4 || isempty(x_coords)

x_coords = [115.4919,155.7933,216.2454,230.9005,269.9807,293.7951,350.5835,391.1902,...
294.7111,351.8048,250.4406,226.3208,179.6078,102.3634,66.6416,168.3111,...
171.3643,114.2706,214.4135,238.8386,284.3304,360.9642,296.5430,349.0569,...
396.3806,309.0608,249.8299,234.5642,194.8735,171.3643,122.2088,73.6639];

y_coords = [195.9215,242.5832,186.5073,227.0293,302.7521,247.9042,269.5978,...
208.6102,202.0612,270.0071,184.8701,259.7743,295.3845,263.0488,200.8333,...
198.3774,144.3481,76.4022,159.9020,85.4071,51.0248,83.3605,147.2133,...
148.8506,144.3481,101.7796,158.6741,118.1521,44.8851,97.2772,142.3015,135.7525];

x_coords = round(x_coords);
y_coords = round(y_coords);

end

% Heatmap limits

min_rate = floor(min(var));
max_rate = ceil(max(var));
x_centers = x_coords;
y_centers = y_coords;
padding = 100;
x_min = min(x_centers) - padding;
x_max = max(x_centers) + padding;
y_min = min(y_centers) - padding;
y_max = max(y_centers) + padding;
    % Precompute centers and grid
if nargin > 6 && ~isempty(img)
    imagefile = imread(img);
    %imshow(imagefile, 'XData', [x_min x_max], 'YData', [y_min y_max]);
    imshow(imagefile)
    hold on
    transp_scale = 0.6;
    [H,W,~] = size(imagefile);
    [Y,X] = ndgrid(1:H,1:W);
    % Create grid matching image
    %[Y,X] = ndgrid(1:size(imagefile,1),1:size(imagefile,2));
    heatmap = nan(size(X));
    
    if nargin < 9 || isempty(col)
        col = 'w'; % text color for overlay
    end
else
    % No image, create plain grid
    transp_scale = 1;
    [Y, X] = ndgrid(y_min:y_max, x_min:x_max);
    heatmap = nan(size(X));
    if nargin < 9 || isempty(col)
        col = 'k';
    end
end
hold on
cmap = turbo(256);


% Interpolation

if ~isempty(var)

INTERP_POINTS = 300;

center_x = mean(x_coords);
center_y = mean(y_coords);

outer_radius = max(sqrt((x_coords-center_x).^2 + (y_coords-center_y).^2));
extended_radius = outer_radius + 100;

theta = linspace(0,2*pi,50);
[add_x,add_y] = pol2cart(theta,extended_radius);

add_x = add_x + center_x;
add_y = add_y + center_y;

try
add_values = compute_nearest_values([add_x(:),add_y(:)],...
[x_coords(chans+1)',y_coords(chans+1)'],var(:),4);
catch
errordlg('Please load correct map for mapping functionalities');
return
end

linear_grid_x = linspace(center_x-extended_radius,center_x+extended_radius,INTERP_POINTS);
linear_grid_y = linspace(center_y-extended_radius,center_y+extended_radius,INTERP_POINTS);

[interp_x,interp_y] = meshgrid(linear_grid_x,linear_grid_y);

interp_z = griddata([x_coords(chans+1),add_x],...
[y_coords(chans+1),add_y],...
[var(:);add_values(:)],...
interp_x,interp_y,'natural');

mask = sqrt((interp_x-center_x).^2 + (interp_y-center_y).^2) <= extended_radius;
interp_z(~mask) = NaN;

hImg = imagesc(linear_grid_x,linear_grid_y,interp_z);
set(gca,'YDir','reverse')

cs = colorbar('southoutside');
colormap(jet)

alpha_data = ~isnan(interp_z).*rescale(interp_z,transp_scale,1);
set(hImg,'AlphaData',alpha_data)
set(hImg,'Interpolation','bilinear')

% electrode dots
var(var>max_rate)=max_rate;
fr_color = interp1(linspace(min_rate,max_rate,size(cmap,1)),cmap,var);

for i=1:length(chans)
scatter(x_coords(chans(i)+1),y_coords(chans(i)+1),25,fr_color(i,:),'filled');
end

end

clim([min_rate max_rate])

cs.Label.String = Zlabel;
cs.AxisLocation='out';
set(cs,'TickDirection','out');

cs.Label.Rotation=0;
cs.Label.VerticalAlignment='top';
cs.Label.HorizontalAlignment='center';


% WAVEFORM OVERLAY
if nargin >= 6 && ~isempty(mean_waveforms)

    wf_scale_x = 18;   % waveform width
    wf_scale_y = 20;   % waveform height

    nClusters = size(mean_waveforms,2);

    cluster_colors = lines(nClusters);

    cluster_spacing = 25;  % spacing between clusters
    vertical_offset = 30;  
    
    for i = 1:length(chans)

        ch = chans(i);

        x_center = x_coords(ch+1);
        y_center = y_coords(ch+1);

        % center the cluster layout around electrode
        x_start = x_center - ((nClusters-1)/2)*cluster_spacing;
     

        for k = 1:nClusters

            wf = squeeze(mean_waveforms(i,k,:));

            if all(isnan(wf))
                continue
            end

            % normalize waveform
            wf = wf - mean(wf);
            wf = wf ./ max(abs(wf));

            time_axis = linspace(0,1,length(wf));

            % cluster offset
            x0 = x_start + (k-1)*cluster_spacing;
            y0 = y_center - vertical_offset;

            xwf = x0 + time_axis*wf_scale_x;
            ywf = y0 + wf*wf_scale_y;

            plot(xwf,ywf,'Color',cluster_colors(k,:),'LineWidth',1)

        end
    end
end



% Channel labels

for t=1:length(chans)

chan_id = chans(t);

x_center = x_coords(chan_id+1);
y_center = y_coords(chan_id+1);

text(x_center+20,y_center,num2str(chan_id),...
'Color','w','FontSize',10,'FontWeight','bold',...
'HorizontalAlignment','center');

end

axis equal
axis off
box off

end