function spike_snippet_settings(h)

    h = guidata(h.figure);

    %  LOAD EXISTING CONFIG 
    if exist('spike_config.mat','file')
        S = load('spike_config.mat');
        cfg = S.config;
    else
        cfg = struct();
    end

    %  DEFAULTS (if fields missing) 
    def.pre_time = 0.8;
    def.post_time = 0.8;
    def.pre_time_plot = 0.8;
    def.post_time_plot = 0.8;
    def.align_mode = 'min';
    def.central_tendency = 'mean';
    def.spread = 'std';
    def.line_width = 2;
    def.shade_alpha = 0.3;
    def.ylim_mode = 'auto';
    def.split_polarity = 0;

    fn = fieldnames(def);
    for i = 1:numel(fn)
        if ~isfield(cfg,fn{i})
            cfg.(fn{i}) = def.(fn{i});
        end
    end

    %  UI FIGURE 
    d = dialog('Name','Spike Plot Settings',...
               'Position',[300 300 320 400]);

    y = 360; dy = 30;

    %  PRE / POST TIME 
        uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Plot Pre time (ms)','BackgroundColor',[1 1 1]);
    preEditPlot = uicontrol(d,'Style','edit','Position',[170 y 100 25],...
        'String',num2str(cfg.pre_time_plot));
    y = y - dy;

    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Plot Post time (ms)','BackgroundColor',[1 1 1]);
    postEditPlot = uicontrol(d,'Style','edit','Position',[170 y 100 25],...
        'String',num2str(cfg.post_time_plot));
    y = y - dy;
    
        uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Detection Pre time (ms)','BackgroundColor',[1 1 1]);
    preEdit = uicontrol(d,'Style','edit','Position',[170 y 100 25],...
        'String',num2str(cfg.pre_time));
    y = y - dy;

    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Detection Post time (ms)','BackgroundColor',[1 1 1]);
    postEdit = uicontrol(d,'Style','edit','Position',[170 y 100 25],...
        'String',num2str(cfg.post_time));
    y = y - dy;

    %  SPLIT POS/NEG SPIKES
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Split pos/neg spikes','BackgroundColor',[1 1 1]);
    splitPolarityCheck = uicontrol(d,'Style','checkbox','Position',[170 y 25 25],...
        'Value', isfield(cfg,'split_polarity') && cfg.split_polarity,'BackgroundColor',[1 1 1]);
    y = y - dy;
    
    %  ALIGNMENT 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Alignment','BackgroundColor',[1 1 1]);
    alignMenu = uicontrol(d,'Style','popupmenu',...
        'String',{'min','max','none'},...
        'Position',[170 y 100 25],...
        'Value',find(strcmp({'min','max','none'},cfg.align_mode)));
    y = y - dy;

    %  CENTRAL TENDENCY 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Waveform Average','BackgroundColor',[1 1 1]);
    centralMenu = uicontrol(d,'Style','popupmenu',...
        'String',{'mean','median'},...
        'Position',[170 y 100 25],...
        'Value',find(strcmp({'mean','median'},cfg.central_tendency)));
    y = y - dy;

    %  SPREAD 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Spread','BackgroundColor',[1 1 1]);
    spreadMenu = uicontrol(d,'Style','popupmenu',...
        'String',{'std','sem','none'},...
        'Position',[170 y 100 25],...
        'Value',find(strcmp({'std','sem','none'},cfg.spread)));
    y = y - dy;


    %  LINE WIDTH 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Line width','BackgroundColor',[1 1 1]);
    lwEdit = uicontrol(d,'Style','edit','Position',[170 y 100 25],...
        'String',num2str(cfg.line_width));
    y = y - dy;

    %  SHADE ALPHA 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Shade transparency','BackgroundColor',[1 1 1]);
    alphaEdit = uicontrol(d,'Style','edit','Position',[170 y 100 25],...
        'String',num2str(cfg.shade_alpha));
    y = y - dy;

    %  YLIM MODE 
    uicontrol(d,'Style','text','Position',[10 y 150 20],'String','Y axis','BackgroundColor',[1 1 1]);
    ylimMenu = uicontrol(d,'Style','popupmenu',...
        'String',{'auto','global'},...
        'Position',[170 y 100 25],...
        'Value',find(strcmp({'auto','global'},cfg.ylim_mode)));
    y = y - dy;

    %  SAVE BUTTON 
    uicontrol(d,'Style','pushbutton',...
        'String','Save',...
        'Position',[100 20 100 40],...
        'Callback',@saveCallback);

    %  CALLBACK 
    function saveCallback(~,~)

        cfg.pre_time = str2double(preEdit.String);
        cfg.post_time = str2double(postEdit.String);

        cfg.pre_time_plot = str2double(preEditPlot.String);
        cfg.post_time_plot = str2double(postEditPlot.String);

        cfg.split_polarity = logical(splitPolarityCheck.Value);

        alignOpts = {'min','max','none'};
        cfg.align_mode = alignOpts{alignMenu.Value};

        centralOpts = {'mean','median'};
        cfg.central_tendency = centralOpts{centralMenu.Value};

        spreadOpts = {'std','sem','none'};
        cfg.spread = spreadOpts{spreadMenu.Value};

        cfg.line_width = str2double(lwEdit.String);
        cfg.shade_alpha = str2double(alphaEdit.String);

        ylimOpts = {'auto','global'};
        cfg.ylim_mode = ylimOpts{ylimMenu.Value};

        config = cfg; 
        save('spike_config.mat','config');

        delete(d);

        % Optional: auto refresh plot
        try
            plot_spikes_callback(h);
        catch
        end
    end

end