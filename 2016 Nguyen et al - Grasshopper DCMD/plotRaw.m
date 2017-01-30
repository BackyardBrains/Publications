
function [ out ] = plotRaw( spike,  varargin )
    %
    % plots the raw data around timeOfImpact collected from the iOS app
    % from trials indicated in [trialsIndex].

    %trialsIndex = [2,34,80];% velocities -2, -6 -10 in session 'G17-071416-01'
    trialsIndex = [81,110,126];%velocities -2, -4, -6 in session 'G17-071416-01'
    
    
    
    timeRange = [-0.5 0.5];

    for iarg= 1:2:(nargin-2),   % assume an even number of varargs

        switch lower(varargin{iarg}),

            case {'events','event'}
                eventNames = varargin{iarg+1};

            case {'timerange','timewindow', 'time', 't'}
                timeRange= varargin{iarg+1};

            case {'trials', 'trialsIndex'}
                trialsIndex = varargin{iarg+1};

        end % end of switch
end % end of for iarg



    %NOTE:
    %change "sessionDirectory" to change session
    %change "trialsIndex" to select diferent trials 
    sessionDirectory = [spike.subject '-' spike.session];



    rootDirectory = 'data';
    directoryDelimiter = '/';
    session = [];
    jsonPath =  [rootDirectory directoryDelimiter sessionDirectory directoryDelimiter sessionDirectory '.json'];
    session = loadjson(jsonPath);
    for i=1:length(trialsIndex)
        trials{i} = session.trials{1,trialsIndex(i)};
    end
    plotColor = {'R', 'G', 'B', 'Y'};
    linewidth = 2;


    for i=1:length(trials)

        %--------------------- Plot Angles --------------------------------
        subplot(length(trials)+1,1,1);
        axis([timeRange(1) timeRange(2) 0 180]);hold on;
        angleTime = trials{i}.timestamps - trials{i}.timeOfImpact;
        angleValues = 180*(trials{i}.angles/pi);
        angleValues(find(angleTime>0)) = angleValues(find(angleTime>0))*2;%bug fix
        plot(angleTime, angleValues, plotColor{i},'LineWidth',linewidth);

        %-------------------- Plot raw data -------------------------------
        subplot(length(trials)+1,1,i+1);
        axis([timeRange(1) timeRange(2) -1 1]);hold on;

        if ismac 
            audioFilePath = [rootDirectory directoryDelimiter sessionDirectory directoryDelimiter trials{i}.filename];
        else
            audioFilePath = [rootDirectory directoryDelimiter sessionDirectory directoryDelimiter strrep(trials{i}.filename, ':', '_')];
        end
        [audioData,Fs] = audioread(audioFilePath);
        audioTime = linspace(trials{i}.startOfRecording,trials{i}.startOfRecording+(1/Fs)*length(audioData),length(audioData));
        audioTime = audioTime - trials{i}.timeOfImpact;
        plot(audioTime,audioData, 'k','LineWidth',linewidth);
        plot([0 0], [-1 1], plotColor{i}, 'LineWidth',2);
    end



end