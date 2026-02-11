%% Manual Rotation Determination for Image Analysis

% Initialize or reset environment
reload = true;
if reload
    close all; clear; reload = true; % Ensure a clean workspace for the operation
end

%% User-Defined Parameters
% Path to the configuration JSON file
mainconfigname = 'config_example_cc';
configdir = 'C://Users/zinke/Documents/GitHub/microfluidics-image-processing/CC_pipeline/';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% end of user defined parameters %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Configuration and Metadata Loading
% Load configuration from JSON
if ~endsWith(mainconfigname, '.json')
    % If it does not, append '.json' to 'mainconfigname'
    mainconfigname = [mainconfigname, '.json'];
end
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

% Load and preProcess metadata table
metaname = fullfile(masterdir, metacsv);
meta = preProcessMetaTable(metaname);

% Check and proceed only if rotation angles need determination
% Logical array where true indicates a valid entry
validEntries = ~isnan(meta.rotangle) & meta.rotangle >= -360 & meta.rotangle <= 360;

% Check if all entries in 'rotangle' are valid
allValid = all(validEntries);

if allValid
    msgbox('Rotation angle for all replicates recorded.', 'Success')
    return
end

% get current script path to find the bioformats reader
currentScriptPath = fileparts(mfilename('fullpath'));
% Go up one level to the repository root
repoRoot = fileparts(currentScriptPath);
% Construct the path to the helper functions
helperFunctionsPath = fullfile(repoRoot, 'MM_pipeline', 'helperfunctions', 'bfmatlab');
% Add the path
addpath(genpath(helperFunctionsPath));

%% Main Rotation Angle Determination Loop
disableWarnings();

% these need to be Processed
% these need to be Processed
meta.repchip = strcat(meta.replicate,meta.chip);
allrepchip = unique(meta.repchip(~validEntries));

% set image scaling paramters
maxin_val=(2^bitdepth)-1; %max intensity values possible
thr1 = thr1*maxin_val; % min and max values for mat2gray for PH
thr2 = thr2*maxin_val; % min and max values for mat2gray for GFP
thr3 = thr3*maxin_val; % min and max values for mat2gray for RFP

for repi = 1:numel(allrepchip)   
    % get id of replicate and main directory
    repchip = string(allrepchip(repi));
   
    % get id of replicate and main directory
    meta.repchip = strcat(meta.replicate,meta.chip);
    replind = strcmp((meta.repchip), repchip);
    replicate = string(unique(meta.replicate(replind)));
    maindir = fullfile(masterdir,'raw', replicate);

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
        if ~isnan(meta.rotangle(metai)); continue; end
        
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
    % update rotation angle
meta.rotangle(replind) = prerotate;
   
   writetable(meta,...
            metaname,...
            'Delimiter', ',');
    clear r bfc bf rotangleN
    end
end
close all
% Final message indicating completion
msgbox('Rotation angle for all replicates recorded.', 'Success');

%% Supporting Functions

function meta = preProcessMetaTable(metaname)
    % Read and preProcess the metadata table
    opts = detectImportOptions(metaname);
    % Define columns and their desired types
    charColumns = {'Exclude', 'Note', 'register', 'stardist', 'stardist_fails'};
    doubleColumns = {'MaxFr', 'Process', 'StageX', 'StageY', 'PxinUmX', 'PxinUmY', 'rotangle',...
        'BarrierYincrop', 'chamberbox1', 'chamberbox2', 'chamberbox3', 'chamberbox4'};
    
    % Update VariableTypes for specified columns
    for colName = [charColumns, doubleColumns]
        colType = 'char';
        if ismember(colName, doubleColumns)
            colType = 'double';
        end
        opts.VariableTypes{strcmp(opts.VariableNames, colName)} = colType;
    end
    meta = readtable(metaname, opts);
    meta = sortrows(meta, {'replicate', 'pos'}, 'ascend');
end

function disableWarnings()
    % Disable specific MATLAB warnings
    warning('off', 'MATLAB:table:RowsAddedExistingVars');
    warning('off', 'images:imfindcircles:warnForSmallRadius');
    warning('off', 'MATLAB:MKDIR:DirectoryExists');
end