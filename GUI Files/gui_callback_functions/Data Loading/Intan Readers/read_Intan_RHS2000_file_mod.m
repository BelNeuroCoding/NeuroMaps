function [amplifier_data, amplifier_channels, t] = read_Intan_RHS2000_minimal(file, path)

filename = fullfile(path, file);
fid = fopen(filename, 'r');

% --- header ---
magic_number = fread(fid, 1, 'uint32');
if magic_number ~= hex2dec('d69127ac')
    error('Not a valid RHS file');
end
fread(fid, 1, 'int16');
fread(fid, 1, 'int16');
sample_rate = fread(fid, 1, 'single');
num_samples_per_block = 128;

% skip unused header bits until signal groups
fseek(fid, 36, 'cof'); % jump past dc_amp_data_saved, board_mode, reference_channel
n_signal_groups = fread(fid, 1, 'int16');

amplifier_channels = struct([]);
amp_index = 1;

for g = 1:n_signal_groups
    group_name   = fread_QString(fid); %#ok<NASGU>
    group_prefix = fread_QString(fid); %#ok<NASGU>
    group_enabled = fread(fid, 1, 'int16');
    n_chan = fread(fid, 1, 'int16');
    fread(fid, 1, 'int16'); % n_amp
    if n_chan > 0 && group_enabled > 0
        for c = 1:n_chan
            fread_QString(fid); % native_name
            fread_QString(fid); % custom_name
            fread(fid, 1, 'int16'); % native_order
            custom_order = fread(fid, 1, 'int16');
            sig_type = fread(fid, 1, 'int16');
            chan_enabled = fread(fid, 1, 'int16');
            fread(fid, 1, 'int16'); % chip_channel
            fread(fid, 1, 'int16'); % command_stream
            fread(fid, 1, 'int16'); % board_stream
            fread(fid, 4, 'int16'); % trigger info
            imp_mag   = fread(fid, 1, 'single');
            imp_phase = fread(fid, 1, 'single');

            if chan_enabled && sig_type == 0
                amplifier_channels(amp_index).electrode_impedance_magnitude = imp_mag; %#ok<AGROW>
                amplifier_channels(amp_index).electrode_impedance_phase     = imp_phase;
                amplifier_channels(amp_index).custom_order                  = custom_order;
                amplifier_channels(amp_index).port_number                   = g;
                amp_index = amp_index + 1;
            end
        end
    end
end

num_amplifier_channels = numel(amplifier_channels);

% --- figure out number of blocks ---
fseek(fid, 0, 'eof');
filesize = ftell(fid);
bytes_per_sample = 4 + 2*num_amplifier_channels; % timestamp + amp data
bytes_per_block  = num_samples_per_block * bytes_per_sample;
data_bytes = filesize - ftell(fid);
num_blocks = floor(data_bytes / bytes_per_block);
num_samples = num_blocks * num_samples_per_block;

% --- read data ---
fseek(fid, -num_blocks*bytes_per_block, 'eof');

% timestamps
timestamps = fread(fid, [num_samples_per_block, num_blocks], 'int32=>double');
t = reshape(timestamps, 1, []) / sample_rate;

% amps
amps = fread(fid, [num_amplifier_channels*num_samples_per_block, num_blocks], 'uint16=>double');
amps = reshape(amps, num_amplifier_channels, num_samples_per_block, num_blocks);
amplifier_data = reshape(permute(amps, [1 2 3]), num_amplifier_channels, []);

% scale to µV
amplifier_data = 0.195 * (amplifier_data - 32768);

fclose(fid);
end
