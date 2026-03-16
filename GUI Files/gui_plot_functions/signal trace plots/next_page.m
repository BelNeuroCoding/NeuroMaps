function next_page(fig)

h = guidata(fig);

numTiles = size(h.selectedPorts,1);
maxPage = ceil(numTiles / h.tilesPerPage);

if h.waterfallPage < maxPage
    h.waterfallPage = h.waterfallPage + 1;
end

guidata(fig,h)

pop_graph_callback(h)

end