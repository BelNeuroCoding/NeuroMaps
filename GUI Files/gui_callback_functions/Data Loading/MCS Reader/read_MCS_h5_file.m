function [recording_data, electrode_stream, fsample] = read_MCS_h5_file(file_path)

% read_MCS_h5_file - Reads MCS .h5 file and extracts recording data.
%
% This function opens a .h5 file from Multi Channel Systems (MCS), extracts
% the raw recording data, electrode stream information, and the sampling frequency.
%
% Parameters:
%   file_path - Path to the .h5 file to be read.
%
% Returns:
%   recording_data - Corrected recording data in microvolts.
%   electrode_stream - The electrode stream object containing metadata.
%   fsample - Sampling frequency of the recording data.
%
% Example:
%   [recording_data, electrode_stream, fsample] = read_MCS_h5_file('data.h5');
%
% Notes:
%   - The function loads the .h5 file using the McsHDF5 library.
%   - The raw data is corrected using ADC step and zero values and converted to microvolts.
    import McsHDF5.*
    % Load the .h5 file
    file = McsHDF5.McsData(file_path);
    electrode_stream = file.Recording{1}.AnalogStream{1};
    fsample = double(electrode_stream.ChannelData(1).Info.SamplingFrequency);
    
    % Extract the raw data from the electrode stream
    signal = [];
    for i = 1:length(electrode_stream.ChannelData)
        signal = [signal; double(electrode_stream.ChannelData(i).Data)];
    end
    
    % Correct the signal
    scale = double(electrode_stream.ChannelData(1).Info.ADCStep);
    ad_zero = double(electrode_stream.ChannelData(1).Info.ADZero);
    signal_corrected = (signal - ad_zero) * scale;
    
    % Convert the signal to microvolts
    scale_factor_for_uV = 1e6;  % Conversion factor from volts to microvolts
    recording_data = signal_corrected * scale_factor_for_uV;
end