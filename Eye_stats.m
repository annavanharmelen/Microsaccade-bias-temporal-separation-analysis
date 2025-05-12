%% Script for doing stats on saccade data.
% So run those scripts first.
% by Anna, 29-04-2025
%% Saccade bias data - stats
statcfg.xax = saccade.time;
statcfg.npermutations = 1000;
statcfg.clusterStatEvalaluationAlpha = 0.05;
statcfg.nsub = s;
statcfg.statMethod = 'montecarlo';
%statcfg.statMethod = 'analytic';

timeframe = [701:1701]; %this is 0 to 1000 ms post-cue

data_cond1 = d3(:,10,timeframe); %cue_any same side
data_cond2 = d3(:,11,timeframe); %cue_any other side
null_data = zeros(size(data_cond1));

stat = frevede_ftclusterstat1D(statcfg, data_cond1, data_cond2);
stat1 = frevede_ftclusterstat1D(statcfg, data_cond1, null_data);
stat2 = frevede_ftclusterstat1D(statcfg, data_cond2, null_data);

%% Saccade bias data - plot all effects
mask_1_vs_2 = double(stat.mask);
mask_1_vs_2(mask_1_vs_2==0) = nan; % nan data that is not part of mask

mask_1 = double(stat1.mask);
mask_1(mask_1==0) = nan; % nan data that is not part of mask 

mask_2 = double(stat2.mask);
mask_2(mask_2==0) = nan; % nan data that is not part of mask 

figure;
hold on
p1 = frevede_errorbarplot(saccade.time, squeeze(d3(:,10,:)), 'r', 'se');
p2 = frevede_errorbarplot(saccade.time, squeeze(d3(:,11,:)), 'm', 'se');
p1.LineWidth = 2.5;
p2.LineWidth = 2.5;
sig = plot(saccade.time(timeframe), mask_1_vs_2*-0.15, 'Color', 'k', 'LineWidth', 5); % verticaloffset for positioning of the "significance line"
sig_1 = plot(saccade.time(timeframe), mask_1*-0.16, 'Color', 'r', 'LineWidth', 5);
sig_2 = plot(saccade.time(timeframe), mask_2*-0.17, 'Color', 'm', 'LineWidth', 5);

xlim(xlimtoplot);
plot(xlim, [0,0], '--', 'LineWidth',2, 'Color', [0.6, 0.6, 0.6]);
plot([0,0], ylim, '--', 'LineWidth',2, 'Color', [0.6, 0.6, 0.6]);
legend([p1, p2], saccade.label(10:11));
ylabel('Saccade bias (ΔHz)');
xlabel('Time (ms)');
xlabel('Time (ms)');
hold off
