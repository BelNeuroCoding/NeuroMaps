function initialize_random_seed(seed)
    % INPUT: 
    %   seed - (Optional) A numeric value to set the random seed. 
    %          If not provided, a default value is used.
    %
    % FUNCTIONALITY:
    %   Sets the random seed to ensure reproducible results for 
    %   random processes like clustering or simulation.

    if nargin < 1
        seed = 42; % Default seed if none is provided
    end
    
    % Set the random number generator seed
    rng(seed);
    
    % Print confirmation (optional for debugging)
    fprintf('Random seed set to %d.\n', seed);
end