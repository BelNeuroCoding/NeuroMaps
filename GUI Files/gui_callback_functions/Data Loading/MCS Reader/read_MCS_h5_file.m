function [dat, AmpChs, t,metadata] = read_MCS_h5_file(file_path)

% Neu
    import McsHDF5.*
    % Load the .h5 file
    data_file = McsHDF5.McsData(file_path);
    exponent = data_file.Recording{1}.AnalogStream{1}.Info.Exponent(:);
    exponent = double(exponent);
    label = data_file.Recording{1}.AnalogStream{1}.Info.Label(:);
    numChannels = length(label);

    channels = zeros(numChannels, 1) + nan;
    for channelIdx = 1:numChannels
        channelStr = split(label{channelIdx}, ' ');

        if strcmp(channelStr{end}, 'Ref')
           channelNumber = 15; 
        else
           channelNumber = str2num(channelStr{end});
        end

        channels(channelIdx) = channelNumber;
    end

    cfg = [];
    cfg.dataType = 'double';
    dat = data_file.Recording{1}.AnalogStream{1}.getConvertedData(cfg); 
    dat = (dat.*10.^(exponent-(exponent+6))); % (NChans, NSamps)
    fs = data_file.Recording{1}.AnalogStream{1}.getSamplingRate;
    t = (0:length(dat)-1)/fs;
    [AmpChs.custom_order, sort_idx] = sort(channels);  
    dat = dat(sort_idx,:);        % reorder rows of dat
    AmpChs.port_number = 1*ones(size(channels));
    metadata = data_file.Data.Date;
end