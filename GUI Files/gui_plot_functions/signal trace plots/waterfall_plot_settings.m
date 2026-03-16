function waterfall_plot_settings(h)
h = guidata(h.figure);  

% Default values
defaults.spacing = 300;
defaults.scaleBarTimeFrac = 5;
defaults.scaleBarAmplitude = 200;
defaults.excludedChannels = [];

prompt = { ...
    'Channel spacing (uV offset):', ...
    'Scale bar time label (s):', ...
    'Scale bar amplitude (uV):', ...
    'Excluded channels (comma separated):'};

dlgtitle = 'Waterfall Plot Settings';

definput = { ...
    num2str(defaults.spacing), ...
    num2str(defaults.scaleBarTimeFrac), ...
    num2str(defaults.scaleBarAmplitude), ...
    ''};

answer = inputdlg(prompt,dlgtitle,[1 50],definput);

if isempty(answer)
    axprops = [];
    return
end

% Convert inputs
axprops.spacing = str2double(answer{1});
axprops.scaleBarTimeFrac = str2double(answer{2});
axprops.scaleBarAmplitude = str2double(answer{3});

% Parse excluded channels
if isempty(answer{4})
    axprops.excludedChannels = [];
else
    axprops.excludedChannels = str2num(answer{4}); %#ok<ST2NM>
end

pop_graph_callback(h,[],axprops)

end