function set_status(fig,state,msg)

h = guidata(fig);

switch lower(state)

    case "loading"
        color = [0.9 0.7 0];      % yellow

    case "ready"
        color = [0 0.7 0];        % green

    case "error"
        color = [0.8 0 0];        % red

    otherwise
        color = [0.5 0.5 0.5];    % grey

end

set(h.statusLight,'ForegroundColor',color)

if nargin > 2
    set(h.statusText,'String',msg)
end

drawnow

end