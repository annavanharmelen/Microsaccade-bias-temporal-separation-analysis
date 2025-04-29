function param = getSubjParam(pp)

%% participant-specific notes

%% set path and pp-specific file locations
unique_numbers = [50,89,79,95,81,52,33,10,22,64,96,80,62,58,82,56,72,36,92,66,61,12,25,32,70,45,18]; %needs to be in the right order

param.path = '\\labsdfs.labs.vu.nl\labsdfs\FGB-ETP-CogPsy-ProactiveBrainLab\core_lab_members\Anna\Data\m3 - temporal separation\';

if pp < 10
    param.subjName = sprintf('pp0%d', pp);
else
    param.subjName = sprintf('pp%d', pp);
end

log_string = sprintf('data_session_%d.csv', pp);
param.log = [param.path, log_string];

eds_string = sprintf('%d_%d.asc', pp, unique_numbers(pp));
param.eds = [param.path, eds_string];
