function [ out ] = plotAngles( s,  varargin )
%Plots angles vs time centered around impact time 

    timeRange = [-1 1];
    eventNames = {};
    linewidth = 1;
    plotColor = {'R', 'B', 'G', 'Y'};
 for iarg= 1:2:(nargin-2),   % assume an even number of varargs

        switch lower(varargin{iarg}),

            case {'events','event'}
                eventNames = varargin{iarg+1};

            case {'timerange','timewindow', 'time', 't'}
                timeRange= varargin{iarg+1};

            case 'linewidth',
                linewidth = varargin{iarg+1};
                
            case {'color','plotcolor'}
                plotColor = varargin{iarg+1};

        end % end of switch
end % end of for iarg


    axis([timeRange 0 180])
    hold on;
    eventLocation = 's.timestamps.';

    tempImpactTimestamps = [];
    for i=1:length(eventNames)
    %for i=1:length(s.timestamps.impactV02)
        eval ( ['tempImpactTimestamps = ' eventLocation eventNames{ i } ';'] );
        if(length(tempImpactTimestamps)>0)
            %Plot just first one, assume that all other are the same type
            %of event
            plot( s.timestamps.angleTimestamps-tempImpactTimestamps(1),s.timestamps.angleValues, 'LineWidth',linewidth, 'Color',plotColor{i});
        end
    end
    hold off;
end

