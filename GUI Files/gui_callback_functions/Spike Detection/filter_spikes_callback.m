function filter_spikes_callback(h)

    h = guidata(h.figure);

    backgdcolor = [1 1 1];
    accentcolor = [0.1 0.4 0.6];

    d = dialog('Position',[400 400 440 220], ...
               'Name','Spike Filter Ranges', ...
               'WindowStyle','modal', ...
               'Color', backgdcolor);

    metrics = { ...
        'Peak-to-Peak Amplitude (µV)', ...
        'FWHM (ms)'};

    defaults = [ ...
        10     1000;   % Amplitude
        0.1    0.3];   % FWHM

    nMetrics = size(defaults,1);
    y = 140;

    for i = 1:nMetrics

        uicontrol(d,'Style','text',...
            'Position',[20 y 220 20],...
            'HorizontalAlignment','left',...
            'String',metrics{i},...
            'ForegroundColor',accentcolor,...
            'BackgroundColor',backgdcolor,...
            'FontWeight','bold');

        minEdit(i) = uicontrol(d,'Style','edit',...
            'Position',[250 y 70 25],...
            'String',num2str(defaults(i,1)),...
            'BackgroundColor',[1 1 1]);

        maxEdit(i) = uicontrol(d,'Style','edit',...
            'Position',[330 y 70 25],...
            'String',num2str(defaults(i,2)),...
            'BackgroundColor',[1 1 1]);

        y = y - 60;
    end

    uicontrol(d,'Position',[170 20 100 35],...
              'String','Apply',...
              'FontWeight','bold',...
              'ForegroundColor',[1 1 1],...
              'BackgroundColor',accentcolor,...
              'Callback',@applyCallback);

    uiwait(d);

    % ---- Callback ----
    function applyCallback(~,~)

        vals = zeros(nMetrics,2);

        for j = 1:nMetrics
            vals(j,1) = str2double(get(minEdit(j),'String'));
            vals(j,2) = str2double(get(maxEdit(j),'String'));
        end

        if any(isnan(vals),'all')
            errordlg('All fields must be numeric.','Invalid Input');
            return;
        end

        if any(vals(:,1) > vals(:,2))
            errordlg('Minimum cannot exceed Maximum.','Range Error');
            return;
        end

        ranges.amp  = vals(1,:);
        ranges.fwhm = vals(2,:);

        h.spike_filter_ranges = ranges;
        guidata(h.figure,h);
        spike_feats_callback(h);

        uiresume(d);
        delete(d);
    end
end