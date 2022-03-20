%%%% DeepMIMO parameters set %%%%
% A detailed description of the parameters is available on DeepMIMO.net

%Ray-tracing scenario
params.scenario = 'O1_60';          % The adopted ray tracing scenario [check the available scenarios at https://deepmimo.net/scenarios/]

%Dynamic Scenario Scenes [only for dynamic (multiple-scene) scenarios]
params.scene_first = 1;
params.scene_last = 1;

% Active base stations
params.active_BS = [1];             % Includes the numbers of the active BSs (values from 1-18 for 'O1')(check the scenario description at https://deepmimo.net/scenarios/ for the BS numbers) 

% Active users
params.active_user_first = 1;       % The first row of the considered user section (check the scenario description for the user row map)
params.active_user_last = 1;        % The last row of the considered user section (check the scenario description for the user row map)

% Subsampling of active users
%--> Setting both subsampling parameters to 1 activate all the users indicated previously
params.row_subsampling = 1;         % Randomly select round(row_subsampling*(active_user_last-params.active_user_first)) rows
params.user_subsampling = 1;        % Randomly select round(user_subsampling*number_of_users_in_row) users in each row

params.enable_BS2BSchannels = 1;    % Enable generating BS to BS channel (could be useful for IAB, RIS, repeaters, etc.) 
params.num_paths = 5;               % Maximum number of paths to be considered (a value between 1 and 25), e.g., choose 1 if you are only interested in the strongest path

% If 5G toolbox is activated, the relevant previous parameters will be overridden
params.CDL_5G.NRB = 24;             % Number of NR blocks
params.CDL_5G.SCS = 30;             % kHz - Subcarrier Spacing

% OFDM parameters
params.OFDM_sampling_factor = 1;    % The constructed channels will be calculated only at the sampled subcarriers (to reduce the size of the dataset)
params.OFDM_limit = 64;             % Only the first params.OFDM_limit subcarriers will be considered when constructing the channels

% UE Movement Model
% The maximum Doppler shift will be determined from the velocity
% i.e., max_doppler =(params_user.velocity/3.6)/physconst('lightspeed')*f_carrier
% For a fixed velocity, select a scalar value.
% For random velocity selection for each user,
% set it to [min_vel, max_vel] and it will take a uniform random value in (min_vel, max_vel)
params.CDL_5G.Velocity = [1, 20]; % UE velocity in km/h -

% UE travel direction in degrees
% If a 1x2 vector is given in the format [azimuth; zenith], the direction is fixed. E.g., [0; 90] corresponds to +x
% If a 2x2 matrix of [min_az, max_az; min_zen, max_zen] is given
% it will be uniformly randomly sampled for each user.
params.CDL_5G.UTDirectionOfTravel = [0, 360; 90, 90];

% Number of consecutive OFDM slots to be sampled.
% - 14*num_slots channel time samples will be returned -
params.CDL_5G.num_slots = 2;

% The LOS path (if there is any in the ray-tracing) is split into Rician paths with the K-factor.
% 13.3dB is the CDL-D channel K factor given in 3GPP 38.901 7.7.1-4.
% 22dB is the CDL-E channel K factor given in 3GPP 38.901 7.7.1-5.
params.CDL_5G.KFactorFirstCluster = 13.3;

% Cross-polarization power ratio in dB
% The values defined in 3GPP 38.901 are
% CDL-A: 10, CDL-B: 8, CDL-C: 7, CDL-D: 11, CDL-E: 8.
params.CDL_5G.XPR = 10;

%%%%%%%%%%%%%%%%%%%%%%%%%% Antenna Definiton %%%%%%%%%%%%%%%%%%%%%%%%%%
% Antenna Arrays of Isotropic Elements
% Orientation:
params.CDL_5G.bsArrayOrientation = [0, 0]; 
% Azimuth (0 deg is array look direction +x, 90 deg is +y) and elevation (positive points upwards) in deg
% If there are multiple active antennas are available, and different
% orientations are targeted, rows of orientations can be given. 
% E.g., with 2 active antennas, we can set:
% params.CDL_5G.bsArrayOrientation = [[0, 0]; [90, 0]];

params.CDL_5G.ueArrayOrientation = [-180, 0]; 
% Azimuth (0 deg is array look direction +x, 90 deg is +y) and elevation (positive points upwards) in deg
% For a random UE orientation, set [az_min, az_max; el_min, el_max]. 
% The azimuth and elevation directions are uniformly sampled from [az_min, az_max] and [el_min, el_max]. 
% E.g., params.CDL_5G.ueArrayOrientation = [0, 360; 0, 60];
% The resulting array orientation of a UE can be viewed at path_params.ueArrayOrientation

% Antenna panel size:
params.CDL_5G.bsAntSize = [4, 8];  % Number of rows and columns in rectangular BS array
% If there are multiple active antennas are available, and different
% antennta sizes are targeted, rows of different panel sizes can be given. 
% E.g., with 2 active antennas, we can set:
% params.CDL_5G.bsAntSize = [[4, 8]; [2, 2]]; 

params.CDL_5G.ueAntSize = [2, 2];  % Number of rows and columns in the rectangular UE array


params.CDL_5G.polarization = 0;    % Polarization
% Setting it to 1 places 2 cross polarized antennas for each antenna element in the array. 
% In this case, there will be twice the number of antennas selected in
% ueAntSize and bsAntSize parameters.
% For instance, if bsAntSize = [4,8] and polarization is 1, the transmitter will have 64 antennas. 
% Similary, the ueAntSize is doubled with the polarization.

% Custom Antenna Array Definition with Phased Array Toolbox
%
% If the indicator is activated, the following custom antenna objects
% will be adopted by the CDL model. This way, directive
% and different shapes of antenna arrays can be defined.
%
% The details of the Phased Array System Toolbox
% can be found at https://www.mathworks.com/help/phased/index.html.
params.CDL_5G.customAntenna = 0;
if params.CDL_5G.customAntenna
    % Calculate wavelength for defining custom antenna object
    carrier_frequency = 60; %GHz
    lambda = carrier_frequency*1e9/physconst('LightSpeed');
    
    % Example UPA with (0.5*lambda) spacing in both directions
    params.CDL_5G.bsCustomAntenna = phased.URA('Size', [4, 8], 'ElementSpacing', 0.5*lambda*[1, 1]);
    
    % If there are multiple BS antennas activated, it can be
    % defined as a cell of the antennas corresponding to each active BS.
    % Example:
    % antenna1 = phased.URA('Size', [2 2], 'ElementSpacing', 0.5*lambda*[1 1]);
    % antenna2 = phased.URA('Size', [4 4], 'ElementSpacing', 0.5*lambda*[1 1]);
    % params.CDL_5G.bsCustomAntenna = {antenna1, antenna2};
    
    params.CDL_5G.ueCustomAntenna = phased.URA('Size', [2, 2], 'ElementSpacing', 0.5*lambda*[1, 1]);
end

params.saveDataset=0;