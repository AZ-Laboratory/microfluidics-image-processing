%% Manual prerotate Determination for Image Analysis

% Initialize or reset environment
reload = true;
if reload
    close all; clear; reload = true; % Ensure a clean workspace for the operation
end

%% Configuration File Location
% Define the name and directory for the configuration file.
% This script can be used for both the matched and mixed examples.
% Uncomment the one you are running
mainconfigname = 'config_example_matched.json';
% mainconfigname = 'jbanalysisconfig_mmrevmix.json';

configdir = 'G://GitHub/microfluidics-image-processing/MM_pipeline';

perposangle = false; %do you want to check the angle for each position seperately? Otherwise, assume per replicate the same




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% end of user defined parameters %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Configuration and Metadata Loading
% Load configuration from JSON
cfgFilePath = fullfile(configdir, mainconfigname);

% Iterate through each field in the structure
cfg = jsondecode(fileread(fullfile(configdir, mainconfigname)));
fields = fieldnames(cfg);
for i = 1:length(fields)
    fieldName = fields{i};
    fieldValue = cfg.(fieldName);

    % Assign each field to a variable in the base workspace
    assignin('base', fieldName, fieldValue);
end

% read in meta file and assign correct VariableTypes
metaname = fullfile([masterdir, filesep, metacsv]);

% Get the path of the current script
currentScriptPath = fileparts(mfilename('fullpath'));

% Construct the full path to the 'helperfunctions' subfolder
helperFunctionsPath = fullfile(currentScriptPath, 'helperfunctions');

% Temporarily add the helper functions folder to the MATLAB path
addpath(helperFunctionsPath);

meta = preprocessMetaTable(metaname);

% Check and proceed only if prerotate angles need determination
% Logical array where true indicates a valid entry
validEntries = (~isnan(meta.prerotate) & meta.prerotate >= -360 & meta.prerotate <= 360) | strcmp(meta.Exclude, 'excl');

% Check if all entries in 'prerotate' are valid
allValid = all(validEntries);

if allValid
    msgbox('prerotate angle for all replicates recorded.', 'Success')
    return
end

%% Main prerotate Angle Determination Loop
disableWarnings();

% these need to be processed

if perposangle
    meta.repchip = strcat(meta.replicate,meta.chip,num2str(meta.pos));
    allrepchip = unique(meta.repchip(~validEntries));
else
    meta.repchip = strcat(meta.replicate,meta.chip);
    allrepchip = unique(meta.repchip(~validEntries));
end


% set image scaling paramters
maxin_val=(2^bitdepth)-1; %max intensity values possible
thr1 = thr1*maxin_val; % min and max values for mat2gray for PH
thr2 = thr2*maxin_val; % min and max values for mat2gray for GFP
thr3 = thr3*maxin_val; % min and max values for mat2gray for RFP

for repi = 1:numel(allrepchip)
%     repchip = allrepchip{repi};
    repchip = string(allrepchip(repi));
    % disp(replicate)

   
    % get id of replicate and main directory
    if perposangle
        meta.repchip = strcat(meta.replicate,meta.chip,num2str(meta.pos));
    else
        meta.repchip = strcat(meta.replicate,meta.chip);
    end
    replind = strcmp((meta.repchip), repchip);
    replicate = string(unique(meta.replicate(replind)));

    % get full folder for the replicate based on the subdir names provided
    for pardi = 1:length(typedirs)
        potmaindir = fullfile(masterdir, char(typedirs(pardi)), replicate);
        if isfolder(potmaindir)
            maindir = potmaindir;
        end
    end

    cd(maindir) %set directory to main folder
    alldir=dir('_*'); %list of all dirs inside the main containing images
    

    if sum(isnan(meta.Process(replind)))==0
        procL = meta.Process(replind);
        posL = 1:size(procL,1);
    else
        procL = [];
        posL = 1:size(alldir, 1);
    end
    

    for posi=posL %go over all folders
        % if there were missing process numbers, get that now from folder name.
        % Otherwise, use that from the meta file
        if isempty(procL)
            % get process number (olympus position ID) from folder name
            dird=fullfile(maindir, alldir(posi).name, 'stack1'); %get dir of image
            procnr = str2double(extract(alldir(posi).name, digitsPattern));
            posind = replind & meta.pos == posi;
            meta.Process(posind) = procnr;
        else
            procnr = procL(posi);
            dird=fullfile(maindir, ['_Process_', num2str(procnr), '_'], 'stack1'); %get dir of image
        end
            
        % get index of current position
        metai = replind & meta.Process == procnr;
        if strcmp(meta.Exclude(metai), 'excl'); continue; end
        if strcmp(meta.register(metai), 'Done'); continue; end
        
        r = bfGetReader(char(fullfile(dird, filesep, 'frame_t_0.ets'))); %able to pull out just one image instead of entire file
        r = loci.formats.Memoizer(r);
        bf = imadjust(mat2gray(bfGetPlane(r, 1), thr1));
    
        anglcheck = 1; %run until 0
        qtxt = ['Replicate: ', char(repchip),...
            ' || Insert prerotation angle to check (-360 to 360). If you click OK without changing the number, correct angle is assumed'];
        prerotate = 0; %init
        while anglcheck
                bfc = imrotate(bf, prerotate); % apply prerotate
                imshow(bfc)
        %         next few lines are for adding a grid
                axis on;
                [rows, columns, numberOfColorChannels] = size(bfc);
                hold on;
                for row = 1 : 200 : rows
                  line([1, columns], [row, row], 'Color', 'r');
                end
                for col = 1 : 200 : columns
                  line([col, col], [1, rows], 'Color', 'r');
                end
                %get user input for angle
                % Flag to keep the loop running until valid input is received
                validInput = false;
                while ~validInput
                    prerotateN = inputdlg(qtxt, 'prerotate angle', 1, {num2str(prerotate)});
                    
                    % Check if the dialog was cancelled
                    if isempty(prerotateN)
                        disp('User cancelled the input.');
                        return; % Exit if user cancelled the input
                    else
                        prerotateN = str2double(prerotateN{1}); % Convert the input to a number
                        
                        % Check if the input is a single number, not NaN, and within the desired range
                        if ~isnan(prerotateN) && isscalar(prerotateN) && prerotateN >= -360 && prerotateN <= 360
                            validInput = true; % Input is valid, exit the loop
                        else
                            % Input is invalid, display an error message and prompt again
                            waitfor(msgbox('Invalid input. Please enter a single number between -360 and +360.', 'Error','error'));
                        end
                    end
                end
    
                if prerotateN == prerotate %if it was te same, angle is correct
                    anglcheck = 0;
                else %otherwise, update actual prerotate angle
                   prerotate = prerotateN; 
                end
        end
        % update prerotate angle
       meta = preprocessMetaTable(metaname);
       meta.prerotate(replind) = prerotate;
       writetable(meta,...
                metaname,...
                'Delimiter', ',');
        clear r bfc bf prerotateN
        % break out of pos loop. assuming same rotation for all chips per
        % replicate
        break
    end
end
close all
% Final message indicating completion
msgbox('prerotate angle for all replicates recorded.', 'Success');
