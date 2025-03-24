%% Step3-- gaze-shift calculation

%% start clea
clear; clc; close all;

%% parameter
oneOrTwoD  = 1;
oneOrTwoD_options = {'_1D','_2D'};

plotResults = 0;

%% loop over participants
for pp = [13:21];

    %% load epoched data of this participant data
    param = getSubjParam(pp);
    load([param.path, '\epoched_data\eyedata_m3', '__', param.subjName], 'eyedata');

    %% only keep channels of interest
    cfg = [];
    cfg.channel = {'eyeX','eyeY'}; % only keep x & y axis
    eyedata = ft_selectdata(cfg, eyedata); % select x & y channels

    %% reformat all data to a single matrix of trial x channel x time
    cfg = [];
    cfg.keeptrials = 'yes';
    tl = ft_timelockanalysis(cfg, eyedata); % realign the data: from trial*time cells into trial*channel*time?
    tl.time = tl.time * 1000;

    %% pixel to degree
    [dva_x, dva_y] = frevede_pixel2dva(squeeze(tl.trial(:,1,:)), squeeze(tl.trial(:,2,:)));
    tl.trial(:,1,:) = dva_x;
    tl.trial(:,2,:) = dva_y;

    %% selection vectors for conditions -- this is where it starts to become interesting!
    % select possible target locations
    targL = ismember(tl.trialinfo(:,1), [31,32,33,36,311,312,313,316]);
    targR = ismember(tl.trialinfo(:,1), [34,35,37,38,314,315,317,318]);
    
    % cue can be many different things
    cueL = ismember(tl.trialinfo(:,1), [31,32,33,36]);
    cueR = ismember(tl.trialinfo(:,1), [34,35,37,38]);
    cue0 = ismember(tl.trialinfo(:,1), [311:318]);
    cue1 = ismember(tl.trialinfo(:,1), [31,33,35,37]);
    cue2 = ismember(tl.trialinfo(:,1), [32,34,36,38]);
      
    % when was target presented
    targ1 = ismember(tl.trialinfo(:,1), [31,33,35,37,311,313,315,317]);
    targ2 = ismember(tl.trialinfo(:,1), [32,34,36,38,312,314,316,318]);
    
    % same side or not
    same_side = ismember(tl.trialinfo(:,1), [31,32,37,38,311,312,317,318]);
    other_side = ismember(tl.trialinfo(:,1), [33,34,35,36,313,314,315,316]);

    % channels
    chX = ismember(tl.label, 'eyeX');
    chY = ismember(tl.label, 'eyeY');

    %% get gaze shifts using our custom function
    cfg = [];
    data_input = squeeze(tl.trial);
    time_input = tl.time;

    [shiftsX,shiftsY, peakvelocity, times] = PBlab_gazepos2shift_2D(cfg, data_input(:,chX,:), data_input(:,chY,:), time_input);

    %% select usable gaze shifts
    minDisplacement = 0;
    maxDisplacement = 1000;

    if oneOrTwoD == 1
        saccadesize = abs(shiftsX);
    elseif oneOrTwoD == 2
        saccadesize = abs(shiftsX+shiftsY*1i);
    end

    shiftsL = shiftsX<0 & (saccadesize>minDisplacement & saccadesize<maxDisplacement);
    shiftsR = shiftsX>0 & (saccadesize>minDisplacement & saccadesize<maxDisplacement);

    %% get relevant contrasts out
    saccade = [];
    saccade.time = times;
    sel = ones(size(cueL)); %NB: selection of oktrials has happened at the start when remove_unfixated is "on".
    saccade.label = {'all','cueL','cueR','cue0','cue1','cue2','cueany','same_side_0','other_side_0','same_side_any','other_side_any'};

    for selection = [1:11] % conditions.
        if     selection == 1  sel = ones(size(targL));
        elseif selection == 2  sel = cueL;
        elseif selection == 3  sel = cueR;
        elseif selection == 4  sel = cue0;
        elseif selection == 5  sel = cue1;
        elseif selection == 6  sel = cue2;
        elseif selection == 7  sel = logical(cue1+cue2);
        elseif selection == 8  sel = same_side&cue0;
        elseif selection == 9  sel = other_side&cue0;
        elseif selection == 10  sel = same_side&logical(cue1+cue2);
        elseif selection == 11  sel = other_side&logical(cue1+cue2);
        end
        
        if selection == 2
            saccade.toward(selection,:) =  mean(shiftsL(sel,:));
            saccade.away(selection,:)  =   mean(shiftsR(sel,:));
        elseif selection == 3
            saccade.toward(selection,:) =  mean(shiftsR(sel,:));
            saccade.away(selection,:)  =   mean(shiftsL(sel,:));
        else
            saccade.toward(selection,:) =  (mean(shiftsL(targL&sel,:)) + mean(shiftsR(targR&sel,:))) ./ 2;
            saccade.away(selection,:)  =   (mean(shiftsL(targR&sel,:)) + mean(shiftsR(targL&sel,:))) ./ 2;
        end
    end

    % add towardness field
    saccade.effect = (saccade.toward - saccade.away);
    
    %% smooth and turn to Hz
    integrationwindow = 100; % window over which to integrate saccade counts
    
    saccade.toward = smoothdata(saccade.toward,2,'movmean',integrationwindow)*1000; % *1000 to get to Hz, given 1000 samples per second.
    saccade.away   = smoothdata(saccade.away,2,  'movmean',integrationwindow)*1000;
    saccade.effect = smoothdata(saccade.effect,2,'movmean',integrationwindow)*1000;
       
    %% plot
    if plotResults
        figure; 
        hold on
        plot(saccade.time, saccade.toward(1,:,:), 'b');
        plot(saccade.time, saccade.away(1,:,:), 'r');
        plot(saccade.time, saccade.effect(1,:,:), 'k');
        title('Main effect');
        hold off

        figure; 
        hold on
        plot(saccade.time, saccade.toward(4,:,:), 'b');
        plot(saccade.time, saccade.away(4,:,:), 'r');
        plot(saccade.time, saccade.effect(4,:,:), 'k');
        title('Effect of null cue');
        hold off
        
        figure; 
        hold on
        plot(saccade.time, saccade.toward(7,:,:), 'b');
        plot(saccade.time, saccade.away(7,:,:), 'r');
        plot(saccade.time, saccade.effect(7,:,:), 'k');
        title('Effect of any cue');
        hold off

        figure;
        hold on
        plot(saccade.time, saccade.effect(5,:,:), 'c');
        plot(saccade.time, saccade.effect(6,:,:), 'm');
        title('First vs. second item - effect');
        legend(saccade.label(5:6));
        hold off
    end

    %% also get as function of saccade size - identical as above, except with extra loop over saccade size.
    binsize = 0.5;
    halfbin = binsize/2;

    saccadesize = [];
    saccadesize.dimord = 'chan_freq_time';
    saccadesize.freq = halfbin:0.1:7-halfbin; % shift sizes, as if "frequency axis" for time-frequency plot
    saccadesize.time = times;
    saccadesize.label = saccade.label;

    c = 0;
    for sz = saccadesize.freq;
        c = c+1;
        
        shiftsL = [];
        shiftsR = [];
        shiftsL = shiftsX<-sz+halfbin & shiftsX > -sz-halfbin; % left shifts within this range
        shiftsR = shiftsX>sz-halfbin  & shiftsX < sz+halfbin; % right shifts within this range

        for selection = [1:11] % conditions.
            if     selection == 1  sel = ones(size(targL));
            elseif selection == 2  sel = cueL;
            elseif selection == 3  sel = cueR;
            elseif selection == 4  sel = cue0;
            elseif selection == 5  sel = cue1;
            elseif selection == 6  sel = cue2;
            elseif selection == 7  sel = logical(cue1+cue2);
            elseif selection == 8  sel = same_side&cue0;
            elseif selection == 9  sel = other_side&cue0;
            elseif selection == 10  sel = same_side&logical(cue1+cue2);
            elseif selection == 11  sel = other_side&logical(cue1+cue2);
            end
            
            if selection == 2
                saccadesize.toward(selection,c,:) =  mean(shiftsL(sel,:));
                saccadesize.away(selection,c,:)  =   mean(shiftsR(sel,:));
            elseif selection == 3
                saccadesize.toward(selection,c,:) =  mean(shiftsR(sel,:));
                saccadesize.away(selection,c,:)  =   mean(shiftsL(sel,:));
            else
                saccadesize.toward(selection,c,:) = (mean(shiftsL(targL&sel,:)) + mean(shiftsR(targR&sel,:))) ./ 2;
                saccadesize.away(selection,c,:) =   (mean(shiftsL(targR&sel,:)) + mean(shiftsR(targL&sel,:))) ./ 2;
            end
        end

    end
   
    % add towardness field
    saccadesize.effect = (saccadesize.toward - saccadesize.away);

    %% smooth and turn to Hz
    integrationwindow = 100; % window over which to integrate saccade counts
    saccadesize.toward = smoothdata(saccadesize.toward,3,'movmean',integrationwindow)*1000; % *1000 to get to Hz, given 1000 samples per second.
    saccadesize.away   = smoothdata(saccadesize.away,3,  'movmean',integrationwindow)*1000;
    saccadesize.effect = smoothdata(saccadesize.effect,3,'movmean',integrationwindow)*1000;
    
    %% plot saccadesize effects
    if plotResults
        cfg = [];
        cfg.parameter = 'effect';
        cfg.figure = 'gcf';
        cfg.zlim = [-0.5, 0.5];
        figure;
        for chan = 1:7
            cfg.channel = chan;
            subplot(3,3,chan);
            ft_singleplotTFR(cfg, saccadesize);
        end
        colormap('jet');
        drawnow;
    end

    %% save
    save([param.path, '\saved_data\saccadeEffects', oneOrTwoD_options{oneOrTwoD} '__', param.subjName], 'saccade','saccadesize');
    %% close loops
end % end pp loop
