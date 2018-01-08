%% 2env PV silent cell vetting figures

%% Load Data
% optimal aligned data
opt_data = fullfile(ChangeDirectory_NK(G30_square(1),0),...
    '2env_PVsilent_cm4_local0-1000shuffles-2018-01-06.mat'); % '2env_PVsilent_cm4_local0-0shuffles-2018-01-03.mat' % works
% local aligned data
loc_data = fullfile(ChangeDirectory_NK(G30_square(1),0),...
    '2env_PVsilent_cm4_local1-0shuffles-2018-01-05.mat'); 

load(loc_data); Mouseloc = Mouse;
load(opt_data); %stays in Mouse variable

%% 1st plot all 4 animals PV curves for each condition (no silent cells, only 
% unambiguous silent cells, and any silent cells)

sesh_type = {'square','circle','circ2square'};
sesh_simple = {'', 'Same Arena', 'Different Arena'};

for k = 1:3; hcomb(k) = figure; end
hsep2 = figure; % Plots for silent_thresh = nan only for each mouse
for m = 1:length(sesh_type)

    hsep = figure;
    for k = 1:3% 1:3 % different silent_cell thresholds
        % Pre-allocate arrays for same vs different curves
        if ismember(k,[1 3])
            corr_simp_all = []; shuf_simp_all = [];
        end
        
        % Pre-allocate arrays for square v circle v circ2square curves
        corrs_all = []; shuf_all = []; local_all = [];
        for j = 1:length(Mouse)
            figure(hsep); hin = subplot(3,4,j + 4*(k-1)); % Ind. Mouse handle
%             if k == 1
                figure(hcomb(k)); hinc = subplot(2,2,m); hold on; % Combined handle
%             end
            if k == 1; figure(hsep2); hin2 = subplot(3,4,j+4*(m-1)); end
            
            % Make relevant variables small
            corrs_use = Mouse(j).PVcorrs.(sesh_type{m})(k).PVcorrs;
            shuf_use = Mouse(j).PVcorrs.(sesh_type{m})(k).PVshuf_corrs;
            local_use = Mouseloc(j).PVcorrs.(sesh_type{m})(k).PVcorrs;
            silent_thresh = Mouse(j).PVcorrs.(sesh_type{m})(k).silent_thresh;
            Animal_text = mouse_name_title(Mouse(j).sesh.(sesh_type{m})(1)...
                .Animal);
            
            % Plot it
            twoenv_plot_PVcurve(corrs_use, sesh_type{m}, shuf_use, hin);
            title([Animal_text ' - ' sesh_type{m} ' silent\_thresh = ' ...
                num2str(silent_thresh)]);
            make_plot_pretty(gca);
            
            % Same as above but only for silent_thresh = nan and all mice
            % on one plot
            if k == 1
                twoenv_plot_PVcurve(corrs_use, sesh_type{m}, shuf_use, hin2);
                title([Animal_text ' - ' sesh_type{m}])
                make_plot_pretty(gca);
                set(gca,'XTick',0:7,'YLim',[-0.3 0.7])
                if j == 1 && m == 1
                    text(4,0.5,'Silent = nan')
                end
            end
            
            
            % Don't plot curves on combined/simple plots - wait for mean of all later
            twoenv_plot_PVcurve(corrs_use, sesh_type{m}, shuf_use, hinc,...
                false); hold on
%             twoenv_plot_PVcurve(corrs_use, sesh_type{m}, shuf_use, hins,...
%                 false); hold on

            % Aggregate each mouse's correlations together
            corrs_all = cat(3, corrs_all, corrs_use);
            shuf_all = cat(3, shuf_all, shuf_use);
            local_all = cat(3,local_all, local_use);
            
        end
        
        % Get simple mouse mean and plot
        corrs_mean = nanmean(corrs_all,3);
        [~, unique_lags_all{m,k}, mean_PVcorr_all{m,k},~, CI{m,k}, day_lag_all{m,k}] = ...
            twoenv_plot_PVcurve(corrs_mean, sesh_type{m}, shuf_all, hinc,...
            true); hold off
        title(['Combined - ' sesh_type{m} ' silent\_thresh = ' ...
            num2str(silent_thresh)]);
        make_plot_pretty(gca);
               
        % Get local aligned correlations for later comparison
        local_mean = nanmean(local_all,3);
        [~, ~, mean_PVlocal_all{m,k}, ~, ~] = ...
            twoenv_plot_PVcurve(local_mean, sesh_type{m}, [], 'dont_plot', true);
            
    end
end

for k = 1:3
    silent_thresh = Mouse(j).PVcorrs.(sesh_type{1})(k).silent_thresh;
    figure(hcomb(k)); subplot(2,2,4); 
    text(0.2,0.5,['Silent = ' num2str(silent_thresh)]);
    axis off
end
%% Plot same env overlap and different env overlap
load(opt_data);
silent_thresh_array = [nan 0 1];
figure(602); set(gcf,'Position',[2150 20 1400 940]);
pt_colors = [0 0 0; 0 0 0; 1 0 0];
for silent_ind = 1:3% 1:3
    silent_thresh = silent_thresh_array(silent_ind);
    hs = subplot(2,2,silent_ind);
    
    % First plot individual data points (means of each session-pair for all
    % 4 mice)
    hold on; 
    for k = 1:3
        [xout, grpsout] = scatterbox_reshape(mean_PVcorr_all{k,silent_ind}, ...
            unique_lags_all{k,silent_ind});
        [~, ~, hscat(k)] = scatterBox(xout, grpsout, 'plotBox', false, 'h', hs,...
            'circleColors', pt_colors(k,:), 'sf', 0.02);
    end
    
    % Now plot curves with error bars (sem)
    same_env = cellfun(@(a,b) [a; b], mean_PVcorr_all{1,silent_ind}, ...
        mean_PVcorr_all{2,silent_ind},'UniformOutput',false);
    diff_env = mean_PVcorr_all{3,silent_ind};
    local_same_env = cellfun(@(a,b) [a; b], mean_PVlocal_all{1,silent_ind}, ...
        mean_PVlocal_all{2,silent_ind},'UniformOutput',false);
    
    h1 = errorbar(unique_lags_all{1,silent_ind}, cellfun(@mean, same_env), ...
        cellfun(@std, same_env)./sqrt(cellfun(@length, same_env)), 'k.-');
    hold on
    h2 = errorbar(unique_lags_all{3,silent_ind}, cellfun(@mean, diff_env), ...
        cellfun(@std, diff_env)./sqrt(cellfun(@length, diff_env)), 'r.-');
    h3 = errorbar(unique_lags_all{1,silent_ind}, cellfun(@mean, local_same_env), ...
        cellfun(@std, local_same_env)./sqrt(cellfun(@length, local_same_env)), 'c.--');
    xlabel('Day lag')
    ylabel('Mean PV correlation')
    title(['PV Correlations - silent\_thresh = ' num2str(silent_thresh)])
    xlim([-0.5 7.5]); % ylim([-0.1 0.7])
    
    % Hack to get mean CIs from all three comparisons
    n = 1;
    CIalltemp = cat(2,cat(1,unique_lags_all{:,silent_ind}), ...
        cat(1,CI{:,silent_ind})); % 1st col = lags, 2/3 = max/min CI at each lag
    CIplot = nan(8,2);
    for ll = 0:7
       CIplot(n,:) = nanmean(CIalltemp(CIalltemp(:,1) == ll,2:3),1);
       n = n+1;
    end
    
    hshufline = plot((0:7)', CIplot(:,1), 'Color', [1 0 1 0.7], 'LineStyle', ':');
    legend(cat(1,h1,h2,h3,hshufline), {'Same Arena', 'Different Arena', ...
        'Local Aligned', 'Shuffled'})
    make_plot_pretty(gca)

end
subplot(2,2,4)
text(0.2,0.8,['Lccal aligned = ' ...
    num2str(Mouse(1).PVcorrs.square(1).local_aligned) ' for subplot 1'])
text(0.2,0.65, 'Local aligned = 0 for subplot 2 and 3')
text(0.2,0.5, 'Silent thresh = nan -> no silent cells included')
text(0.2,0.35, 'Silent thresh = 0 -> only silent cells with non-overlapping ROIs included')
text(0.2,0.2, 'Silent thresh = 1 -> all silent cells included')

axis off

%%

%% Code to get pval for PV correlation vs shuffled
% 1 - sum(Mouse(1).PVcorrs.square.PVcorrs - ...
%     Mouse(1).PVcorrs.square.PVshuf_corrs > 0,3)/num_shuffles;
