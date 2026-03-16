function lab = extract_lab(label)
% Extracts plotting format label i.e. User selected raw, filtered, or
% referenced signals
if isempty(label)
     label = questdlg('What would you like to plot?', ...
    'Plot Selection', ...
    'Raw','Filtered','Referenced','Raw');
end

% Select signal type
switch label
    case {'Raw','AC Filtered'}
        lab = 'raw';
    case 'LFP'
        lab = 'lfp';
    case 'Spikes'
        lab = 'hpf';
    case 'Ref'
        lab = 'ref';
    otherwise
        error('Unexpected format toggle.');
end
end