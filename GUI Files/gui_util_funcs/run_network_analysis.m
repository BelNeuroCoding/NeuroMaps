function run_network_analysis(h)
h = guidata(h.figure);  
%% Main Spike Tabs
if ~isfield(h,'network_dynamics_tab') || ~isvalid(h.network_dynamics_tab)
create_network_tabs(h)
end
h=guidata(h.figure);

set_status(h.figure,"loading","Computing Network Connectivity...");

compute_sttc_latency(h)
network_conn_callback(h)
nwcorr_callback(h)

set_status(h.figure,"ready","Network Analysis Step Complete...");

end
