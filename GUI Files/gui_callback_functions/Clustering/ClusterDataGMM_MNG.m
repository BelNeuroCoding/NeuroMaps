function [id_cluster,wpca,peaks] = ClusterDataGMM_MNG(waveforms)
% waveforms organised in an array of NxT 
% N spikes each being T long
nof_spikes = size(waveforms,1); 
wavelen = size(waveforms,2);
%% Define GMM Parameters
global parameters
parameters =[];
initialize_random_seed();

% maximum number of gaussians to fit in one dimension.
parameters.maxGauss         = 8;

% maximum number of iterations of (exp maximization) EM algorithm
parameters.optgmfit.max_iter    = 10000;
parameters.optgmfit.conv_factor = 1e-6;

% number of models to calculate to check robustness
parameters.nof_replicates	= 10;

% maximum number of gaussians to overfit in multidim space. 12 for
% single-wire. 20 for tetrodes.
parameters.ngaussovfit      = 12;

%% Compute Wavelets
% 
wavetemp = waveforms;
N = floor(log2(size(wavetemp,2)));    
[aux, L] = wavedec(wavetemp(1,:),N,'haar');
waveforms_WV=nan(size(wavetemp,1), length(aux));
parfor i=1:size(wavetemp,1)
    [waveforms_WV(i,:), L] = wavedec(wavetemp(i,:),N,'haar');
end
  
% zcoring the wavelet coefficients
norm_components = zscore(waveforms_WV);
norm_components(isnan(norm_components)) = 0;

nof_wv = size(waveforms_WV,2);
sep_metric = nan(nof_wv,4);
param = @(x) [Ipeak(x) Iinf(x)];

gaussMultiFitPDF=nan(nof_wv,1000);
bins=nan(nof_wv,1000);
for wavelet_i = 1:nof_wv
    
    componentvalues = norm_components(:,wavelet_i);
    ngauss = parameters.maxGauss;
    flag = 1;
    while flag
        try
            
            MultimodalFit = ...
                gm_EM(componentvalues,ngauss,...
                'options',parameters.optgmfit,...
                'replicates',parameters.nof_replicates,...
                'rep_param',param);
            
            bins(wavelet_i,:) = linspace(min(componentvalues),max(componentvalues),1000);
            gaussMultiFitPDF(wavelet_i,:) = gm_pdf(MultimodalFit,bins(wavelet_i,:)');
            sep_metric(wavelet_i,1:3) = median(MultimodalFit.param);
            
            flag = 0;
        catch errorinfo
            ngauss = ngauss-1;
            if ngauss<1
                flag = 0;
                display(errorinfo.message)
            end
        end
    end
    disp(['Computing models for each wavelet: ' ...
    num2str(round(wavelet_i*1000/nof_wv)/10) '%'])
    pause(0.01)
    
    
end

sep_metric(isnan(sep_metric)) = 0;
sep_metric(:,4) = var(waveforms_WV);

% % % % % % % % % %
% choose the separability metric to perform wPCA
I_peak=1;
I_inf=2;
I_dist=3;
Var=4;
% % % % % % % % % %

% wPCA is done in the zcored wavelet coefficients
wcomponents = repmat(sep_metric(:,I_dist)',size(norm_components,1),1).*norm_components;
wcomponents(isnan(wcomponents)) = 0;
try
    [~, wpca, ~] = pca(wcomponents);
catch e
    [~, wpca, ~] = princomp(wcomponents);
end

%the 5 wPCs are selected for clustering
Multimodel_components = 1:5;
waveforms_components = wpca(:,Multimodel_components);
nof_dimensions = length(Multimodel_components);
disp(['Clustering will be perfomed in ' num2str(nof_dimensions) ...
    ' dimension(s)'])
pause(0.01)
flag = 1;
ngaussovfit = parameters.ngaussovfit;
while flag
    try
        MultidimModel = gm_EM(waveforms_components,ngaussovfit,...
                    'options',parameters.optgmfit,...
                    'replicates',parameters.nof_replicates);
                
        flag = 0;
    catch
        ngaussovfit = ngaussovfit-1;
        if ngaussovfit <1
            disp('Not possible to fit model in multidim space')
            return
        end
    end
end

disp('Finding distribution peaks..')
pause(0.01)

if size(waveforms_components,2)==1
    peaks = MultidimModel.mu;
else
    % each Gaussian center is an initial condition to finding peaks
    putativeMultidim_peaks = MultidimModel.mu;
    
    nof_putativepeaks = size(putativeMultidim_peaks,1);
    gradient_minstep = NaN(1,nof_dimensions);
    
    % defining the minimum step for each dimension
    for d = 1 : nof_dimensions
        gradient_minstep(d) = prctile(diff(sort(waveforms_components(:,d))),1);
        % gradient_minstep(d) = 1e-8;
    end
    
    peaks = [];
    
    %%%%%
    % defining the probability of the model as an anonimous function to use
    % fminsearch
    fun_prob_x = @(x) -sum(exp(gm_ll(x,MultidimModel.mu,MultidimModel.S,MultidimModel.alpha)),1);
    %%%%%
    
    for p = 1 : nof_putativepeaks
        % Nelder-Mead algorithm
        current_coord = putativeMultidim_peaks(p,:);
        [x_local_max,fval] = fminsearch(fun_prob_x, current_coord,...
            optimset('TolX',1e-8,'TolFun',1e-8));
        peaks = [peaks; x_local_max];
    end
    
    %normalizing peaks and excluding repeated ones..
    peaks_norm = peaks;
    for d = 1 : nof_dimensions
        peaks_norm(:,d) = round(peaks(:,d)/(5*gradient_minstep(d)));
    end
    [~,centersid]       = unique(peaks_norm,'rows');
    peaks               = peaks(centersid,:);

end

nof_cluster = size(peaks,1);
disp([num2str(nof_cluster) ' clusters detected.'])
pause(0.01)

%% Clustering using the fixed-mean GMM
disp('Clustering...')
    
% Structure telling which parameters are fixed.. in this case, the mean of
% the Gaussians. Can also work fixing S or alpha.
S = struct('mu',peaks,'S',[],'alpha',[]);

ClusteringModel = gm_EM(waveforms_components,nof_cluster,...
                'options',parameters.optgmfit,...
                'replicates',parameters.nof_replicates,...
                'fixed_param',S);
[~,cluster_probability] = gm_pdf(ClusteringModel,waveforms_components);

% defining the cluster identity of each spike according to the Gaussian
% with higher probability
[~,id_cluster] = max(cluster_probability,[],2);

if size(cluster_probability,2) ~= nof_cluster
    nof_cluster = size(cluster_probability,2);
end


% computing the entropy of the classes.. this is not used in the interface,
% but can be used to implement a threshold to select only spikes that have
% low overlap of gaussians..
classification_uncertainty = NaN(nof_spikes,1);
for s = 1 : nof_spikes
    classification_uncertainty(s) = 0;
    for c = 1 : nof_cluster
        classification_uncertainty(s) =   classification_uncertainty(s)                                ...
            + (-sum(cluster_probability(s,c)*log2(cluster_probability(s,c) ...
            + ~cluster_probability(s,c))));
    end
end

%%
clusterlabels = unique(id_cluster);

id_cluster_aux = id_cluster;
for clus_i = 1:length(clusterlabels)
    id_cluster_aux(id_cluster==clusterlabels(clus_i)) = clus_i;
end
id_cluster = id_cluster_aux;
end
