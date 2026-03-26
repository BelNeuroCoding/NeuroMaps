function setup_cluster_plots(h)
    h = guidata(h.figure);

    %  LOAD EXISTING CONFIG 
    if exist('clust_config.mat','file')
        loaded = load('clust_config.mat'); 
        cfg = loaded.cfg;
    else
        cfg = struct();
    end

    %  DEFAULTS 

    def.pre_time_plot = 0.8;
    def.post_time_plot = 0.8;
    for i = 1:4
        def.(['ylim_' num2str(i) '_mode']) = 'auto';
        def.(['ylim_' num2str(i)]) = [0 1];
        if i<3
        def.(['xlim_' num2str(i) '_mode']) = 'auto';
        def.(['xlim_' num2str(i)]) = [0 1];
        end
    end

    fn = fieldnames(def);
    for i = 1:numel(fn)
        if ~isfield(cfg,fn{i})
            cfg.(fn{i}) = def.(fn{i});
        end
    end

    %  UI FIGURE 
    d = dialog('Name','Cluster Plot Settings','Position',[300 200 450 350]);
    y = 300; dy = 30;

    %  PRE/POST TIME 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Plot Pre time (ms)','BackgroundColor',[1 1 1]);
    preEditPlot = uicontrol(d,'Style','edit','Position',[170 y 100 25], 'String',num2str(cfg.pre_time_plot));
    y = y - dy;

    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Plot Post time (ms)','BackgroundColor',[1 1 1]);
    postEditPlot = uicontrol(d,'Style','edit','Position',[170 y 100 25], 'String',num2str(cfg.post_time_plot));
    y = y - dy;


    %  YLIM & XLIM POPUPS 
    ylimMenus = cell(1,4); ylimMins = cell(1,4); ylimMaxs = cell(1,4);
    xlimMenus = cell(1,4); xlimMins = cell(1,4); xlimMaxs = cell(1,4);
    labelsY = {'Y PCA','Y Waveform','Y FWHM','Y Amplitude'};
    labelsX = {'X PCA','X Waveform'};

    for i = 1:4
        % Y-axis
        uicontrol(d,'Style','text','Position',[10 y 150 20],'String',labelsY{i},'BackgroundColor',[1 1 1]);
        ylimMenus{i} = uicontrol(d,'Style','popupmenu','String',{'auto','manual'},...
                                'Position',[170 y 100 25],...
                                'Value',find(strcmp({'auto','manual'},cfg.(['ylim_' num2str(i) '_mode']))));
        ylimMins{i} = uicontrol(d,'Style','edit','Position',[300 y 50 25],'String',num2str(cfg.(['ylim_' num2str(i)])(1)));
        ylimMaxs{i} = uicontrol(d,'Style','edit','Position',[350 y 50 25],'String',num2str(cfg.(['ylim_' num2str(i)])(2)));
        y = y - dy;
        if i<3
        % X-axis
        uicontrol(d,'Style','text','Position',[10 y 150 20],'String',labelsX{i},'BackgroundColor',[1 1 1]);
        xlimMenus{i} = uicontrol(d,'Style','popupmenu','String',{'auto','manual'},...
                                'Position',[170 y 100 25],...
                                'Value',find(strcmp({'auto','manual'},cfg.(['xlim_' num2str(i) '_mode']))));
        xlimMins{i} = uicontrol(d,'Style','edit','Position',[300 y 50 25],'String',num2str(cfg.(['xlim_' num2str(i)])(1)));
        xlimMaxs{i} = uicontrol(d,'Style','edit','Position',[350 y 50 25],'String',num2str(cfg.(['xlim_' num2str(i)])(2)));
        y = y - dy;
        end
    end

    %  SAVE BUTTON 
    uicontrol(d,'Style','pushbutton','String','Save','Position',[200 20 100 40], 'Callback',@saveCallback);

    %  CALLBACK 
    function saveCallback(~,~)
        cfg.pre_time = str2double(preEditPlot.String);
        cfg.post_time = str2double(postEditPlot.String);

        for i = 1:4
            % Y-axis
            optsY = {'auto','manual'};
            cfg.(['ylim_' num2str(i) '_mode']) = optsY{ylimMenus{i}.Value};
            cfg.(['ylim_' num2str(i)]) = [str2double(ylimMins{i}.String), str2double(ylimMaxs{i}.String)];

            % X-axis
            if i<3
            optsX = {'auto','manual'};
            cfg.(['xlim_' num2str(i) '_mode']) = optsX{xlimMenus{i}.Value};
            cfg.(['xlim_' num2str(i)]) = [str2double(xlimMins{i}.String), str2double(xlimMaxs{i}.String)];
            end
        end

        save('clust_config.mat','cfg');
        delete(d);

        % Auto-refresh cluster plots
        try
            plot_all_clusters(h);
        catch
            warning('Failed to refresh cluster plots.');
        end
    end
end