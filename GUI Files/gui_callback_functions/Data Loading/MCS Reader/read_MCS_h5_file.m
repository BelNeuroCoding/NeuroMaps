function [dat, AmpChs, t,metadata] = read_MCS_h5_file(file_path)
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
    h = waitbar(0,'Loading data, please wait...');
    drawnow();
    try
        dat = data_file.Recording{1}.AnalogStream{1}.getConvertedData(cfg); 
    catch ME
        if isvalid(h)
            close(h)
        end
        errordlg(['Error loading data: ' ME.message],'Load Error');
        rethrow(ME)   
    end
    
    if isvalid(h)
        close(h)
    end
    dat = (dat.*10.^(exponent-(exponent+6))); % (NChans, NSamps)
    fs = data_file.Recording{1}.AnalogStream{1}.getSamplingRate;
    t = (0:length(dat)-1)/fs;
    [AmpChs.custom_order, sort_idx] = sort(channels);  
    dat = dat(sort_idx,:);        % reorder rows of dat
    AmpChs.port_number = 1*ones(size(channels));
    metadata.date = data_file.Data.Date;
    [~, name, ext] = fileparts(file_path);
    metadata.filename = [name ext];
end