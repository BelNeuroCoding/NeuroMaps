function add_val = compute_nearest_values(coor_add, coor_neigh, val_neigh, k)
    
    add_val = NaN(size(coor_add,1),1);
    L = length(add_val);
    
    for i = 1:L
        % Distances between the added electrode and the original ones
        target = repmat(coor_add(i,:),size(coor_neigh,1),1);
        d = sqrt(sum((target-coor_neigh).^2,2));
        
        % K-nearest neighbors
        [~, idx] = sort(d,'ascend');
        if length(idx)<(k+1)
            k= length(idx)-1;
            idx = idx(2:1+k);
        end
        
        % Final value as the mean value of the k-nearest neighbors
        add_val(i) = mean(val_neigh(idx));
    end
    
end