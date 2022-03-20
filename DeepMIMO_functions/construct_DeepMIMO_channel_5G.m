% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Umut Demirhan, Abdelrahman Taha, Ahmed Alkhateeb
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function [channel_coeffs] = construct_DeepMIMO_channel_5G(txSize, txOrientation, rxSize, rxOrientation, params_user, params)

    selected_subcarriers = 1:params.OFDM_sampling_factor:params.OFDM_limit;

    if params_user.num_paths == 0
        % Create a dummy input
        params_user.DS = [0];
        params_user.power = [1];
        params_user.DoD_phi = [0];
        params_user.DoD_theta = [0];
        params_user.DoA_phi = [0];
        params_user.DoA_theta = [0];
    end

    % Channel Generation
    channel = construct_DeepMIMO_CDL_channel(txSize, txOrientation, rxSize, rxOrientation, params_user, params);

    [pathGains,sampleTimes] = channel();

    pathFilters = getPathFilters(channel);
    [offset,~] = nrPerfectTimingEstimate(pathGains, pathFilters);
    nSlot = 0;
    hest = nrPerfectChannelEstimate(pathGains, pathFilters, params.CDL_5G.NRB, params.CDL_5G.SCS, nSlot, offset, sampleTimes);

    % Subsampling
    channel_coeffs = permute(hest, [2 3 4 1]);
    channel_coeffs = channel_coeffs(:, :, :, selected_subcarriers);

    if params_user.num_paths == 0
        % Make all channels 0
        channel_coeffs(:) = 0;
        channel_coeffs = complex(channel_coeffs);
    end

end