
%% Step2b--grand average plots of gaze-position results

%% start clean
clear; clc; close all;

%% parameters
pp2do = setdiff(1:27,[1,4]);

nsmooth             = 200;
baselineCorrect     = 0;
removeTrials        = 0; % use data with removed trials based on gaze deviation from baseline

plotSinglePps       = 1;
plotGAs             = 1;
xlimtoplot          = [-500 3200];

colours = [72, 224, 176;...
           104, 149, 238;...
           251, 129, 81;...
           223, 52, 163];
colours = colours/255;

ft_size = 26;

%% load and aggregate the data from all pp
s = 0;
for pp = pp2do;
    s = s+1;

    % get participant data
    param = getSubjParam(pp);

    % load
    disp(['getting data from participant ', param.subjName]);

    if baselineCorrect == 1     toadd1 = '_baselineCorrect'; else toadd1 = ''; end % depending on this option, append to name of saved file.
    if removeTrials == 1        toadd2 = '_removeTrials';    else toadd2 = ''; end % depending on this option, append to name of saved file.

    load([param.path, '\saved_data\gazePositionEffects', toadd1, toadd2, '__', param.subjName], 'gaze');

    % smooth?
    if nsmooth > 0
        for x1 = 1:size(gaze.dataL,1);
            gaze.dataL(x1,:)      = smoothdata(squeeze(gaze.dataL(x1,:)), 'gaussian', nsmooth);
            gaze.dataR(x1,:)      = smoothdata(squeeze(gaze.dataR(x1,:)), 'gaussian', nsmooth);
            gaze.towardness(x1,:) = smoothdata(squeeze(gaze.towardness(x1,:)), 'gaussian', nsmooth);
            gaze.blinkrate(x1,:)  = smoothdata(squeeze(gaze.blinkrate(x1,:)), 'gaussian', nsmooth);
        end
    end

    % put into matrix, with pp as first dimension
    d1(s,:,:) = gaze.dataR;
    d2(s,:,:) = gaze.dataL;
    d3(s,:,:) = gaze.towardness;
    d4(s,:,:) = gaze.blinkrate;
end

%% make GA

%% all subs
if plotSinglePps
    % towardness
    figure;
    for sp = 1:s
        subplot(5,5,sp); hold on;
        plot(gaze.time, squeeze(d3(sp,:,:)));
        plot(xlim, [0,0], '--k');
        xlim(xlimtoplot); ylim([-.2 .2]);
        title(pp2do(sp));
    end
    legend(gaze.label);

    % blink rate
    figure;
    for sp = 1:s
        subplot(5,5,sp); hold on;
        plot(gaze.time, squeeze(d4(sp,:,:)));
        plot(xlim, [0,0], '--k');
        xlim(xlimtoplot); ylim([-20 100]);
        title(pp2do(sp));
    end
    legend(gaze.label);
end

%% plot grand average data patterns of interest, with error bars
if plotGAs
    % right and left cues, per condition
    figure;
    for sp = 1:size(d1,2)
        subplot(3,3,sp); hold on; title(gaze.label(sp));
        p1 = frevede_errorbarplot(gaze.time, squeeze(d1(:,sp,:)), [1,0,0], 'se');
        p2 = frevede_errorbarplot(gaze.time, squeeze(d2(:,sp,:)), [0,0,1], 'se');
        xlim(xlimtoplot);
    end
    legend([p1, p2], {'R','L'});
    
    % towardness per condition
    figure;
    for sp = 1:size(d3,2)
        subplot(3,3,sp); hold on; title(gaze.label(sp));
        frevede_errorbarplot(gaze.time, squeeze(d3(:,sp,:)), [0,0,0], 'both');
        plot(xlim, [0,0], '--k');
        xlim(xlimtoplot);
    end
    legend({'toward'});
    
    %% blink rate
    figure; 
    hold on;
    p1 = frevede_errorbarplot(gaze.time, squeeze(d4(:,2,:)), [1,0,0], 'se');
    p2 = frevede_errorbarplot(gaze.time, squeeze(d4(:,3,:)), [1,0,1], 'se');
    p3 = frevede_errorbarplot(gaze.time, squeeze(d4(:,4,:)), [0,0,1], 'se');
    plot(xlim, [0,0], '--k');
    plot([0,0], [-5, 30], '--k')
    legend([p1,p2,p3], gaze.label(2:4));
    xlim(xlimtoplot);

end
