function plot_setting_callback(src,mode)

    h = guidata(src.figure);
    defaults.label_color = 'w';
    defaults.topo_map_transparency = 0.6;
    defaults.font_size = 5;
    defaults.colormap = 'turbo';
    defaults.use_clim = false;
    defaults.clim = [0 1];
    %  UI 
    f = uifigure('Name','Plot Settings', ...
                 'Position',[100 100 340 320]);

    % Colormap
    uilabel(f,'Position',[20 260 120 20],'Text','Colormap');
    dd_cmap = uidropdown(f, ...
        'Items',{'turbo','parula','jet','hot','cool','gray'}, ...
        'Value',defaults.colormap, ...
        'Position',[150 260 150 22]);

    % Label Color
    uilabel(f,'Position',[20 220 120 20],'Text','Label Color');
    dd_color = uidropdown(f, ...
        'Items',{'w','k','r','g','b','y','c','m'}, ...
        'Value',defaults.label_color, ...
        'Position',[150 220 150 22]);

    % Transparency
    uilabel(f,'Position',[20 180 120 20],'Text','Transparency');
    ef_alpha = uieditfield(f,'numeric', ...
        'Limits',[0 1], ...
        'Value',defaults.topo_map_transparency, ...
        'Position',[150 180 150 22]);

    % Font size
    uilabel(f,'Position',[20 140 120 20],'Text','Font Size');
    ef_font = uieditfield(f,'numeric', ...
        'Limits',[1 30], ...
        'Value',defaults.font_size, ...
        'Position',[150 140 150 22]);

    %  CLIM toggle 
    cb_clim = uicheckbox(f, ...
        'Text','Use manual color limits', ...
        'Value',defaults.use_clim, ...
        'Position',[20 100 200 20]);

    % CLIM min
    uilabel(f,'Position',[20 70 60 20],'Text','Min');
    ef_min = uieditfield(f,'numeric', ...
        'Value',defaults.clim(1), ...
        'Position',[80 70 80 22]);

    % CLIM max
    uilabel(f,'Position',[170 70 60 20],'Text','Max');
    ef_max = uieditfield(f,'numeric', ...
        'Value',defaults.clim(2), ...
        'Position',[220 70 80 22]);

    % Apply
    uibutton(f,'Text','Apply', ...
        'Position',[120 20 100 30], ...
        'ButtonPushedFcn', @(btn,event) applySettings());

    % ---- Callback ----
    function applySettings()

        hm_props = struct;

        hm_props.colormap = dd_cmap.Value;
        hm_props.label_color = dd_color.Value;
        hm_props.topo_map_transparency = ef_alpha.Value;
        hm_props.font_size = ef_font.Value;

        % CLIM logic
        hm_props.use_clim = cb_clim.Value;

        if hm_props.use_clim
            cmin = ef_min.Value;
            cmax = ef_max.Value;

            if cmin >= cmax
                uialert(f,'Min must be < Max','Invalid limits');
                return;
            end

            hm_props.clim = [cmin cmax];
        else
            hm_props.clim = [];
        end

        % Store
        h.hm_props = hm_props;
        guidata(src.figure, h);

        % Apply
        if mode == 1
            plot_fr_callback(h, hm_props);
        else
            plot_amphm_callback(h,hm_props);
        end

        close(f)
    end
end