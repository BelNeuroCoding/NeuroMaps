function pop_graph_callback(h,src1,axprops)
%% pop_graph_callback - Display channel signals over a selected time window
set_status(h.figure,"loading","Waterfall Plot...");

h = guidata(h.figure);  

selectedStr = get(h.formatToggleGroup, 'SelectedObject').String;
lab = extract_lab(selectedStr);

exclude_impedance_chans_toggle = get(h.excl_imp_toggle, 'Value');
exclude_noisy_chans_toggle = get(h.excl_high_STD_toggle,'Value');

idx = h.portList.Value;
map = h.portList.UserData;
selected = map(idx,:);

%% Pagination settings
h.tilesPerPage = 2;
h.selectedPorts = selected;

if ~isfield(h,'waterfallPage')
    h.waterfallPage = 1;
end

guidata(h.figure,h)
if nargin<2
    src1=[];
end
if nargin<3
    render_waterfall_page(h.figure,src1,lab,...
        exclude_impedance_chans_toggle,...
        exclude_noisy_chans_toggle)
else
    render_waterfall_page(h.figure,src1,lab,...
    exclude_impedance_chans_toggle,...
    exclude_noisy_chans_toggle,axprops)
end
set_status(h.figure,"ready","Waterfall Plot Complete...");

end