% --------- DeepMIMO: A Generic Dataset for mmWave and massive MIMO ------%
% Authors: Umut Demirhan, Abdelrahman Taha, Ahmed Alkhateeb
% Date: March 17, 2022
% Goal: Encouraging research on ML/DL for MIMO applications and
% providing a benchmarking tool for the developed algorithms
% ---------------------------------------------------------------------- %

function channel = construct_DeepMIMO_CDL_channel(txSize, txOrientation, rxSize, rxOrientation, params_user, params)

    fc = params.carrier_freq;                 % carrier frequency (Hz)
    polarization = params.CDL_5G.polarization+1;
    
    channel = nrCDLChannel;
    channel.DelayProfile = 'Custom';
    channel.PathDelays = double(params_user.DS);
    channel.AveragePathGains = double(pow2db(params_user.power));
    channel.AnglesAoD = double(params_user.DoD_phi);       % azimuth of departure
    channel.AnglesZoD = double(params_user.DoD_theta);    % channel uses zenith angle, rays use elevation
    channel.AnglesAoA = double(params_user.DoA_phi);       % azimuth of arrival
    channel.AnglesZoA = double(params_user.DoA_theta);    % channel uses zenith angle, rays use elevation
    channel.HasLOSCluster = (params_user.LoS_status > 0);
    channel.CarrierFrequency = fc;
    channel.MaximumDopplerShift = (params_user.velocity*1000/3600)/physconst('lightspeed')*fc;
    channel.NormalizeChannelOutputs = false; % do not normalize by the number of receive antennas, this would change the receive power
    channel.NormalizePathGains = false;      % set to false to retain the path gains
    channel.UTDirectionOfTravel = params_user.travel_dir;
    channel.RandomStream = 'mt19937ar with seed'; % For reproducibility
    channel.Seed = 5; % Fixed seed
    channel.XPR = params.CDL_5G.XPR;
    
    if ~isMATLABReleaseOlderThan("R2021a")
        channel.ReceiveArrayOrientation = [rxOrientation(1); (-1)*rxOrientation(2); 0];  % the (-1) converts elevation to downtilt
        channel.TransmitArrayOrientation = [txOrientation(1); (-1)*txOrientation(2); 0];   % the (-1) converts elevation to downtilt
    else
        channel.ReceiveAntennaArray.Orientation = [rxOrientation(1); (-1)*rxOrientation(2); 0];  % the (-1) converts elevation to downtilt
        channel.TransmitAntennaArray.Orientation = [txOrientation(1); (-1)*txOrientation(2); 0];   % the (-1) converts elevation to downtilt
    end
    
    if params.CDL_5G.customAntenna
        channel.TransmitAntennaArray = rxSize;
        channel.ReceiveAntennaArray = txSize;
    else
        channel.ReceiveAntennaArray.Size = [rxSize, polarization, 1, 1];    
        channel.TransmitAntennaArray.Size = [txSize, polarization, 1, 1];
    end

    ofdmInfo = nrOFDMInfo(params.CDL_5G.NRB, params.CDL_5G.SCS);

    channel.SampleRate = ofdmInfo.SampleRate;
    channel.SampleDensity = 64;
    channel.ChannelFiltering = false;

    channel.NumTimeSamples = ceil((params.CDL_5G.num_slots+0.1)*ofdmInfo.SampleRate/ofdmInfo.SlotsPerSubframe*1e-3); % Each subframe is 1 ms

end