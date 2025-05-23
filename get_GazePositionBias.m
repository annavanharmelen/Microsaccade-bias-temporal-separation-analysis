%% Step2--Gaze position calculation

%% start clean
clear; clc; close all;

%% parameters
for pp = [1:27];

baselineCorrect     = 0; 
removeTrials        = 0; % remove trials where gaze deviation larger than value specified below. Only sensible after baseline correction!
max_eye_pos         = 2; % remove trials with x_position bigger than 2 degrees visual angle

plotResults         = 0;

%% load epoched data of this participant
param = getSubjParam(pp);
load([param.path, '\epoched_data\eyedata_m3_','_'  param.subjName], 'eyedata');

%% only keep channels of interest
cfg = [];
cfg.channel = {'eyeX','eyeY'}; % only keep x & y axis
eyedata = ft_selectdata(cfg, eyedata); % select x & y channels

%% reformat such that all data in single matrix of trial x channel x time
cfg = [];
cfg.keeptrials = 'yes';
tl = ft_timelockanalysis(cfg, eyedata); % realign the data: from trial*time cells into trial*channel*time?
tl.time = tl.time * 1000;

% dirty hack to get proxy for blink rate
tl.blink = squeeze(isnan(tl.trial(:,1,:))*100); % 0 where not nan, 1 where nan (putative blink, or eye close etc.)... *100 to get to percentage of trials where blink at that time

%% baseline correct?
if baselineCorrect
    tsel = tl.time >= -250 & tl.time <= 0; 
    bl = squeeze(mean(tl.trial(:,:,tsel),3));
    for t = 1:length(tl.time);
        tl.trial(:,:,t) = ((tl.trial(:,:,t) - bl));
    end
end

%% pixel to degree
[dva_x, dva_y] = frevede_pixel2dva(squeeze(tl.trial(:,1,:)), squeeze(tl.trial(:,2,:)));
tl.trial(:,1,:) = dva_x;
tl.trial(:,2,:) = dva_y;

%% remove trials with gaze deviation >= 2 dva
chX = ismember(tl.label, 'eyeX');
chY = ismember(tl.label, 'eyeY');

if plotResults
figure;
plot(tl.time, squeeze(tl.trial(:,chX,:)));
title('all trials - full time range');
end

if removeTrials
    tsel = tl.time>= 0 & tl.time <=3200; % only check within this time range of interest
    
    figure;
    subplot(1,2,1);
    plot(tl.time(tsel), squeeze(tl.trial(:,chX,tsel)));
    title('before');
    
    for trl = 1:size(tl.trial,1)
        oktrial(trl) = sum(sqrt(abs(tl.trial(trl,chX,tsel)).^2 + abs(tl.trial(trl,chY,tsel)).^2  ) > max_eye_pos) ==0;
    end
    tl.trial = tl.trial(oktrial,:,:);
    tl.trialinfo = tl.trialinfo(oktrial,:);

    subplot(1,2,2);
    plot(tl.time(tsel), squeeze(tl.trial(:,chX,tsel)));
    title('after');
    proportionOK(pp) = mean(oktrial)*100;
    fprintf('%s has %.2f%% OK trials\n\n', param.subjName, mean(oktrial)*100)

end

%% selection vectors for conditions -- this is where it starts to become interesting!
% target item locations
targL = ismember(tl.trialinfo(:,1), [31,32,33,36,311,312,313,316]);
targR = ismember(tl.trialinfo(:,1), [34,35,37,38,314,315,317,318]);

% cue locations and cue orders
cueL = ismember(tl.trialinfo(:,1), [31,32,33,36]);
cueR = ismember(tl.trialinfo(:,1), [34,35,37,38]);
cue0 = ismember(tl.trialinfo(:,1), [311:318]);
cue1 = ismember(tl.trialinfo(:,1), [31,33,35,37]);
cue2 = ismember(tl.trialinfo(:,1), [32,34,36,38]);
  
% target order
targ1 = ismember(tl.trialinfo(:,1), [31,33,35,37,311,313,315,317]);
targ2 = ismember(tl.trialinfo(:,1), [32,34,36,38,312,314,316,318]);

% same side or not
same_side = ismember(tl.trialinfo(:,1), [31,32,37,38,311,312,317,318]);
other_side = ismember(tl.trialinfo(:,1), [33,34,35,36,313,314,315,316]);
       

%% get relevant contrasts out
gaze = [];
gaze.time = tl.time;
gaze.label = {'all','cue0','cue1','cue2','cueany','same_side_0','other_side_0','same_side_any','other_side_any'};

for selection = [1:9] % conditions.
    if     selection == 1  sel = ones(size(targL))==1;
    elseif selection == 2  sel = cue0;
    elseif selection == 3  sel = cue1;
    elseif selection == 4  sel = cue2;
    elseif selection == 5  sel = logical(cue1+cue2);
    elseif selection == 6  sel = same_side&cue0;
    elseif selection == 7  sel = other_side&cue0;
    elseif selection == 8  sel = same_side&logical(cue1+cue2);
    elseif selection == 9  sel = other_side&logical(cue1+cue2);
    end
    gaze.dataL(selection,:) = squeeze(nanmean(tl.trial(sel&targL, chX,:)));
    gaze.dataR(selection,:) = squeeze(nanmean(tl.trial(sel&targR, chX,:)));
    gaze.blinkrate(selection,:) = squeeze(nanmean(tl.blink(sel, :)));
end

% add towardness field
gaze.towardness = (gaze.dataR - gaze.dataL) ./ 2;


%% plot
if plotResults
    figure;
    for sp = 1:4 subplot(2,3,sp);
        hold on;
        plot(gaze.time, gaze.dataR(sp,:), 'r');
        plot(gaze.time, gaze.dataL(sp,:), 'b');
        
        title(gaze.label(sp)); legend({'R','L'},'autoupdate', 'off');
        plot([0,0], ylim, '--k');plot([1500,1500], ylim, '--k');
    end

    figure;
    for sp = 1:4 subplot(2,3,sp);
        hold on;
        plot(gaze.time, gaze.towardness(sp,:), 'k');
        plot(xlim, [0,0], '--k');
        title(gaze.label(sp)); legend({'T'},'autoupdate', 'off');
        plot([0,0], ylim, '--k');
        plot([1500,1500], ylim, '--k');
    end

    figure;
    hold on;
    plot(gaze.time, gaze.towardness([1:4],:));
    plot(xlim, [0,0], '--k');
    legend(gaze.label([1:4]),'autoupdate', 'off');
    plot([0,0], ylim, '--k');plot([1500,1500], ylim, '--k'); 

    figure;
    hold on;
    plot(gaze.time, gaze.blinkrate([1:4],:)); plot(xlim, [0,0], '--k');
    legend(gaze.label([1:4]),'autoupdate', 'off'); plot([0,0], ylim, '--k');
    plot([1500,1500], ylim, '--k'); title('blinkrate');
end

%% save
if baselineCorrect == 1     toadd1 = '_baselineCorrect';    else toadd1 = ''; end; % depending on this option, append to name of saved file.    
if removeTrials == 1        toadd2 = '_removeTrials';       else toadd2 = ''; end; % depending on this option, append to name of saved file.    

save([param.path, '\saved_data\gazePositionEffects', toadd1, toadd2, '__', param.subjName], 'gaze');

drawnow; 

%% close loops
end % end pp loop
