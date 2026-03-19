function fooof_results_fitted = fit_lfps(lfp_filt,fs_ds,filt_params,settings)
py.importlib.import_module('numpy');
py.importlib.import_module('scipy');
py.importlib.import_module('matplotlib');
py.importlib.import_module('fooof');
py.importlib.import_module('builtins');
py_builtin = py.importlib.import_module('builtins');

[psds,freqs] =  pwelch(lfp_filt,fs_ds*2,fs_ds,fs_ds*2,fs_ds);
freqs = freqs';
powers_int2 =zeros(size(psds))'; 
hWait = waitbar(0, 'Interpolating spectra...');
for i = 1:size(lfp_filt,2)
if max(lfp_filt(:,i))>0
% Convert inputs
freqs = py.numpy.array(freqs);
power_spectrum = py.numpy.array(psds(:,i));
centre_freqs = [];
if isfield(filt_params,'powerline_freqs')
    centre_freqs = filt_params.powerline_freqs;
end
if ~isempty(centre_freqs)
    BW = filt_params.bandwidth;
    halfBW = BW/2;
    for j = 1:length(centre_freqs)
        if centre_freqs(j)<max(freqs)
        fit_freqs{j} = [centre_freqs(j)-halfBW, centre_freqs(j)+halfBW];
        end
    end
    fit_freqs_python = py_builtin.list(cellfun(@py_builtin.list,fit_freqs,'UniformOutput',false));
    fit_results = cell(py.fooof.utils.interpolate_spectrum(freqs,power_spectrum,fit_freqs_python));
else
    fit_freqs = {[48, 52],[98 102], [148, 152],[198,202],[248,252],[298,302],[348 352],[448 452]};
    fit_freqs_python = py_builtin.list(cellfun(@py_builtin.list,fit_freqs,'UniformOutput',false));
    fit_results = cell(py.fooof.utils.interpolate_spectrum(freqs,power_spectrum,fit_freqs_python));

end
freqs_int2 = double(fit_results{1});
powers_int2(i,:) =  double(fit_results{2});
    % Update waitbar
    waitbar(i/size(lfp_filt,2), hWait, ...
        sprintf('Processing channel %d of %d', i, size(lfp_filt,2)));
end
end
close(hWait)
% FOOOF settings
%settings = struct();  % Use defaults
%f_range = [1,35];
fooof_results_fitted = fooof_group(freqs_int2, powers_int2', settings);
end
