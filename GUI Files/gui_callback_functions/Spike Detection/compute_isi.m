function ISI_values = compute_isi(spike_times)
    % Function to compute inter-spike intervals (ISI)
    if length(spike_times) > 1
        ISI_values = diff(spike_times);
    else
        ISI_values = [];
    end
end
