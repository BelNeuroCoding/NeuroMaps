function data_out = powerline_filter_gui(data, fs,linefreq,bandwidth)
% Applies powerline notch filters at harmonics efficiently
if isempty(linefreq) | isempty(bandwidth)
linefreq = [50;100; 150; 200;250;300; 350;400; 450;500; 550; 650; 750; 850;950;1150;1250;1450;1750;1850;4000];  % Center frequencies
bandwidth = 4;  % Bandwidth of ±2 Hz around each frequency
end
hWait = waitbar(0, 'Applying powerline filters...', 'Name', 'Filtering Progress');

for j = 1:length(linefreq)

    tstep = 1/fs;
    Fc = linefreq(j)*tstep;
    
    L = length(data);
    
    % Calculate IIR filter parameters
    d = exp(-2*pi*(bandwidth/2)*tstep);
    b = (1 + d*d)*cos(2*pi*Fc);
    a0 = 1;
    a1 = -b;
    a2 = d*d;
    a = (1 + d*d)/2;
    b0 = 1;
    b1 = -2*cos(2*pi*Fc);
    b2 = 1;
    
    data_out = zeros(size(data));
    data_out(:,1) = data(:,1);  
    data_out(:,2) = data(:,2);
    % Run filter
    for i=3:L
        data_out(:,i) = (a*b2*data(:,i-2) + a*b1*data(:,i-1) + a*b0*data(:,i) - a2*data_out(:,i-2) - a1*data_out(:,i-1))/a0;
    end
    data = data_out;
    waitbar(j / length(linefreq), hWait, sprintf('Powerline Filtering %d%% Complete', round((j / length(linefreq))*100)));

end
close(hWait);

end
