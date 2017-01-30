function [ s ] = makeSpikeDB( varargin )
%MAKESPIKEDB Summary of this function goes here
%   Detailed explanation goes here

TargetDir = {'data'};

for iDir = 1 : length(TargetDir)
    if TargetDir{iDir}(1) == '\'
        TargetDir{iDir} = TargetDir{iDir};
    end
end

for iarg= 1:2:(nargin-1),   % assume an even number of varargs
 
    switch lower(varargin{iarg}),

        case {'dir','path','filepath'}
            TargetDir = varargin{iarg+1};

        case ''

        otherwise,

    end % end of switch
end % end of for iarg


current_dir = pwd;
if ~iscell(TargetDir)
    temp{1}=TargetDir;
    TargetDir=temp;
    clear temp;
end

s = {};
iSpikeID = 1;
for iDir = 1:length(TargetDir)

    subdirs = dir(TargetDir{iDir});
    isitasubdir = [subdirs.isdir ];
    datadirs = subdirs( isitasubdir );
    subdirs = datadirs( 3:end ); %Remove all the weird . directories

    disp( ['Found ' num2str(size( subdirs, 1 )) ' session directories.']);
    jsonVersion = 1;
    
    for iSession = 1:size( subdirs, 1 )
        
        datafilepath = [TargetDir{iDir} '/' subdirs(iSession).name '/'];
        jsonfiles = dir([datafilepath '*.json']);
       
        disp(['Analyzing ' subdirs(iSession).name ]);
        try
            d = loadjson( [datafilepath jsonfiles(1).name]);
        
        if isfield(d, 'jsonversion') 
            jsonVersion = str2num(d.jsonversion);
        end
        
        %disp(jsonVersion);
        spike.name = subdirs(iSession).name;
        spike.number = iSpikeID;
        spike.session = subdirs(iSession).name(end-8:end);
        spike.comment = d.comment;
        spike.subject = subdirs(iSession).name(1:3);
        spike.sampleRate = 44100;
        spike.jsonVersion = jsonVersion;
        
        spike.trial.targetColor = '000000';
        spike.trial.targetSize = cell2mat( cellfun(@(x) x.size, d.trials, 'UniformOutput', 0) );
        spike.trial.targetVelocity = cell2mat( cellfun(@(x) x.velocity, d.trials, 'UniformOutput', 0) );
        
        spike.timestamps.spike = [];
        spike.timestamps.impact = [];
        spike.timestamps.angleValues = [];
        spike.timestamps.angleTimestamps = [];
        
        if jsonVersion == 3
            spike.trial.targetColor = d.color;
        elseif jsonVersion > 3
            spike.trial.targetColor = {};    
        end

        %spike.timestamps.spike = cell2mat( cellfun(@(x) x.spikeTimestamps, d.trials, 'UniformOutput', 0) );
        %spike.timestamps.impact = cell2mat( cellfun(@(x) x.timeOfImpact, d.trials, 'UniformOutput', 0) );
        for iTrial = 1:length(d.trials)
                try
                %spike.trial.targetColor{iTrial} = d.trials{iTrial}.color;
                spike.timestamps.spike = [spike.timestamps.spike d.trials{iTrial}.spikeTimestamps + (iTrial - 1).*(45*1000)];
                catch
                end 
                tempAngles = (180*(d.trials{iTrial}.angles/pi));
                tempAngleTimestamps = d.trials{iTrial}.timestamps - d.trials{iTrial}.timeOfImpact;
                 if (jsonVersion == 1)
                     %in Json version 1 angles after impact are 80 deg but
                     %in reality they were 160 deg (object covered full screen)
                     %this will fix the bug 
                    tempAngles(find(tempAngleTimestamps>0)) = tempAngles(find(tempAngleTimestamps>0))*2;
                 end
                 tempAngleTimestamps = d.trials{iTrial}.timestamps+ (iTrial - 1).*(45*1000);
                %spike.timestamps.angleTimePairs{iTrial} = [tempAngleTimestamps tempAngles];
                spike.timestamps.angleValues = [spike.timestamps.angleValues tempAngles];
                spike.timestamps.angleTimestamps = [spike.timestamps.angleTimestamps tempAngleTimestamps];

                spike.timestamps.impact = [spike.timestamps.impact d.trials{iTrial}.timeOfImpact + (iTrial - 1).*(45*1000)];
        end
          
         spike.timestamps.allSpike = [];
        if jsonVersion >= 5
            spike.timestamps.allSpike = d.allSpikeTimestamps;
        end
        
        %spike.firingRate = 1/mean(diff(spike.timestamps.spike));
        
        spike.timestamps.impactS06 = sort(spike.timestamps.impact( find( spike.trial.targetSize == 0.06 ) ));
        spike.timestamps.impactS08 = sort(spike.timestamps.impact( find( spike.trial.targetSize == 0.08 ) ));
        spike.timestamps.impactV02 = sort(spike.timestamps.impact( find( spike.trial.targetVelocity == -2 ) ));
        spike.timestamps.impactV04 = sort(spike.timestamps.impact( find( spike.trial.targetVelocity == -4 ) ));
        spike.timestamps.impactV06 = sort(spike.timestamps.impact( find( spike.trial.targetVelocity == -6 ) ));
        spike.timestamps.impactV08 = sort(spike.timestamps.impact( find( spike.trial.targetVelocity == -8 ) ));
        spike.timestamps.impactV10 = sort(spike.timestamps.impact( find( spike.trial.targetVelocity == -10 ) ));
        spike.timestamps.impactS06V02 = intersect( spike.timestamps.impactS06, spike.timestamps.impactV02 );
        spike.timestamps.impactS06V04 = intersect( spike.timestamps.impactS06, spike.timestamps.impactV04 );
        spike.timestamps.impactS06V06 = intersect( spike.timestamps.impactS06, spike.timestamps.impactV06 );
        spike.timestamps.impactS06V08 = intersect( spike.timestamps.impactS06, spike.timestamps.impactV08 );
        spike.timestamps.impactS06V10 = intersect( spike.timestamps.impactS06, spike.timestamps.impactV10 );
        spike.timestamps.impactS08V02 = intersect( spike.timestamps.impactS08, spike.timestamps.impactV02 );
        spike.timestamps.impactS08V04 = intersect( spike.timestamps.impactS08, spike.timestamps.impactV04 );
        spike.timestamps.impactS08V06 = intersect( spike.timestamps.impactS08, spike.timestamps.impactV06 );
        spike.timestamps.impactS08V08 = intersect( spike.timestamps.impactS08, spike.timestamps.impactV08 );
        spike.timestamps.impactS08V10 = intersect( spike.timestamps.impactS08, spike.timestamps.impactV10 );
       
        %spike.timestamps.impactV02S06 = 
        spike.classification.classified = 1;
        spike.classificationType = 'U';
        spike.classification.color = 'k';
        
        s{iSpikeID} = spike;

        iSpikeID = iSpikeID + 1;
        
        catch
         disp('Error happened')   
        end
        
    
    end
    
    
   
end

