# NeuroMaps

#### Overview
NeuroMaps is a MATLAB GUI for processing, analysing, and visualising multi-channel electrophysiological recordings. It integrates spike, LFP, and network-level metrics into a central data structure for fast analysis, quality control, and downstream statistics.

#### Features
- **Signal Visualization**: Raw and filtered traces, waterfall plots.  
- **Spike Analysis**: Spike detection, clustering, inter-spike intervals (ISI), bursts, amplitude, full-width half-maximum (FWHM), Phase plots (dv/dt).  
- **Frequency & Spectral Analysis**: Power spectral density (PSD), spectrograms, continuous wavelet transform (CWT), bandpower, FOOOF fitting.  
- **Phase & Coupling Metrics**: Bandpower, Phase-Amplitude Coupling (PAC), Oscillatory and Exponent Analysis.  
- **Network Dynamics**: Firing rate heatmaps, raster plots, STTC, network connectivity matrices.  
- **Quality Control**: Electrical properties per channel, QC flags and notes.  
- **Probe Map Integration**: Spatial layout of channels, custom probe configurations.  
- **Batch Analysis**: Aggregate spike or LFP data across sessions.

#### System Requirements
- **MATLAB**: 2024b or higher  
- **Toolboxes**: Signal Processing, Statistics & Machine Learning, Wavelet, Econometrics, Mapping  
- **Python 3.11** (optional, for FOOOF & MATLAB-Python interface)  
- **Hardware**: Minimum 1.3 GHz CPU, 16 GB RAM recommended  

#### Python Setup (MATLAB Integration)
1. Check Python configuration in MATLAB:  
   ```matlab
   pyenv
2. Set Python version in MATLAB:
Directory = 'C:\Users\User\appdata\local\programs\python\python311\pythonw.exe';
pyenv('Version',Directory,'ExecutionMode','OutOfProcess')
3. Install required Python packages:
"C:\Users\User\AppData\Local\Programs\Python\Python311\pythonw.exe" -m pip install numpy scipy matplotlib fooof
4. Restart MATLAB before running NeuroMaps

###Installation

1. Clone or download this repository.

2. Add the NeuroMaps folder (and subfolders) to your MATLAB path.

3. Launch the GUI:
NeuroMaps or run NeuroMaps.m directly

#### Usage
##### Upload and Visualise
1. Open NeuroMaps in MATLAB
2. Upload recordings via Data Files -> Upload. Multiple files per session supported.
3. View raw or filtered signals and assess quality:
Signal Traces Tab:
- Waterfall plots
- Signal Traces
Quality Checks Tab:
- Electrical Properties
- Noise Levels
- QC (good/bad assessment: you can toggle and untoggle which quality of data to show)
Probe Map: 
Shows your the position of the currently selected channel via the slider below the left tabs (Port:Channel)
4. After inspecting the signal traces, perform either referencing or filtering directly
- Signals Traces Tab will update
- Toggle the Raw/Filtered buttons on the top to change the view on: waterfall plots and PSD/Spectrogram/CWT plots
- Filter data and view it. Use toggles in the Signal Traces tab to set thresholds for spike detection
5A. Spike Detection Route
- Toggle whether to exclude bad channels at the bottom of the screen then detect spikes
- View detected spikes, firing rates, plot rasters, network connectivity, sttc, and various spike features
- Perform clustering. Once this step is done, downstream plots will be performed only on 'selected clusters'. Select all clusters if this is of interest, else select only physiologically looking clusters

5B. LFP Analysis Route
- Perform FOOOF analysis and plot oscillatory/exponent heatmaps
- Measure bandpowers and perform PAC analysis between specific channels of interest after inspecting the raster plots and population activity

6. View Gif of spikes firing on the heatmap: Go to the save menu and click on Save GIF

7. Save Data for future multi-experiment analysis


#### Performance
- Performance depends on CPU, RAM, and disk speed. It is recommended not to analyse more than 5 minute files at a time (ideally 1 minute at a time) for the initial analysis
#### Citation
If you use NeuroMaps in your research, please cite it appropriately.

#### References
Berens, P. CircStat: a MATLAB toolbox for circular statistics. J. Stat. Softw. 31, 1–21 (2009).
Bounova, G. & De Weck, O. Overview of metrics and their correlation patterns for multiple-metric topology analysis on heterogeneous graph ensembles. Phys. Rev. E Stat. Nonlinear Soft Matter Phys. 85, 1–11 (2012).
Cutts, C. S. & Eglen, X. S. J. Detecting pairwise correlations in spike trains: an objective comparison of methods and application to the study of retinal waves. J. Neurosci. 34, 14288–14303 (2014).
Souza, B. C., Lopes-dos-Santos, V., Bacelo, J., & Tort, A. B. (2019). Spike sorting with Gaussian mixture models. Scientific reports, 9(1), 3627.
Giandomenico, S. L. et al. Cerebral organoids at the air–liquid interface generate diverse nerve tracts with functional output. Nat. Neurosci. 22, 669–679 (2019).
Quiroga, R. Q., Nadasdy, Z. & Ben-Shaul, Y. Unsupervised spike detection and sorting with wavelets and superparamagnetic clustering. Neural Comput. 16, 1661–1687 (2004).
Sharf, T., Van Der Molen, T., Glasauer, S. M., Guzman, E., Buccino, A. P., Luna, G., ... & Kosik, K. S. (2022). Functional neuronal circuitry and oscillatory dynamics in human brain organoids. Nature communications, 13(1), 4403.
Trujillo, C. A., Gao, R., Negraes, P. D., Gu, J., Buchanan, J., Preissl, S., ... & Muotri, A. R. (2019). Complex oscillatory waves emerging from cortical organoids model early human brain network development. Cell stem cell, 25(4), 558-569.
