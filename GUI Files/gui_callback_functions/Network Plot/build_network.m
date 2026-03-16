function [adjacency_matrix, receiver_nodes, sender_nodes, broker_nodes, node_degrees] = ...
        build_network(sttc_matrix, latency_matrix, threshold1, threshold2)

    num_nodes = size(sttc_matrix, 1);
    adjacency_matrix = sttc_matrix;
    adjacency_matrix(sttc_matrix < threshold1) = 0;

    Din = zeros(1, num_nodes);
    Dout = zeros(1, num_nodes);

    % Loop through each pair of nodes in the STTC matrix to assign directionality 
    for i = 1:num_nodes 
        for j = 1:num_nodes 
            if i ~= j && adjacency_matrix(i,j)~=0 
            latency = latency_matrix(i, j); 
            if latency < 0 % Negative latency -> edge from i to j (out-degree for i, in-degree for j) 
                Dout(i) = Dout(i) + 1; Din(j) = Din(j) + 1; directionality(i, j) = -1; % From i to j 
            elseif latency > 0 % Positive latency -> edge from j to i 
                Dout(j) = Dout(j) + 1; Din(i) = Din(i) + 1; directionality(i, j) = 1; % From j to i 
            end 
            end 
        end 
    end

    receiver_nodes = (Din - Dout)./(Din + Dout) > threshold2;
    sender_nodes   = (Dout - Din)./(Din + Dout) > threshold2;
    broker_nodes   = ~(receiver_nodes | sender_nodes);
    disp('Receiver nodes:'); disp(find(receiver_nodes)); % Indices of receiver nodes 
    disp('Sender nodes:'); disp(find(sender_nodes)); % Indices of sender nodes 
    disp('Broker nodes:'); disp(find(broker_nodes)); % Indices of broker nodes

    G = graph(adjacency_matrix,'upper','omitselfloops');
    node_degrees = degree(G);
end
