function configure_python()

if count(py.sys.path,'') == 0
    try
        if isdeployed
            % locate bundled python
            rootDir = ctfroot;   % compiled app extraction folder
            pyExe = fullfile(rootDir,'python_env','pythonw.exe');
        else 
            pyExe = fullfile(pwd,'python_env','pythonw.exe');
        end
       
            pyenv('Version',pyExe,'ExecutionMode','OutOfProcess');
    catch ME
        warndlg(sprintf('Python Configuration Failed: %s', ME.message));
       
    end

end

end