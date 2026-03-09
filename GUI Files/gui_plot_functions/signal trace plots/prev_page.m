function prev_page(fig)

h = guidata(fig);

h.waterfallPage = max(1,h.waterfallPage-1);

guidata(fig,h)

pop_graph_callback(h)

end