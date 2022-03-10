function [params, params_inner] = validate_parameters(params)

    [params, params_inner] = additional_params(params);

    params_inner = validate_CDL5G_params(params, params_inner);
end

function [params, params_inner] = additional_params(params)

    % Add dataset path
    if ~isfield(params, 'dataset_folder')
        params_inner.dataset_folder = fullfile('./Raytracing_scenarios/');

        % Create folders if not exists
        folder_one = './Raytracing_scenarios/';
        folder_two = './DeepMIMO_dataset/';
        if ~exist(folder_one, 'dir')
            mkdir(folder_one);
        end
        if ~exist(folder_two, 'dir')
            mkdir(folder_two)
        end
    else
        params_inner.dataset_folder = fullfile(params.dataset_folder);
    end
    
    scenario_folder = fullfile(params_inner.dataset_folder, params.scenario);
    assert(logical(exist(scenario_folder, 'dir')), ['There is no scenario named "' params.scenario '" in the folder "' scenario_folder '/"' '. Please make sure the scenario name is correct and scenario files are downloaded and placed correctly.']);

    % Determine if the scenario is dynamic
    params_inner.dynamic_scenario = 0;
    if ~isempty(strfind(params.scenario, 'dyn'))
        params_inner.dynamic_scenario = 1;
        list_of_folders = strsplit(sprintf('/scene_%i/--', params.scene_first-1:params.scene_last-1),'--');
        list_of_folders(end) = [];
        list_of_folders = fullfile(params_inner.dataset_folder, params.scenario, list_of_folders);
    else
        list_of_folders = {fullfile(params_inner.dataset_folder, params.scenario)};
    end
    params_inner.list_of_folders = list_of_folders;
    
    % Read scenario parameters
    params_inner.scenario_files=fullfile(list_of_folders{1}, params.scenario); % The initial of all the scenario files
    load([params_inner.scenario_files, '.params.mat']) % Scenario parameter file

    % BS-BS channel parameters
    if params.enable_BS2BSchannels
        load([params_inner.scenario_files, '.BSBS.params.mat']) % BS2BS parameter file
        params.BS_grids = BS_grids;
    end

    params.carrier_freq = carrier_freq; % in Hz
    params.transmit_power_raytracing = transmit_power; % in dBm
    params.user_grids = user_grids;
    params.num_BS = num_BS;
    params.num_active_BS =  length(params.active_BS);
    
    assert(params.row_subsampling<=1 & params.row_subsampling>0, 'Row subsampling parameters must be selected in (0, 1]')
    assert(params.user_subsampling<=1 & params.user_subsampling>0, 'User subsampling parameters must be selected in (0, 1]')

    [params.user_ids, params.num_user] = find_users(params);
end

function [params_inner] = validate_CDL5G_params(params, params_inner)
    % Polarization
    assert(params.CDL_5G.polarization == 1 | params.CDL_5G.polarization == 0, 'Polarization value should be an indicator (0 or 1)')

    % UE Antenna
    if params.CDL_5G.customAntenna
        params_inner.ueAntenna = params.CDL_5G.ueCustomAntenna;
    else
        params_inner.ueAntenna = params.CDL_5G.ueAntSize;
    end

    % BS Antenna
    if params.CDL_5G.customAntenna % Custom Antenna
        if length(params.CDL_5G.bsCustomAntenna) ~= params.num_active_BS
            if length(params.CDL_5G.bsCustomAntenna) == 1
                antenna = params.CDL_5G.bsCustomAntenna;
                params_inner.bsAntenna = cell(1, params.num_active_BS);
                for ant_idx=1:params.num_active_BS
                    params_inner.bsAntenna{ant_idx} = antenna;
                end
            else
                error('The number of defined BS custom antenna should be either single or a cell array of N custom antennas, where N is the number of active BSs.')
            end
        else
            if ~iscell(params.CDL_5G.bsCustomAntenna)
                params_inner.bsAntenna = {params.CDL_5G.bsCustomAntenna};
            else
                params_inner.bsAntenna = params.CDL_5G.bsCustomAntenna;
            end
        end
    else % Size input
        % Check BS antenna size
        ant_size = size(params.CDL_5G.bsAntSize);
        assert(ant_size(2) == 2, 'The defined BS antenna panel size must be 2 dimensional (rows - columns)')
        if ant_size(1) ~= params.num_active_BS
            if ant_size(1) == 1
                params_inner.bsAntenna = repmat(params.CDL_5G.bsAntSize, params.num_active_BS, 1);
            else
                error('The defined BS antenna panel size must be either 1x2 or Nx2 dimensional, where N is the number of active BSs.')
            end
        else
            params_inner.bsAntenna = params.CDL_5G.bsAntSize;
        end
        
        if ~iscell(params_inner.bsAntenna)
            params_inner.bsAntenna = num2cell(params_inner.bsAntenna, 2);
        end
    end
    
    % Check BS Antenna Orientation
    ant_size = size(params.CDL_5G.bsArrayOrientation);
    assert(ant_size(2) == 2, 'The defined BS antenna orientation size must be 2 dimensional (azimuth - elevation)')
    if ant_size(1) ~= params.num_active_BS
        if ant_size(1) == 1
            params_inner.bsOrientation = repmat(params.CDL_5G.bsArrayOrientation, params.num_active_BS, 1);
        else
            error('The defined BS antenna orientation size must be either 1x2 or Nx2 dimensional, where N is the number of active BSs.')
        end
    else
        params_inner.bsOrientation = params.CDL_5G.bsArrayOrientation;
    end
    if ~iscell(params_inner.bsOrientation)
        params_inner.bsOrientation = num2cell(params_inner.bsOrientation, 2);
    end
    
    % Velocity
    if length(params.CDL_5G.Velocity) == 2
        params_inner.velocity = unifrnd(params.CDL_5G.Velocity(1), params.CDL_5G.Velocity(2), params.num_user, 1);
    elseif length(params.CDL_5G.Velocity) == 1
        params_inner.velocity = repmat(params.CDL_5G.Velocity, params.num_user, 1);
    else
        error('The defined velocity must be either 1 or 2 dimensional for fixed or random values.')
    end
    
    % Travel Direction
    size_travel_dir = size(params.CDL_5G.UTDirectionOfTravel);
    params_inner.travel_dir = zeros(params.num_user, 2);
    if sum(size_travel_dir == 2) == 2
        for i = 1:2
            params_inner.travel_dir(:, i) = unifrnd(params.CDL_5G.UTDirectionOfTravel(i, 1), params.CDL_5G.UTDirectionOfTravel(i, 2), params.num_user, 1);
        end
    elseif sum(size_travel_dir == [1, 2]) == 2
        for i = 1:2
            params_inner.travel_dir(:, i) = params.CDL_5G.UTDirectionOfTravel(i);
        end
    else
        error('The defined travel direction must be either 1x2 or 2x2 dimensional for fixed or random values.')
    end

    % UE Antenna Direction
    size_ue_orientation = size(params.CDL_5G.ueArrayOrientation);
    params_inner.ueOrientation = zeros(params.num_user, 2);
    if sum(size_ue_orientation == 2) == 2
        for i = 1:2
            params_inner.ueOrientation(:, i) = unifrnd(params.CDL_5G.ueArrayOrientation(i, 1), params.CDL_5G.ueArrayOrientation(i, 2), params.num_user, 1);
        end
    elseif sum(size_ue_orientation == [1, 2]) == 2
        for i = 1:2
            params_inner.ueOrientation(:, i) = params.CDL_5G.ueArrayOrientation(i);
        end
    else
        error('The defined user array orientation must be either 1x2 or 2x2 dimensional for fixed or random values.')
    end
end