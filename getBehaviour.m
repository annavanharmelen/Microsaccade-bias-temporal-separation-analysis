clear all
close all
clc

%% set parameters and loops
display_percentage_ok = 1;
plot_individuals = 1;
plot_averages = 0;

pp2do = [2:9];
p = 0;

[bar_size, bright_colours, colours, light_colours, SOA_colours, dark_colours, subplot_size, labels, percentageok, overall_dt, overall_error] = setBehaviourParam(pp2do);

for pp = pp2do
    p = p+1;
    ppnum(p) = pp;
    figure_nr = 1;
    
    param = getSubjParam(pp);
    disp(['getting data from ', param.subjName]);
    
    %% load actual behavioural data
    behdata = readtable(param.log);

    %% check percentage oktrials
    % select trials with reasonable decision times
    oktrials = abs(zscore(behdata.idle_reaction_time_in_ms))<=3; 
    percentageok(p) = mean(oktrials)*100;
  
    % display percentage unbroken trials
    if display_percentage_ok
        fprintf('%s has %.2f%% unbroken trials\n\n', param.subjName, percentageok(p,1))
    end
    %% basic data checks, each pp in own subplot
    if plot_individuals
        figure(figure_nr);
        figure_nr = figure_nr+1;
        subplot(subplot_size,subplot_size,p);
        h = histogram(behdata.idle_reaction_time_in_ms,50);
        title(['decision time - pp ', num2str(pp2do(p))]);
        ylim([0 200]);

        figure(figure_nr);
        figure_nr = figure_nr+1;
        subplot(subplot_size,subplot_size,p);
        h = histogram(behdata.response_time_in_ms, 50);
        title(['response time - pp ', num2str(pp2do(p))]);
        xlim([0 5010]);
        ylim([0 150]);
        
        figure(figure_nr);
        figure_nr = figure_nr+1;
        subplot(subplot_size,subplot_size,p);
        h = histogram(behdata.rgb_distance,50);       
        title(['colour error abs - pp ', num2str(pp2do(p))]);
        xlim([0 180]);
        ylim([0 150]);
        
        figure(figure_nr);
        figure_nr = figure_nr+1;
        subplot(subplot_size,subplot_size,p);
        h = histogram(behdata.rgb_distance_signed,50);     
        title(['colour error signed - pp ', num2str(pp2do(p))]);
        xlim([-180 180]);
        ylim([0 150]);

        figure(figure_nr);
        figure_nr = figure_nr+1;
        subplot(subplot_size,subplot_size,p);
        h = histogram(str2double(erase(behdata.selected_colour,["[", ", 0.2, 0.5]"])), 360);
        colour_responses(p,:) = h.Values;
        title(['responded colours - pp ', num2str(pp2do(p))]);
        xlim([0 360]);
        ylim([0 12]);
    end

    
    %% trial selections
    left_trials = ismember(behdata.target_position, {'left'});
    right_trials = ismember(behdata.target_position, {'right'});

    first_target_trials = behdata.target_item == 1;
    second_target_trials = behdata.target_item == 2;

    same_side_trials = ismember(behdata.condition_code, [11,12,17,18,111,112,117,118]);
    other_side_trials = ismember(behdata.condition_code, [13,14,15,16,113,114,115,116]);

    cue_1 = ismember(behdata.retrocue, [1]);
    cue_2 = ismember(behdata.retrocue, [2]);
    cue_0 = ismember(behdata.retrocue, [0]);
    cue_any = ismember(behdata.retrocue, [1,2]);

  
    %% extract data of interest
    overall_dt(p,1) = mean(behdata.idle_reaction_time_in_ms(oktrials), "omitnan");
    overall_rt(p,1) = mean(behdata.response_time_in_ms(oktrials), "omitnan");
    overall_abs_error(p,1) = mean(behdata.rgb_distance(oktrials), "omitnan");
    overall_error(p,1) = mean(behdata.rgb_distance_signed(oktrials), "omitnan");
    
    sharepos_labels = {'same side', 'other side'};

    % get decision and response time as function of co-occupying same space
    dt_sharepos(p,1) = mean(behdata.idle_reaction_time_in_ms(same_side_trials&oktrials), "omitnan");
    dt_sharepos(p,2) = mean(behdata.idle_reaction_time_in_ms(other_side_trials&oktrials), "omitnan");

    rt_sharepos(p,1) = mean(behdata.response_time_in_ms(same_side_trials&oktrials), "omitnan");
    rt_sharepos(p,2) = mean(behdata.response_time_in_ms(other_side_trials&oktrials), "omitnan");
    
    % get error as function of co-occupying same space
    error_sharepos(p,1) = mean(behdata.rgb_distance(same_side_trials&oktrials), "omitnan");
    error_sharepos(p,2) = mean(behdata.rgb_distance(other_side_trials&oktrials), "omitnan");
    
    cue_labels = {'cue1', 'cue2', 'cue0', 'cue_any'};

    % get decision and response time as function of cue
    dt_cue(p,1) = mean(behdata.idle_reaction_time_in_ms(cue_1&oktrials), "omitnan");
    dt_cue(p,2) = mean(behdata.idle_reaction_time_in_ms(cue_2&oktrials), "omitnan");
    dt_cue(p,3) = mean(behdata.idle_reaction_time_in_ms(cue_0&oktrials), "omitnan");
    dt_cue(p,4) = mean(behdata.idle_reaction_time_in_ms(cue_any&oktrials), "omitnan");

    rt_cue(p,1) = mean(behdata.response_time_in_ms(cue_1&oktrials), "omitnan");
    rt_cue(p,2) = mean(behdata.response_time_in_ms(cue_2&oktrials), "omitnan");
    rt_cue(p,3) = mean(behdata.response_time_in_ms(cue_0&oktrials), "omitnan");
    rt_cue(p,4) = mean(behdata.response_time_in_ms(cue_any&oktrials), "omitnan");
    
    % get error as function of cue
    error_cue(p,1) = mean(behdata.rgb_distance(cue_1&oktrials), "omitnan");
    error_cue(p,2) = mean(behdata.rgb_distance(cue_2&oktrials), "omitnan");
    error_cue(p,3) = mean(behdata.rgb_distance(cue_0&oktrials), "omitnan");
    error_cue(p,4) = mean(behdata.rgb_distance(cue_any&oktrials), "omitnan");

end

if plot_averages
 %% check performance
    figure;
    figure_nr = figure_nr+1;
    subplot(5,1,1);
    bar(ppnum, overall_dt(:,1));
    title('overall decision time');
    xlabel('pp #');

    subplot(5,1,2);
    bar(ppnum, overall_rt(:,1));
    title('overall response time');
    xlabel('pp #');

    subplot(5,1,3);
    bar(ppnum, overall_error(:,1));
    title('overall error');
    xlabel('pp #');

    subplot(5,1,4);
    hold on
    bar(ppnum, overall_abs_error(:,1));
    title('overall abs error');
    xlabel('pp #');

    subplot(5,1,5);
    bar(ppnum, percentageok);
    title('percentage ok trials');
    ylim([90 100]);
    xlabel('pp #');
    
    %% effect of cue on behaviour
    figure(figure_nr);
    figure_nr = figure_nr+1;

    subplot(1,3,1)
    hold on
    bar(mean(dt_cue, 1));
    plot(dt_cue', 'k');
    xticks([1,2,3,4]);
    xticklabels(cue_labels)
    ylabel('Decision time (ms)');
    
    subplot(1,3,2)
    hold on
    bar(mean(rt_cue, 1));
    plot(rt_cue', 'k');
    xticks([1,2,3,4]);
    xticklabels(cue_labels)
    ylabel('Response time (ms)');

    subplot(1,3,3)
    hold on
    bar(mean(error_cue, 1));
    plot(error_cue', 'k');
    xticks([1,2,3,4]);
    xticklabels(cue_labels)
    ylabel('Reproduction error, abs (deg)');

    %% effect of co-occupying same space on behaviour
    figure(figure_nr);
    figure_nr = figure_nr+1;

    subplot(1,3,1)
    hold on
    bar(mean(dt_sharepos, 1));
    plot(dt_sharepos', 'k');
    xticks([1,2]);
    xticklabels(sharepos_labels)
    ylabel('Decision time (ms)');
    
    subplot(1,3,2)
    hold on
    bar(mean(rt_sharepos, 1));
    plot(rt_sharepos', 'k');
    xticks([1,2]);
    xticklabels(sharepos_labels)
    ylabel('Response time (ms)');

    subplot(1,3,3)
    hold on
    bar(mean(error_sharepos, 1));
    plot(error_sharepos', 'k');
    xticks([1,2]);
    xticklabels(sharepos_labels)
    ylabel('Reproduction error, abs (deg)');

    %% Is there clustering of colours?
    for deg = 1:360
        colours(deg,1) = deg / 360;
        colours(deg,2) = 1; %was 0.2 in exp
        colours(deg,3) = 1; %was 0.5 in exp
    end

    figure(figure_nr);
    figure_nr = figure_nr+1;

    patch([1:360 nan],[mean(colour_responses) nan],[1:360 nan],[1:360 nan], 'edgecolor', 'interp')
    colormap(hsv2rgb(colours));
    ylabel('n responded');
    xlabel('colour (deg)');


end
