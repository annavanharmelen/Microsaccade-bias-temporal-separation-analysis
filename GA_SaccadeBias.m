
%% Step3b--grand average plots of gaze-shift (saccade) results

%% start clean
clear; clc; close all;
    
%% parameters
oneOrTwoD       = 1;
oneOrTwoD_options = {'_1D','_2D'};

pp2do           = [2:9];

nsmooth         = 500;
plotSinglePps   = 0;
plotGAs         = 1;
xlimtoplot      = [-750 1500];

%% visual parameters
[bar_size, bright_colours, colours, light_colours, SOA_colours, dark_colours, subplot_size] = setBehaviourParam(pp2do);

%% load and aggregate the data from all pp
s = 0;
for pp = pp2do
    s = s+1;

    % get participant data
    param = getSubjParam(pp);

    % load
    disp(['getting data from participant ', param.subjName]);
    load([param.path, '\saved_data\saccadeEffects', oneOrTwoD_options{oneOrTwoD} '__', param.subjName], 'saccade','saccadesize');
    
    % smooth?
    if nsmooth > 0
        for i = 1:size(saccade.toward,1)
            saccade.toward(i,:)  = smoothdata(squeeze(saccade.toward(i,:)), 'gaussian', nsmooth);
            saccade.away(i,:)    = smoothdata(squeeze(saccade.away(i,:)), 'gaussian', nsmooth);
            saccade.effect(i,:)  = smoothdata(squeeze(saccade.effect(i,:)), 'gaussian', nsmooth);
        end

        %also smooth saccadesize data over time.
        for i = 1:size(saccadesize.toward,1)
            for j = 1:size(saccadesize.toward,2)
                saccadesize.toward(i,j,:) = smoothdata(squeeze(saccadesize.toward(i,j,:)), 'gaussian', nsmooth);
                saccadesize.away(i,j,:)   = smoothdata(squeeze(saccadesize.away(i,j,:)), 'gaussian', nsmooth);
                saccadesize.effect(i,j,:) = smoothdata(squeeze(saccadesize.effect(i,j,:)), 'gaussian', nsmooth);
            end
        end
    end

    % put into matrix, with pp as first dimension
    d1(s,:,:) = saccade.toward;
    d2(s,:,:) = saccade.away;
    d3(s,:,:) = saccade.effect;

    d4(s,:,:,:) = saccadesize.toward;
    d5(s,:,:,:) = saccadesize.away;
    d6(s,:,:,:) = saccadesize.effect;
end

%% make GA for the saccadesize fieldtrip structure data, to later plot as "time-frequency map" with fieldtrip. For timecourse data, we directly plot from d structures above. 
saccadesize.toward = squeeze(mean(d4));
saccadesize.away   = squeeze(mean(d5));
saccadesize.effect = squeeze(mean(d6));

%% all subs
if plotSinglePps
    % toward & away - some cue
    figure;
    for sp = 1:s
        subplot(subplot_size,subplot_size,sp); hold on;
        plot(saccade.time, squeeze(d1(sp,7,:)));
        plot(saccade.time, squeeze(d2(sp,7,:)));
        plot(xlim, [0,0], '--k');
        xlim(xlimtoplot);
        % ylim([-0.5 0.5]);
        title(pp2do(sp));
    end
    legend({'toward', 'away'});

    % toward vs away - all
    figure;
    for sp = 1:s
        subplot(subplot_size,subplot_size,sp); hold on;
        plot(saccade.time, squeeze(d3(sp,7,:)));
        plot(xlim, [0,0], '--k');
        xlim(xlimtoplot);
        % ylim([-0.5 0.5]);
        title(pp2do(sp));
    end
    legend({'all'});

    % toward vs. away - cue0 vs. cueany
    figure;
    for sp = 1:s
        subplot(subplot_size,subplot_size,sp); hold on;
        plot(saccade.time, squeeze(d3(sp,4,:)));
        plot(saccade.time, squeeze(d3(sp,7,:)));
        plot(xlim, [0,0], '--k');
        xlim(xlimtoplot);
        % ylim([-0.5 0.5]);
        title(pp2do(sp));
    end
    legend({'cue0', 'cue 1 or 2'});

    % towardness for all conditions condition - gaze shift effect X saccade size
    figure;
    for sp = 1:s
        subplot(subplot_size,subplot_size,sp);
        cfg = [];
        cfg.parameter = 'effect';
        cfg.figure = 'gcf';
        cfg.zlim = [-.1 .1];
        cfg.xlim = xlimtoplot;
        for sp = 1:s
            subplot(subplot_size,subplot_size,sp); hold on;
            saccadesize.effect = squeeze(d6(sp,:,:,:)); % put in data from this pp
            cfg.channel = 7; % all conditions combined.
            ft_singleplotTFR(cfg, saccadesize);
            title(pp2do(sp));
        end
        colormap('jet');
    end
end

%% Plot grand average data patterns of interest, with error bars
if plotGAs
    % plot toward, away and effect - all
    figure; 
    subplot(2,1,1)
    hold on
    p1 = frevede_errorbarplot(saccade.time, squeeze(d1(:,7,:)), 'b', 'se');
    p2 = frevede_errorbarplot(saccade.time, squeeze(d2(:,7,:)), 'r', 'se');
    legend([p1, p2], {'toward', 'away'});
    ylabel('Rate (Hz)');
    xlabel('Time (ms)');
    hold off
    subplot(2,1,2)
    p3 = frevede_errorbarplot(saccade.time, squeeze(d3(:,7,:)), 'k', 'se');
    plot(xlim,[0 0]);
    
    % plot main combination
    figure; 
    subplot(3,2,1)
    hold on
    p5 = frevede_errorbarplot(saccade.time, squeeze(d1(:,10,:)), 'b', 'se');
    p6 = frevede_errorbarplot(saccade.time, squeeze(d2(:,10,:)), 'r', 'se');
    legend([p5, p6], {'toward', 'away'});
    ylabel('Rate (Hz)');
    xlabel('Time (ms)');
    title('Cue not zero - same side')
    hold off

    subplot(3,2,3)
    hold on
    p5 = frevede_errorbarplot(saccade.time, squeeze(d1(:,8,:)), 'b', 'se');
    p6 = frevede_errorbarplot(saccade.time, squeeze(d2(:,8,:)), 'r', 'se');
    legend([p5, p6], {'toward', 'away'});
    ylabel('Rate (Hz)');
    xlabel('Time (ms)');
    title('Cue zero - same side')
    hold off

    subplot(3,2,5)
    hold on
    p7 = frevede_errorbarplot(saccade.time, squeeze(d3(:,8,:)), 'c', 'se');
    p8 = frevede_errorbarplot(saccade.time, squeeze(d3(:,10,:)), 'm', 'se');
    legend([p7, p8], {'cue zero', 'cue not zero'});
    plot(xlim, [0 0],'k--')
    title('effect - same side');
    hold off
    
    subplot(3,2,2)
    hold on
    p5 = frevede_errorbarplot(saccade.time, squeeze(d1(:,11,:)), 'b', 'se');
    p6 = frevede_errorbarplot(saccade.time, squeeze(d2(:,11,:)), 'r', 'se');
    legend([p5, p6], {'toward', 'away'});
    ylabel('Rate (Hz)');
    xlabel('Time (ms)');
    title('Cue not zero - other side')
    hold off

    subplot(3,2,4)
    hold on
    p5 = frevede_errorbarplot(saccade.time, squeeze(d1(:,9,:)), 'b', 'se');
    p6 = frevede_errorbarplot(saccade.time, squeeze(d2(:,9,:)), 'r', 'se');
    legend([p5, p6], {'toward', 'away'});
    ylabel('Rate (Hz)');
    xlabel('Time (ms)');
    title('Cue zero - other side')
    hold off

    subplot(3,2,6)
    hold on
    p7 = frevede_errorbarplot(saccade.time, squeeze(d3(:,9,:)), 'c', 'se');
    p8 = frevede_errorbarplot(saccade.time, squeeze(d3(:,11,:)), 'm', 'se');
    plot(xlim, [0 0],'k--')
    legend([p7, p8], {'cue zero', 'cue not zero'});
    title('effect - other side');
    hold off

    % plot the effect - cueany same vs. other side
    figure;
    hold on
    p9 = frevede_errorbarplot(saccade.time, squeeze(d3(:,10,:)), 'r', 'se');
    p10 = frevede_errorbarplot(saccade.time, squeeze(d3(:,11,:)), 'm', 'se');
    legend([p9, p10], {'cue any - same side', 'cue any - other side'});
    plot(xlim, [0 0]);
    ylabel('Hz')
    title('effect (toward vs. away) - same vs. other side (only cued)');
    hold off

    % plot the effect - cueL vs. cueR
    figure;
    hold on
    p7 = frevede_errorbarplot(saccade.time, squeeze(d3(:,2,:)), 'c', 'se');
    p8 = frevede_errorbarplot(saccade.time, squeeze(d3(:,3,:)), 'm', 'se');
    xlim(xlimtoplot);
    plot(xlim, [0,0], '--', 'LineWidth',2, 'Color', [0.6, 0.6, 0.6]);
    plot([0,0], ylim, '--', 'LineWidth',2, 'Color', [0.6, 0.6, 0.6]);
    ylabel('Rate (Hz)');
    xlabel('Time (ms)');
    hold off

    % plot the effect of zero vs. non-zero
    figure;
    subplot(3,1,1)
    hold on
    p12 = frevede_errorbarplot(saccade.time, squeeze(d3(:,4,:)), 'c', 'se');
    p13 = frevede_errorbarplot(saccade.time, squeeze(d3(:,7,:)), 'm', 'se');
    xlim([-500, 1500]);
    ylim([-0.1, 0.2]);
    plot(xlim, [0 0], 'k');
    legend([p12, p13], {'cue 0', 'cue any'});
    ylabel('Hz')
    title('effect of cueing vs not');
    hold off

    subplot(3,1,2)
    hold on
    p14 = frevede_errorbarplot(saccade.time, squeeze(d3(:,7,:)) - squeeze(d3(:,4,:)), 'k', 'se');
    xlim([-500, 1500]);
    ylim([-0.1, 0.2]);
    plot(xlim, [0 0], 'k');
    legend(p14, {'cue any - cue 0'});
    ylabel('Hz')
    title('effect of cueing - not');
    hold off

    subplot(3,1,3)
    hold on
    p15 = frevede_errorbarplot(saccade.time, squeeze(d3(:,10,:)) - squeeze(d3(:,8,:)), 'b', 'se');
    p16 = frevede_errorbarplot(saccade.time, squeeze(d3(:,11,:)) - squeeze(d3(:,9,:)), 'r', 'se');
    xlim([-500, 1500]);
    ylim([-0.1, 0.2]);
    plot(xlim, [0 0], 'k');
    legend([p15, p16], {'cue any - cue 0 (same side)', 'cue any - cue 0 (other side)'});
    ylabel('Hz')
    title('effect of cueing - not x cueing same or other sides');
    hold off

    
    %% just effect as function of saccade size
    cfg = [];
    cfg.parameter = 'effect';
    cfg.figure = 'gcf';
    cfg.zlim = [-0.1, 0.1];
    cfg.xlim = xlimtoplot;  
    cfg.colormap = 'jet';
    
    % per condition
    figure;
    for chan = [1:11]
        hold on
        cfg.channel = chan;
        subplot(3,4,chan);
        saccadesize.effect = squeeze(mean(d6(:,:,:,:))); % put in data from all pp
        ft_singleplotTFR(cfg, saccadesize);
        ylabel('Saccade size (dva)');
        xlabel('Time (ms)');
        xlim(xlimtoplot);
    end
  
end
