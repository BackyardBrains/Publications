function [ out ] = getRastersFromEvent( spike, varargin )
%GETRASTERSFROMEVENT Returns a cell array of relative spike times 
%   around a given event.

eventNames = {'noseCenterOutLeft'};
timeWindow = [-1 1];
blnGetBursts = 0;
ts = [];

for iarg= 1:2:(nargin-1),   % assume an even number of varargs

    switch lower(varargin{iarg}),

        case {'events','event'}
            temp = varargin{iarg+1};
            if iscell ( temp )
                eventNames = temp;
            else
                eventNames = {temp};
            end

        case {'time','t', 'timewindow' }
            timeWindow = varargin{iarg+1};
            
        case 'ts',
            ts = varargin{iarg+1};
            
        case {'bursts' }
            blnGetBursts = varargin{iarg+1};
             
    end % end of switch
end % end of for iarg

if isstruct( ts )
   eventLocation = 'ts.';
else
   eventLocation = 'spike.timestamps.';     
end
           
eventTimes = [];
for iEvent = 1 :  size( eventNames, 2 )
    eval ( ['newEventTimes = ' eventLocation  eventNames{ iEvent } ';'] );
    eventTimes = [newEventTimes eventTimes];   
end

clear newEventTimes;

   
out.isi = [];
out.totalSpikes = 0;
for iEvent = 1:size( eventTimes, 2 )
                relSpikes = spike.timestamps.spike( find( spike.timestamps.spike >= ...
                            (eventTimes(iEvent) + timeWindow(1))  &  ...
                            spike.timestamps.spike <= (eventTimes(iEvent) + timeWindow(2)) ...
                            ) );
                        

                 out.rasters{iEvent} = relSpikes - eventTimes(iEvent);

                 if blnGetBursts
                        relBurstBegins = spike.timestamps.burstBegin( find( spike.timestamps.burstBegin >= ...
                            (eventTimes(iEvent) + timeWindow(1))  &  ...
                            spike.timestamps.burstBegin <= (eventTimes(iEvent) + timeWindow(2)) ...
                            ) );
                    relBurstEnds = spike.timestamps.burstEnd( find( spike.timestamps.burstBegin >= ...
                             (eventTimes(iEvent) + timeWindow(1))  &  ...
                             spike.timestamps.burstBegin <= (eventTimes(iEvent) + timeWindow(2)) ...
                             ) );
                        
                                             
                    out.burstBegin{iEvent} = relBurstBegins - eventTimes(iEvent);
                    out.burstEnd{iEvent} = relBurstEnds - eventTimes(iEvent);
                 end
                 
             out.totalSpikes = out.totalSpikes + size( relSpikes, 2 );
             out.isi = [out.isi diff(out.rasters{iEvent})];
end
            

