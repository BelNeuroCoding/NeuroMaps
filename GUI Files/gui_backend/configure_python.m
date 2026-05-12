function configure_python()

try
    if isdeployed
        rootDir = ctfroot;
        pyExe = fullfile(rootDir, 'NeuroMaps','python_env', 'python.exe');
    else
        rootDir = pwd;
        pyExe = fullfile(rootDir,'python_env', 'python.exe');
    end

    if ~isfile(pyExe)
        error("Python executable not found: %s", pyExe);
    end

    pe = pyenv;

    if pe.Status == "NotLoaded"
        pyenv("Version", pyExe, "ExecutionMode", "OutOfProcess");
    end

    pe = pyenv;

    disp("Python configured:");
    disp(pe);

    % Smoke test
    py.importlib.import_module('sys');
    py.importlib.import_module('numpy');
    py.importlib.import_module('scipy');
    py.importlib.import_module('matplotlib');
    py.importlib.import_module('fooof');

catch ME
    msg = sprintf("Python Configuration Failed:\n\n%s", getReport(ME, 'extended', 'hyperlinks', 'off'));
    errordlg(msg);
    error(msg);
end

end