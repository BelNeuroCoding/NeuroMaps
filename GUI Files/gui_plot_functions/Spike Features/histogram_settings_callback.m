function histogram_settings_callback(h, mode)

    h = guidata(h.figure);

    % --- Mode mapping ---
    names = {'ISI','IBI','Amplitude','FWHM'};
    fields = {'isi','ibi','amp','fwhm'};
    field = fields{mode};

    % --- Default settings ---
    if ~isfield(h, 'hist_settings') || ~isfield(h.hist_settings, field)
        s.binWidth = 0.1;
        s.xmin = 0;
        s.xmax = 10;
        s.ymax = 1000;
        s.normalise = false;
    else
        s = h.hist_settings.(field);
    end

    %  Dialog 
    d = dialog('Name', sprintf('%s Histogram Settings', names{mode}), ...
               'Position',[300 300 250 220]);

    uicontrol(d,'Style','text','Position',[10 170 120 20],'String','Bin Width','BackgroundColor',[1 1 1]);
    e_bin = uicontrol(d,'Style','edit','Position',[140 170 80 20],'String',num2str(s.binWidth),'BackgroundColor',[1 1 1]);

    uicontrol(d,'Style','text','Position',[10 130 120 20],'String','X Min','BackgroundColor',[1 1 1]);
    e_xmin = uicontrol(d,'Style','edit','Position',[140 130 80 20],'String',num2str(s.xmin),'BackgroundColor',[1 1 1]);

    uicontrol(d,'Style','text','Position',[10 100 120 20],'String','X Max','BackgroundColor',[1 1 1]);
    e_xmax = uicontrol(d,'Style','edit','Position',[140 100 80 20],'String',num2str(s.xmax),'BackgroundColor',[1 1 1]);

    uicontrol(d,'Style','text','Position',[10 70 120 20],'String','Y Max','BackgroundColor',[1 1 1]);
    e_ymax = uicontrol(d,'Style','edit','Position',[140 70 80 20],'String',num2str(s.ymax),'BackgroundColor',[1 1 1]);
    
    uicontrol(d,'Style','pushbutton','Position',[75 20 100 25],'String','Apply', ...
        'Callback', @(~,~) apply_settings());

    function apply_settings()
        s.binWidth  = str2double(e_bin.String);
        s.xmin      = str2double(e_xmin.String);
        s.xmax      = str2double(e_xmax.String);
        s.ymax = str2double(e_ymax.String);

        h.hist_settings.(field) = s;
        guidata(h.figure, h);
        delete(d);
    end
end