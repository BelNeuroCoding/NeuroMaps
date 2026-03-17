function traces_settings(h)
    h = guidata(h.figure);

    % Defaults (or previous settings)
    if isfield(h,'traces_props')
        p = h.traces_props;
    else
        p.linewidth = 1.25;       % default line width
        p.thresh_width = 0.75;    % threshold line width
        p.std_min = 2;            % reference thresholds
        p.std_max = 5;
        p.ylim = [];              % auto if empty
        p.xlim = [];              % auto if empty
    end

    % Create Settings Figure
    f = uifigure('Name','Trace Plot Settings','Position',[100 100 360 300]);
    deltaY = 35; % vertical spacing between rows
    labelWidth = 120; fieldWidth = 120; height = 22;
    
    yPos = 240; % start near top
    
    %  Line width 
    uilabel(f, 'Position',[20 yPos labelWidth height],'Text','Line Width');
    ef_lw = uieditfield(f,'numeric','Value',p.linewidth,'Limits',[0.1 5], ...
        'Position',[150 yPos fieldWidth height]);
    
    yPos = yPos - deltaY; % move down for next row
    
    %  Threshold width 
    uilabel(f, 'Position',[20 yPos labelWidth height],'Text','Threshold Line Width');
    ef_thresh = uieditfield(f,'numeric','Value',p.thresh_width,'Limits',[0.1 5], ...
        'Position',[150 yPos fieldWidth height]);
    
    yPos = yPos - deltaY;
    
    %  Ref STD Min 
    uilabel(f, 'Position',[20 yPos labelWidth height],'Text','Ref STD Min');
    ef_stdmin = uieditfield(f,'numeric','Value',p.std_min,'Limits',[0 10], ...
        'Position',[150 yPos fieldWidth height]);
    
    yPos = yPos - deltaY;
    
    %  Ref STD Max 
    uilabel(f, 'Position',[20 yPos labelWidth height],'Text','Ref STD Max');
    ef_stdmax = uieditfield(f,'numeric','Value',p.std_max,'Limits',[0 10], ...
        'Position',[150 yPos fieldWidth height]);
    
    yPos = yPos - deltaY;
    
    %  Y-Limits 
    uilabel(f,'Position',[20 yPos labelWidth height],'Text','Y-Limits [min,max]');
    ef_ylim = uieditfield(f,'text','Value',mat2str(p.ylim), ...
        'Position',[150 yPos fieldWidth height], ...
        'Tooltip','Enter as [min max], leave empty for auto.');
    
    yPos = yPos - deltaY;
    
    %  X-Limits 
    uilabel(f,'Position',[20 yPos labelWidth height],'Text','X-Limits [start,end]');
    ef_xlim = uieditfield(f,'text','Value',mat2str(p.xlim), ...
        'Position',[150 yPos fieldWidth height], ...
        'Tooltip','Enter as [start end] in seconds, leave empty for auto.');


    % Apply button
    buttonHeight = 35;
    uibutton(f,'Text','Apply','Position',[150 yPos-50 100 buttonHeight], ...
        'ButtonPushedFcn',@(btn,event) apply());

    function apply()
        % Update props struct
        p.linewidth = ef_lw.Value;
        p.thresh_width = ef_thresh.Value;
        p.std_min = ef_stdmin.Value;
        p.std_max = ef_stdmax.Value;

        % Parse Y-limits
        ylimVal = str2num(ef_ylim.Value); %#ok<ST2NM>
        if numel(ylimVal)==2
            p.ylim = ylimVal;
        else
            p.ylim = [];
        end

        % Parse X-limits
        xlimVal = str2num(ef_xlim.Value); %#ok<ST2NM>
        if numel(xlimVal)==2
            p.xlim = xlimVal;
        else
            p.xlim = [];
        end

        h.traces_props = p;
        guidata(h.figure,h);
        close(f);

        % Re-initialize axes to apply new settings
        init_traces_tab(h);
    
        % Update plots with current data
        update_traces_tab(h);
    end
end