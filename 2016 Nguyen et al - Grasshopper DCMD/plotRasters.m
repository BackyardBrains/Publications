function [ out handle ] = plotRasters( spike, varargin )
%PLOTISI Summary of this function goes here
%   Detailed explanation goes here

%% Read In Parameters

events = 'noseCenterOutLeft';
timeWindow = [-2 2];
blnNewFigure = 0;
sColor=[0 0 0];
plotSpikes = 1;
plotBursts = 0;
barColor = {'R', 'B', 'G', 'Y'};
ts = [];
out = [];
handle = gca;

for iarg= 1:2:(nargin-1),   % assume an even number of varargs

    switch lower(varargin{iarg}),
        
        case {'events','event'}
            events = varargin{iarg+1};

        case {'time','t', 'timewindow', 'timerange' }
            timeWindow = varargin{iarg+1};

        case 'figure',
            blnNewFigure = varargin{iarg+1};

        case 'ts',
            ts = varargin{iarg+1};
      
        case 'color',
            sColor = varargin{iarg+1};

        case 'barcolor',
            barColor = varargin{iarg+1};

        case {'plotburst','bursts'}
            plotBursts = varargin{iarg+1};
        
        case {'plotspike','spikes'}
            plotSpikes = varargin{iarg+1};
                       
        otherwise, 
        
    end % end of switch
end % end of for iarg

%% Plot Rasters
if ~iscell( events )
    events = { events };
end

nHeight=1;
nTotalRasters = 0;
     
if plotBursts
    title( ['Bursts'] );
end
if plotSpikes
    title( ['Spike Rasters - ' spike.name] );
end


eventLabel = '';
for iEvent = 1:size( events, 2 )
    eventLabel = [ eventLabel events{iEvent} ' / ' ];
end

if length( eventLabel ) > 20
	ylabel( [ 'trials' ] );
else
    ylabel( [ eventLabel(1:end-3) ' trials' ] );

end
if blnNewFigure
    figure;
end

%% Event Loops
for iEvent = 1:size( events, 2 )
     hold on;

     r = getRastersFromEvent( spike, 'ts', ts, 'events', events{ iEvent },...
         'timewindow', timeWindow, 'bursts', plotBursts );

     %if r.totalSpikes == 0
     %   continue 
     %end
     if ~isfield( r, 'rasters' )
         continue 
     end
     
     for i=1:size(r.rasters,2)
         
         if plotSpikes
             sTimes = r.rasters{i};
             for j = 1:size(sTimes,2)
                 line([sTimes(j) sTimes(j)],[nHeight nHeight+0.6],'LineWidth',0.5,'Color',sColor)
             end
         end

         if plotBursts
              bTimes = r.burstBegin{i};
              eTimes = r.burstEnd{i};
              for j = 1:size(bTimes,2)
                 line([bTimes(j) eTimes(j)],[nHeight+0.7 nHeight+0.7],'LineWidth',0.5,'Color',sColor)
              end
         end
         
         nHeight=nHeight+1;
     end
     
     TotalRasters( iEvent ) = size(r.rasters,2);
end

%% Add Color Bars
if size( events, 2 ) > 1
    iBegin = 0;
    
    for iEvent = 1:size( events, 2 )
        try
           iEnd = iBegin + TotalRasters( iEvent ) + 1;
           line( [timeWindow(1) + 0.01   timeWindow(1) + 0.01], [iBegin iEnd], 'color', barColor{iEvent}, 'lineWidth', 3 );
           iBegin = iEnd;
        catch
            
        end
    end
end

%% Event Loops
try
set( gca, 'xLim', timeWindow );
set( gca, 'yLim', [0 sum(TotalRasters)+1] );
set( gca, 'yDir', 'reverse' );
out = r;
handle = gca;
end
%% Old shit

%          bTimes = r.burstBegin{i};
%          for j = 1:size(bTimes,2)
% %             line([bTimes(j) bTimes(j)],[nHeight nHeight+0.6],'LineWidth',0.5,'Color',sColor)
%               plot( bTimes(j), nHeight, 'bo');
%          end
% 
%                   bTimes = r.burstEnd{i};
%          for j = 1:size(bTimes,2)
% %             line([bTimes(j) bTimes(j)],[nHeight nHeight+0.6],'LineWidth',0.5,'Color',sColor)
%               plot( bTimes(j), nHeight, 'ro');
%          end
