function [ out ] = plotPETH( spike,  varargin )
    %
    % plotPETH( spike, ...)

    % sipke = struct of spike class
    % arguments:
    %               'binsize'  number ex: 0.09
    %               'joinevents'  treat multiple events as one.
    %               'timerange'  [beforeEvent afterEvent]  ex: [-1 1]
    %               'ts'        struct of eventTimestamps ts.noseIn, etc.
    % example:
    % plotPETH( spike, 'events', events, 'joinevents', 1,
    %    'binSize', 0.05, 'timerange', [-1 5] );

    binSize = 0.030;
    timeRange = [-1 1];
    makeplot = 1;
    numPointsToSmooth = 3;
    blnMultipleEvents = false;
    blnJoinEvents = false;
    eventNames = 'noseCenterOutLeft';
    ts = [];
    barColor = {'R', 'B', 'G', 'Y'};
    zscore = 0;
    jitter = 0;
    linewidth = 1;
    analyzePETHsByToneDirectionAndCorrect = 0;

    for iarg= 1:2:(nargin-2),   % assume an even number of varargs

        switch lower(varargin{iarg}),

            case {'tone_direction_correct', 'tdc'}
                analyzePETHsByToneDirectionAndCorrect = varargin{iarg+1};

            case {'events','event'}
                eventNames = varargin{iarg+1};

            case {'joinevents','join'}
                blnJoinEvents = varargin{iarg+1};

            case 'binsize',
                binSize= varargin{iarg+1};

            case 'jitter',
                jitter= varargin{iarg+1};

            case {'color','barcolor'}
                barColor = varargin{iarg+1};

            case {'zscore'}
                zscore = varargin{iarg+1};

            case {'timerange','timewindow', 'time', 't'}
                timeRange= varargin{iarg+1};

            case 'ts',
                ts = varargin{iarg+1};

            case 'linewidth',
                linewidth = varargin{iarg+1};

            case 'smooth',
                numPointsToSmooth = varargin{iarg+1};

            case 'plot',
                makeplot = varargin{iarg+1};

        end % end of switch
end % end of for iarg

    if isstruct( ts )
        eventLocation = 'ts.';
    else
        eventLocation = 'spike.timestamps.';
    end

    events = [];
    if analyzePETHsByToneDirectionAndCorrect == 1
                %Orange = T1,     Blue=T2          Gold=Conta  
                c.orange = [255 153 0]/255;
                c.blue = [0 102 255]/255;
                c.gold = [176 170 52]/255;
                c.green = [0 166 81]/255;
                c.babyBlue = [0 153 204]/255;
                c.red = [191 30 45]/255;
                             
                %barColor = {c.orange, c.blue, c.gold, c.green, c.babyBlue, c.red, 'k'};
                barColor = {c.orange, c.blue, c.gold, c.green, 'k'};
        
                ts = getTrialEvents( spike, 'conflict', 0, 'tone', 1);
                eval ( ['events{ 1 } = ts.' eventNames ';'] );

                ts = getTrialEvents( spike, 'conflict', 0, 'tone', 2);
                eval ( ['events{ 2 } = ts.' eventNames ';'] );
                
                ts = getTrialEvents( spike, 'conflict', 0, 'movement', 1);
                eval ( ['events{ 3 } = ts.' eventNames ';'] );
                
                ts = getTrialEvents( spike, 'conflict', 0, 'movement', 2);
                eval ( ['events{ 4 } = ts.' eventNames ';'] );
                
                %ts = getTrialEvents( spike, 'conflict', 0, 'correct', 1);
                %eval ( ['events{ 5 } = ts.' eventNames ';'] );
                
                %ts = getTrialEvents( spike, 'conflict', 0, 'correct', 0);
                %eval ( ['events{ 6 } = ts.' eventNames ';'] );

                %ts = getTrialEvents( spike, 'conflict', 0 );
                %eval ( ['events{ 7 } = ts.' eventNames ';'] );

                ts = getTrialEvents( spike, 'conflict', 0 );
                eval ( ['events{ 5 } = ts.' eventNames ';'] );

    else
        if iscell( eventNames )
            if (size( eventNames, 2 ) > 1) %multiple events

                if blnJoinEvents == 1
                    for iEvent = 1 :  size( eventNames, 2 )
                        eval ( ['newEventTimes = ' eventLocation eventNames{ iEvent } ';'] );
                        events = [newEventTimes events];
                    end
                else
                    %only supporting 2 right now
                    blnMultipleEvents = true;
                    for iEvent = 1 :  size( eventNames, 2 )
                        eval ( ['events{ iEvent } = ' eventLocation eventNames{ iEvent } ';'] );
                    end
                end
            else
                %eval ( ['events{1} = ' eventLocation eventNames{ 1 } ';'] );
                eval ( ['events{1} = ' eventLocation eventNames ';'] );
            end
        else
            try
                eval ( ['events{1} = ' eventLocation eventNames ';'] );
            catch
                out.success = 0;
                return
            end
        end
    end

    spiketimes = spike.timestamps.spike;
    if zscore == 1
        isis = diff(spiketimes);
        spikemean = 1/mean(isis);
        spikestd = 1/std(isis);
    end

    edges = timeRange(1)-numPointsToSmooth*binSize:binSize:timeRange(2)+numPointsToSmooth*binSize + binSize;
    numEvents = 0;
    
    for iEvent = 1:length(events)
        h1=[];

        eventTimes = events{iEvent};

        if jitter > 0
            offset = (rand(size( eventTimes )) * 2 * jitter) - jitter;
            eventTimes = eventTimes + offset;
        end

        for iEventTimes = 1:length(eventTimes)
            relSpikes = spiketimes(  spiketimes > eventTimes(iEventTimes) + ...
                edges(1) &  spiketimes < eventTimes(iEventTimes) + edges(end) ) - eventTimes(iEventTimes);
            if isempty(relSpikes)
                h1(iEventTimes,:) = zeros( size(edges) );
            else
                h1(iEventTimes,:) = histc( relSpikes, edges );
            end
        end
        %histograms{iEvent} = h1(:,1:end - 1);
        histograms{iEvent} = h1;
        numEvents = numEvents + length(events{iEvent});
    end

    %edges = edges(1:end - 1);
    %edges =  edges(numPointsToSmooth+1:end-numPointsToSmooth);

    % If the total time interval (experimental session) is T (seconds) and we have N spikes in the interval,
    % then the neuron frequency is:
    %
    %
    % F = N/T
    F = 1/mean(diff(spiketimes));
    %
    % Then if the spike train is a Poisson train, the probability of the neuron to fire in the small bin of the size b (seconds) is
    %
    % 	P = F*b

    P = F.*binSize;

    %
    % The expected bin count for the perievent histogram is then:
    %
    % 	C = P*NRef, where NRef is the number of the reference events.

    % if blnMultipleEvents > 0
    %      numEvents = (length(events)+length(events2));
    % else
    %      numEvents = length(events);
    % end

    C = P * numEvents;

    %
    % The value C is used for drawing the Mean Frequency in the Perievent Histograms and Cross- and Autocorrelograms.
    %
    % The confidence limits for C are calculated using the assumption that C has a Poisson distribution.
    %
    % Assume that a random variable S has a Poisson distribution with parameter C.
    % Then the 99% confidence limits are calculated as follows:
    %
    % 	Low Conf. = x such that Prob(S < x) = 0.005
    % 	High Conf. =  y such that Prob(S > y) = 0.005
    %
    % If C < 30, Nex uses the actual Poisson distribution
    %
    % 	Prob(S = K) = exp(-C*K)*CK/K!
    %
    % to calculate the confidence limits.
    %

    %If Normalization is Spikes/Sec, bin counts are divided by NumRefEvents*Bin,
    %where NumRefEvents is the number of reference events.

    %Ztotal = sum(h)./binSize./length(events);
    %totMean = C ./ binSize ./ length(events);

    %disp( C - 2.58*sqrt(C) );
    %disp( C + 2.58*sqrt(C) );


    if ( C >= 30 )
        % If C>= 30., the Gaussian approximation is used:
        %
        % 	Low Conf.  = C - 2.58*sqrt(C);
        % 	High Conf.= C + 2.58*sqrt(C);
        %
        LowConf  = C - 2.58*sqrt(C);
        HighConf = C + 2.58*sqrt(C);

    else
        % Calculate Poission Distribution

        LowConf  = -1;
        HighConf  = -1;
        %C( realUnits( k ) ) = 10;
        s = 0;
        %disp(['C = ' num2str( C( realUnits( k ) ))]);
        for aa = 0:50
            pp =  exp(-C)*power(C, aa);

            fact = factorial(aa);
            pp = pp /  fact;
            s = s + pp;

            %disp( sprintf( 'aa = %i \tbb = %i \tpp = %f \ts=%f',aa,bb,pp,s)) ;
            if(LowConf == -1)
                if(s >= 0.05)
                    LowConf = aa-1;
                    %disp(['Setting Low = ' num2str( aa - 1 )])
                    %disp(['mean = ' num2str( C( realUnits( k ) ))])
                    %disp(sprintf('%d %.5f %.5f %d %d\n', aa, pp, s, LowConf( realUnits( k ) ), HighConf( realUnits( k ) )));

                end
            end
            if(HighConf == -1)
                if(s >= 0.95)
                    HighConf = aa;
                    %disp(['Setting High = ' num2str( aa )])

                end
            end

            %disp(sprintf('%d %.5f %.5f %d %d', aa, pp, s, LowConf( realUnits( k ) ), HighConf( realUnits( k ) )));

        end

    end

    %disp(HighConf);
    %disp(LowConf);


    HighConf = HighConf / binSize / numEvents;
    LowConf = LowConf /  binSize /  numEvents;

    out.ci.high = HighConf;
    out.ci.low = LowConf;
    out.m = F;
    for iEvent = 1:length(events)
        out.peth{iEvent} = smooth(sum(histograms{iEvent})./binSize./size(histograms{iEvent},1), numPointsToSmooth);
        out.peth{iEvent} = out.peth{iEvent}';
        out.peth{iEvent} = out.peth{iEvent}(numPointsToSmooth+1:end-numPointsToSmooth);
    end

    out.t = edges(numPointsToSmooth+1:end-numPointsToSmooth);
    if sum(cellfun( @(x) ~isempty(x), out.peth )) == 0 %All Are Empty.
        out.success = 0;
    else
        out.success = 1;
    end
    %
    % if blnMultipleEvents
    %     out.peth2 = smooth(sum(h2)./binSize./length(events2), numPointsToSmooth);
    %     out.peth3 = smooth(sum(h3)./binSize./(length(events) + length(events2)), numPointsToSmooth);
    % else
    %     out.peth2 = [];
    %     out.peth3 = [];
    % end

    if makeplot
        if length(events) > 1
            for iEvent = 1:length(events)
                try
                    g = stairs( out.t, out.peth{iEvent}, 'LineWidth', linewidth , 'Color', barColor{iEvent});
                end
                hold on;
            end

        else
            psp = bar(out.t, out.peth{1});
            set( psp, 'FaceColor', spike.classification.color);
            set( psp, 'EdgeColor', spike.classification.color);
            set( psp, 'BarWidth', 1 );
            if ~isnan(max(out.peth{1}))
                try
                    set( gca, 'ylim', [0 max(out.peth{1})*1.1] );
                catch
                    disp(['Error in Peth for spike: ' spike.name]);
                end
            end
        end
        set( gca, 'xlim', timeRange );
        hm = hline( F, 'r');
        hh = hline( HighConf, 'g:');
        hl = hline( LowConf, 'g:');
        set( hm, 'color', [0.5 0.5 0.5] );
        set( hh, 'color', [0.5 0.5 0.5] );
        set( hl, 'color', [0.5 0.5 0.5] );
        ylabel( 'Hz' );
        out.axes = gca;
        title(['PETH [Bin: ' num2str(binSize) 's ]']);

    else
        out.axes = [];
    end

    if length(events) == 1
        out.peth = out.peth{iEvent};  %Backwards compatable.
    end

    % Fix what we broke to make stair plot look pretty.
    %
    %I removed this...  should be fixed in a modified stair plot.  This PETH
    % function is too important to have this shifting..

    if blnMultipleEvents
        %    out.t  = out.t(1:end - 1);
        %    out.peth = out.peth(:,1:end - 1);
        %    out.peth2 = out.peth2(:,1:end - 1);
        %out.spikecount2 = sum(h2);
    end

    %out.spikecount1 = sum(h1);

    if zscore
        out.pezh = (out.peth - spikemean) ./ spikestd;
        if blnMultipleEvents
            out.pezh2 = (out.peth{2} - spikemean) ./ spikestd;
        end
    end


    %hline( HighConf, 'y');
    %hline( LowConf, 'y');
    end
