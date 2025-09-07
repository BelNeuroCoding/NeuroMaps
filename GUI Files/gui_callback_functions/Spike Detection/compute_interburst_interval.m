function IBI_values = compute_interburst_interval(bursts)
    % Function to compute inter-burst intervals (IBI)
    % Input: bursts - a struct array with fields 'start' and 'end'
    
    % If there are fewer than 2 bursts, IBI cannot be calculated
    if length(bursts) < 2
        IBI_values = [];
        return;
    end
    
    % Extract burst end times and subsequent burst start times
    burst_end_times = [bursts.end];
    burst_start_times = [bursts.start];
    
    % Compute IBI as the time between the end of one burst and the start of the next burst
    IBI_values = burst_start_times(2:end) - burst_end_times(1:end-1);
end
