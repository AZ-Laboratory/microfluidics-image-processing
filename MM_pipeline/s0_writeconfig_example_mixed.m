% % % % WRITE CONFIG FILE FOR MOTHER-MACHINE IMAGE ANALYSIS PIPELINE % % % %

% This script generates a JSON configuration file used by various scripts
% in the mother-machine image analysis pipeline. Customize the
% parameters below to match your analysis requirements.

%% Initialization - Do not change this section
cfg = struct(); % Initialize configuration structure

%% Configuration File Location
% Define the name and directory for the configuration file.
mainconfigname = 'config_example_mixed';
configdir = 'G://GitHub/microfluidics-image-processing/MM_pipeline';

%% General Configuration Values
% Directory containing image datasets and metadata.
cfg.masterdir = 'I://Julian/agr_rev_matched/sharing/mixed'; %main directory of images (contains subfolders typedirs)

% Directory name for saving analysis results.
cfg.savedirname = 'saves';

% Name of the metadata CSV file.
cfg.metacsv = 'shared_mixed_meta_processing.csv';

%name(s) of subdirs containing images
cfg.typedirs = {'raw'};

% Number of imaging channels (e.g., 1 for phase contrast, 2+ for fluorescence).
cfg.n_channel = 2;

% Bit depth of images (e.g., 8, 16, etc).
cfg.bitdepth = 16;

%% Preprocessing Variables
% Specify positions to process (empty array [] processes all positions).
cfg.posLimpose = [];

%set to [] if you want to include all frames or use metadata specified max frame, otherwise script stops at indicated frame
cfg.maxfr = [];

%either automatic chamber selection based on circle detection (=0), manual user selection (=1) or use all chambers (=-1)
cfg.emptychamuser = 0;

% = 1 -> use only bottom 1/3 of chambers. =0 -> use entire chamber
cfg.shortenchamber = 1;

%use this rotation angle. set =[] if auto rotation detection
cfg.rotangleimpose = [];

%max absolute degrees of the auto-rotation detection. If it's higher, set angle to 0
cfg.maxrotangle = 6;

%if the blur-measurment is higher than this, discard that frame (registration fail = 1)
cfg.OOFcutoff = 1.95;

% Downsampling factors for image registration and chamber detection.
cfg.downsampleF = 0.2;
cfg.downsampleF_chamberdetect = 0.15;

%downsampled chamberwidth in downsampled px (for boundary definition), 8 to 10px works decently for D3 MM chips
cfg.chamw = 10;

%starting threshold to binarize PH images for the chamber detection algorithm
cfg.chamb_binthresh = 0.35;

% Pixel padding for chamber boundary elongation
cfg.chambelong = 12;

%save as single page tif in Folder structure: Position/Chamber/single page tifs (=0) or Position/stack per chamber (=1)
cfg.savestack = 0;

%remove chambers with high rate of OOF or registration failed
cfg.checkfailedchambers = 1;

%max proportion of failed frames for each chamber
cfg.maxfailedchamber = 0.2;

% Intensity scaling thresholds for each channel.
cfg.thr1 = [0, 1]; % For 1st channel (e.g., phase contrast)
cfg.thr2 = [0.005, 0.75]; % For 2nd channel (1st fluorescence channel)
cfg.thr3 = [0.002, 0.1]; % For 3rd channel (2nd fluorescence channel)


%% Channel Naming for Cropped Image Export
cfg.chname1 = 'Ch1'; % Name of the 1st channel
cfg.chname2 = 'Ch2'; % Name of the 2nd channel
cfg.chname3 = 'Ch3'; % Name of the 3rd channel

%% Video Creation Parameters
% Colors for fluorescence channels in the output video.
cfg.col1 = [0.15, 1.2, 0]; % Color for 1st fluorescence channel
cfg.col2 = [1, 0, 0]; % Color for 2nd fluorescence channel
cfg.col3 = [0, 0, 1]; % Color for an additional channel or overlay

% Frame rate and size for the output video.
cfg.vidfr = 15; % Video frame rate
cfg.vidsz = [1024, 1024]; % Video size [width, height]

% Option to overlay chamber boundaries on the output movie (1 = yes, 0 = no).
cfg.burn_chamb = 1;

% Option for live image display during processing.
cfg.liveimages = 0.5; % Display scaling factor (0.5 = 50% size)

%% Stardist Parameters for Cell Segmentation
cfg.stardistmodeldir = 'G://GitHub/microfluidics-image-processing/stardist_models/mm';
cfg.ramsize = 8000; % Available GPU RAM in MB
cfg.ramlimit = 0.85; % Max proportion of GPU RAM to use

%% DeLTA parameters

% modified local delta package path
cfg.deltapath = 'G://GitHub/microfluidics-image-processing/delta_vjb/delta';

% delta config path and name
cfg.configpath = 'G://GitHub/microfluidics-image-processing/delta_config/';
cfg.configname = 'config_2D_azimages.json';

% name of folder in which to store delta data (created in each position
% folder)
cfg.deltasavename = 'deltadata';

%image prototype name structured and order
cfg.imageprototype = 'Chamb%02d/Chamb%02dCh%01dFr%03d.tif';
cfg.orderprototype = 'ppct';

%pad images to this height and width
cfg.image_height = 256;
cfg.image_width = 256;

%use DeLTA cropping and drift correction
cfg.cropimages = false;
cfg.driftcor = false;

%DeLTA save format, choose any combination of ('movie', 'pickle', 'legacy')
cfg.saveformats = ('movie');

%clear all previous data of a current position if it already exists in  the deltasavename folder
cfg.clearsaves = true;

%save DeLTA movie
cfg.savemovie = true;
%how often to save a movie for (eg every 10th chamber per position will be saved)
cfg.savemoviefreq = 10;

%regionprop like features to measure. Fluorescence channels are added automatically
cfg.features_list = ["length", "width", "area", "perimeter", "edges"];


%% JSON File Generation - Do not change this section
% Convert configuration structure to JSON text
jsonText = jsonencode(cfg, 'PrettyPrint', true);

% Write JSON text to file
% Check if 'mainconfigname' ends with '.json'
if ~endsWith(mainconfigname, '.json')
    % If it does not, append '.json' to 'mainconfigname'
    mainconfigname = [mainconfigname, '.json'];
end
fid = fopen(fullfile(configdir, mainconfigname), 'w');
if fid == -1
    error('Cannot create JSON file');
end
fwrite(fid, jsonText, 'char');
fclose(fid);

% Confirmation message
msgbox(['Config file exported: ', fullfile(configdir, [mainconfigname, '.json'])]);