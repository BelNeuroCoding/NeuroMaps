function configure_python()

pe = pyenv;

if pe.Status == "NotLoaded"

    % locate bundled python
    rootDir = ctfroot;   % compiled app extraction folder
    pyExe = fullfile(rootDir,'python_env','Scripts','python.exe');

    if isfile(pyExe)
        try
            pyenv('Version',pyExe,'ExecutionMode','OutOfProcess');
        catch ME
            warning(ME.message)
        end
    end

end

end