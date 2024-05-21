% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Umut Demirhan, Abdelrahman Taha, Ahmed Alkhateeb
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [DeepMIMO_dataset, params]=DeepMIMO_generator(params)

    % -------------------------- DeepMIMO Dataset Generation -----------------%
    fprintf(' DeepMIMO Dataset Generation started')

    [params, params_inner] = validate_parameters(params);

    if params_inner.dynamic_scenario
        for f = 1:length(params_inner.list_of_folders)
            fprintf('\nGenerating Scene %i/%i', f, length(params_inner.list_of_folders))
            params.scenario_files = fullfile(params_inner.list_of_folders{f}, params.scenario); % The initial of all the scenario files
            DeepMIMO_scene{f} = generate_data(params, params_inner);
            param{f} = params;
        end

        DeepMIMO_dataset = DeepMIMO_scene;
        params = param;
    else
        DeepMIMO_dataset = generate_data(params, params_inner);
    end

    fprintf('\n DeepMIMO Dataset Generation completed \n')

end

function DeepMIMO_dataset = generate_data(params, params_inner)
    % Reading ray tracing data
    fprintf('\n Reading the channel parameters of the ray-tracing scenario %s', params.scenario)
    for t=1:params.num_active_BS
        bs_ID = params.active_BS(t);
        fprintf('\n Basestation %i', bs_ID);
        [TX{t}.channel_params, TX{t}.channel_params_BSBS, TX{t}.loc] = feval(params_inner.raytracing_fn, bs_ID, params, params_inner);
    end

    % Constructing the channel matrices from ray-tracing
    for t = 1:params.num_active_BS
        fprintf('\n Constructing the DeepMIMO Dataset for BS %d', params.active_BS(t))
        c = progress_counter(params.num_user+params.enable_BS2BSchannels*params.num_active_BS);

        % BS transmitter location & rotation
        DeepMIMO_dataset{t}.loc = TX{t}.loc;

        %----- BS-User Channels
        for user=1:params.num_user
            % Channel Construction
            TX{t}.channel_params(user).travel_dir = params_inner.travel_dir(user, :)';
            TX{t}.channel_params(user).velocity = params_inner.velocity(user, :)';
            TX{t}.channel_params(user).rxArrayOrientation = params_inner.ueOrientation(user, :)';
            [DeepMIMO_dataset{t}.user{user}.channel]=construct_DeepMIMO_channel_5G(params_inner.bsAntenna{t}, params_inner.bsOrientation{t}, params_inner.ueAntenna, params_inner.ueOrientation(user, :), TX{t}.channel_params(user), params);
            
            % Location, LOS status, distance, pathloss, and channel path parameters
            DeepMIMO_dataset{t}.user{user}.loc=TX{t}.channel_params(user).loc;
            DeepMIMO_dataset{t}.user{user}.LoS_status=TX{t}.channel_params(user).LoS_status;
            DeepMIMO_dataset{t}.user{user}.distance=TX{t}.channel_params(user).distance;
            DeepMIMO_dataset{t}.user{user}.pathloss=TX{t}.channel_params(user).pathloss;
            DeepMIMO_dataset{t}.user{user}.path_params=rmfield(TX{t}.channel_params(user),{'loc','distance','pathloss'});

            c.increment();
        end

        %----- BS-BS Channels
        if params.enable_BS2BSchannels
            for BSreceiver=1:params.num_active_BS
                % Channel Construction
                TX{t}.channel_params_BSBS(BSreceiver).travel_dir = [0; 0];
                TX{t}.channel_params_BSBS(BSreceiver).velocity = 0;
                [DeepMIMO_dataset{t}.basestation{BSreceiver}.channel] = construct_DeepMIMO_channel_5G(params_inner.bsAntenna{t}, params_inner.bsOrientation{t}, params_inner.bsAntenna{BSreceiver}, params_inner.bsOrientation{BSreceiver}, TX{t}.channel_params_BSBS(BSreceiver), params);

                % Location, LOS status, distance, pathloss, and channel path parameters
                DeepMIMO_dataset{t}.basestation{BSreceiver}.loc=TX{t}.channel_params_BSBS(BSreceiver).loc;
                DeepMIMO_dataset{t}.basestation{BSreceiver}.LoS_status=TX{t}.channel_params_BSBS(BSreceiver).LoS_status;
                DeepMIMO_dataset{t}.basestation{BSreceiver}.distance=TX{t}.channel_params_BSBS(BSreceiver).distance;
                DeepMIMO_dataset{t}.basestation{BSreceiver}.pathloss=TX{t}.channel_params_BSBS(BSreceiver).pathloss;
                DeepMIMO_dataset{t}.basestation{BSreceiver}.path_params=rmfield(TX{t}.channel_params_BSBS(BSreceiver),{'loc','distance','pathloss'});

                c.increment();
            end
        end
    end

end