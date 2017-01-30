function [ out ] = generateFigures( spikes )

 
 %Figure 5
 generateRawTraces( spikes)
 generateSpeedPETHS( spikes)
 generateSummaryPETHS( spikes)
 
 %Figure 6
 generateITIPlot( spikes) 
 
 %Figure 7
 generateBrightnessPlot( spikes) 
 
end 

function  generateRawTraces( spikes)

    s = dbSelectSpikes( spikes, 'name', 'G17-071416-01' );
    s = s{1};  %Get a single entry of Cell Array.

    plotRaw( s, 'trials', [5,34,74], 'timewindow', [-0.25 0.25] );

end

function generateSpeedPETHS(spikes) 
%% Deterimine Window Heights
% explicitly set each subplot, with no other options
clear top;
top.sp = [3 1];
top.h = [.15 .50 .35];

%make portable position handles
p.size          = 1;
p.rasters       = 2;
p.peths          = 3;


%% Sort the cells
%s = dbSelectSpikes( spikes, 'name', 'G13-071216-01' );
s = dbSelectSpikes( spikes, 'name', 'G15-071316-01' );
s = s{1};

figure;    
h = subsubplot(top);
timerangeF = [-0.5 0.5];
    %fillscreen( gcf );
%    set( gcf, 'PaperOrientation', 'landscape' );
%    set( gcf, 'PaperPosition', [0.1 0.1 10.8 8.3] );
%    set( gcf, 'Position', [680 154 1145 880] );
    events = {'impactS06V02','impactS06V04','impactS06V06'};
    %events = {'impactS06V02', 'impactS06V06', 'impactS06V08', 'impactS06V10'};
    %---------------- Size of object - Angles -------------------------
    subplot( h(p.size) );
    plotAngles(s, 'events', events, 'timerange', timerangeF, 'linewidth',1 )
    %----------------  Spike Waveform  ---------------

    subplot( h(p.rasters) );
    [x r] = plotRasters(s, 'events', events, 'timerange', timerangeF); 
    %title( ['Tone Rasters' ], 'FontName', 'Helvetica' );
    subplot( h(p.peths) );
    
    pp =  plotPETH(s, 'events', events, 'binsize', 0.02, 'timerange', timerangeF);
   
    cleanUpRasters( h(p.rasters) );
    cleanUpHistograms( h(p.peths) );
    %
    

end


function generateSummaryPETHS(spikes) 

 
timerangeF = [-1 1];
peths = []; t = [];
firstHalfPeakBin = []; lastHalfPeakBin=[];
 
for i = 1:length(spikes) 
     mypeth =  plotPETH(spikes{i}, 'event', 'impact', 'binsize', 0.02, 'timerange', timerangeF, 'plot', 0);
     
     if mypeth.success
      peths(i,:) = mypeth.peth ./ max(  mypeth.peth );
      peakBin( i ) = min(find(  peths( i, : ) == 1 ));
      t = mypeth.t;
      
      try 
          halfPeaks = find(  peths( i, : ) <= 0.5 );
      
          firstHalfPeakBin( i ) = max(halfPeaks( halfPeaks < peakBin( i ) ));
          lastHalfPeakBin( i ) = min(halfPeaks( halfPeaks > peakBin( i ) ));
      catch
          firstHalfPeakBin( i ) = 0;
          lastHalfPeakBin( i ) = 0;
      end
     else
        disp('failed');
     end
     
end
  
[Y, I] = sort( peakBin );
sortedPETHs = peths(I,:);

figure; 
subplot( 1, 2, 1);
imagesc( t, [1:size(sortedPETHs,1)], sortedPETHs );
caxis( [0.25 1.25] );

totalPeaks = sum( t(peakBin) > -0.1 & t(peakBin) < 0.1 );
subjects = cell2mat(cellfun( @(x) x.subject', spikes, 'UniformOutput', 0));
[C,IA,IC] = unique( subjects', 'rows' );
sessionsPerSub = diff( IA );

disp(['Summary: Total Ssssions: ' num2str(size(subjects,2)) ]);
disp(['Summary: Total Subjects: ' num2str(size(C,1)) ]);
disp(['Summary: Average Session Per Subject: ' num2str(mean(sessionsPerSub)) ' range: [' num2str(min(sessionsPerSub)) ' ' num2str(max(sessionsPerSub)) ']' ]);
disp(['Summary: Total peaks within -0.1 and 0.1 : ' num2str(totalPeaks) ]);
disp(['Summary:  That is ' num2str(totalPeaks/length(peakBin)* 100) '% of all sessions']);

subplot( 1, 2, 2);

for i = 1:size(sortedPETHs,1)
    
    hold on;
    plot( t(Y(i)), i);
    try
    l = line( [t(firstHalfPeakBin(i)) t(lastHalfPeakBin(i))],[i i]);
    set( l, 'Color', [0.5 0.5 0.5] );
    catch
        
    end
end


end

function generateBrightnessPlot(spikes) 

%% Sort the cells
s = dbSelectSpikes( spikes, 'name', 'G26-072516-03' );
sMin = s{1};
s = dbSelectSpikes( spikes, 'name', 'G26-072516-02' );
sMax = s{1};

figure;
subplot(2,2,1);
plotPETH(sMin, 'events', 'impactS06', 'binsize', 0.02, 'timerange', [-1 1]); ylim([0 110]); title( [sMin.name ' - Min'], 'FontSize', 14); 
subplot(2,2,2);
plotPETH(sMax, 'events', 'impactS06', 'binsize', 0.02, 'timerange', [-1 1]); ylim([0 110]); title( [sMax.name ' - Max'], 'FontSize', 14); 
subplot(2,2,3);
[MinRasters] = plotRasters(sMin, 'events', 'impactS06', 'timerange', [-1 1]); title( [sMin.name ' - Min Brightness'], 'FontSize', 14); 
subplot(2,2,4);
[MaxRasters] = plotRasters(sMax, 'events', 'impactS06', 'timerange', [-1 1]); title( [sMax.name ' - Max Brightness'], 'FontSize', 14); 

%% T-Test of # of spikes between -0.1 and 0.1
for i = 1:length( MinRasters.rasters )
    minSpikes(i) = sum(MinRasters.rasters{i}>-0.1 & MinRasters.rasters{i}<0.1);
end

for i = 1:length( MaxRasters.rasters )
    maxSpikes(i) = sum(MaxRasters.rasters{i}>-0.1 & MaxRasters.rasters{i}<0.1);
end

disp ( ['Mean # of Spikes at Min Brightness = ' num2str(mean(minSpikes) ) '.  Mean # of Spikes at Max Brightness = ' num2str(mean(maxSpikes)) ]); 
[H,P,CI] = ttest2( minSpikes, maxSpikes );

if H == 1 
    disp( 'Brightnesses have Signficantly different spikes.' ); 
else
    disp( 'Brightnesses do not have Signficantly different spikes' );     
end
    disp( ['P = ' num2str(P) '' ] );
end

function generateITIPlot(spikes) 

%% Sort the cells
s = dbSelectSpikes( spikes, 'name', 'G25-072416-01' );
s45 = s{1};
s = dbSelectSpikes( spikes, 'name', 'G25-072416-02' );
s22 = s{1};
s = dbSelectSpikes( spikes, 'name', 'G25-072416-03' );
s01 = s{1};

figure;
subplot(2,3,1);
plotPETH(s01, 'events', 'impactS06', 'binsize', 0.02, 'timerange', [-2 2]); ylim([0 80]); title( [s01.name ' - ITI: 1s'], 'FontSize', 14); 
subplot(2,3,2);
plotPETH(s22, 'events', 'impactS06', 'binsize', 0.02, 'timerange', [-2 2]); ylim([0 80]); title( [s22.name ' - ITI: 22.5s'], 'FontSize', 14); 
subplot(2,3,3);
plotPETH(s45, 'events', 'impactS06', 'binsize', 0.02, 'timerange', [-2 2]); ylim([0 80]); title( [s45.name ' - ITI: 45s'], 'FontSize', 14); 
subplot(2,3,4);
plotRasters(s01, 'events', 'impactS06', 'timerange', [-2 2]); title( [s01.name ' - ITI: 1s'], 'FontSize', 14); 
subplot(2,3,5);
plotRasters(s22, 'events', 'impactS06', 'timerange', [-2 2]); title( [s22.name ' - ITI: 22.5s'], 'FontSize', 14); 
subplot(2,3,6);
plotRasters(s45, 'events', 'impactS06', 'timerange', [-2 2]); title( [s45.name ' - ITI: 45s'], 'FontSize', 14); 

end

function cleanUpRasters( ax )

    axes( ax );
    xlabel('');
    ylabel('');
    title('');
    l = vline(0,'k-');
    set( l, 'color', [0.5 0.5 0.5]);
    
end
function cleanUpHistograms( ax )

    axes( ax );
    xlabel('');
    ylabel('');
    title('');
    l = vline(0,'k--');
    set( l, 'color', [0.5 0.5 0.5]);
end