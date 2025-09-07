# NeuroMaps

## Overview
NeuroMaps is a MATLAB GUI for processing, analysing, and visualising multi-channel electrophysiological recordings. It integrates spike, LFP, and network-level metrics into a central data structure for fast analysis, quality control, and downstream statistics.

---

## Features
- **Signal Visualization**: Raw and filtered traces, waterfall plots  
- **Spike Analysis**: Spike detection, clustering, inter-spike intervals (ISI), bursts, amplitude, full-width half-maximum (FWHM), phase plots (dV/dt)  
- **Frequency & Spectral Analysis**: Power spectral density (PSD), spectrograms, continuous wavelet transform (CWT), bandpower, FOOOF fitting  
- **Phase & Coupling Metrics**: Bandpower, Phase-Amplitude Coupling (PAC), Oscillatory and Exponent Analysis  
- **Network Dynamics**: Firing rate heatmaps, raster plots, STTC, network connectivity matrices  
- **Quality Control**: Electrical properties per channel, QC flags and interactive data curation  
- **Probe Map Integration**: Spatial layout of channels, custom probe configurations  
- **Batch Analysis**: Aggregate spike or LFP data across sessions  

---

## System Requirements
- MATLAB 2024a or higher  
- Toolboxes: Signal Processing, Statistics & Machine Learning, Wavelet, Econometrics, Mapping  
- Python 3.11 (optional, for FOOOF and MATLAB-Python interface)  
- Hardware: Minimum 1.3 GHz CPU, 16 GB RAM recommended  

---

## Python Setup (MATLAB Integration)
1. Check Python configuration in MATLAB using `pyenv`  
2. Set Python version in MATLAB using the path to Python 3.11 (for example, C:\Users\User\appdata\local\programs\python\python311\pythonw.exe) and execution mode 'OutOfProcess'  
3. Install required Python packages by running pip install for numpy, scipy, matplotlib, and fooof  
4. Restart MATLAB before running NeuroMaps  

---

## Installation
1. Clone or download this repository  
2. Add the `NeuroMaps` folder and all subfolders to your MATLAB path  
3. Launch the GUI by running `NeuroMaps` or opening `NeuroMaps.m` directly  

---

## Usage

### Upload and Visualise
1. Open NeuroMaps in MATLAB  
2. Upload recordings via Data Files → Upload (multiple files per session supported)  
3. View raw or filtered signals and assess quality:  

**Signal Traces Tab**: Waterfall plots and signal traces  
**Quality Checks Tab**: Electrical properties, noise levels, and QC flags (toggle good/bad channels)  
**Probe Map**: Shows the position of the currently selected channel via slider (Port:Channel)  

4. After inspecting signals, perform referencing or filtering. Signal Traces tab will update automatically. Toggle Raw/Filtered buttons to view waterfall plots, PSD, spectrogram, and CWT plots. Set thresholds for spike detection using the Signal Traces tab.  

---

### Spike Detection Route
1. Exclude bad channels using the toggle at the bottom of the screen  
2. Detect spikes  
3. View detected spikes, firing rates, raster plots, network connectivity, STTC, and spike features  
4. Perform clustering. Only "selected clusters" are used for downstream analysis; choose physiological clusters for analysis  

---

### LFP Analysis Route
1. Perform FOOOF analysis and inspect oscillatory/exponent heatmaps  
2. Measure bandpowers and perform PAC analysis between channels of interest after inspecting raster plots and population activity  

---

### Save and Export
1. View GIF of spikes firing on the heatmap via Save → Save GIF  
2. Save processed data for future multi-experiment analysis via Save → Save Data  

---

## Performance
- Analysis speed depends on CPU, RAM, and disk speed  
- Recommended: analyze no more than 5-minute files at a time (ideally 1-minute segments for initial analysis)  

---

## Citation
If you use NeuroMaps in your research, please cite it appropriately  

---

## References
- Berens, P. CircStat: a MATLAB toolbox for circular statistics. J. Stat. Softw. 31, 1–21 (2009)  
- Bounova, G. & De Weck, O. Overview of metrics and their correlation patterns for multiple-metric topology analysis on heterogeneous graph ensembles. Phys. Rev. E Stat. Nonlinear Soft Matter Phys. 85, 1–11 (2012)  
- Cutts, C. S. & Eglen, X. S. Detecting pairwise correlations in spike trains: an objective comparison of methods and application to the study of retinal waves. J. Neurosci. 34, 14288–14303 (2014)  
- Souza, B. C., Lopes-dos-Santos, V., Bacelo, J., & Tort, A. B. Spike sorting with Gaussian mixture models. Scientific Reports 9, 3627 (2019)  
- Giandomenico, S. L. et al. Cerebral organoids at the air–liquid interface generate diverse nerve tracts with functional output. Nat. Neurosci. 22, 669–679 (2019)  
- Quiroga, R. Q., Nadasdy, Z. & Ben-Shaul, Y. Unsupervised spike detection and sorting with wavelets and superparamagnetic clustering. Neural Comput. 16, 1661–1687 (2004)  
- Sharf, T., Van Der Molen, T., Glasauer, S. M., Guzman, E., Buccino, A. P., Luna, G., ... & Kosik, K. S. Functional neuronal circuitry and oscillatory dynamics in human brain organoids. Nature Communications 13, 4403 (2022)  
- Trujillo, C. A., Gao, R., Negraes, P. D., Gu, J., Buchanan, J., Preissl, S., ... & Muotri, A. R. Complex oscillatory waves emerging from cortical organoids model early human brain network development. Cell Stem Cell 25, 558–569 (2019)  
