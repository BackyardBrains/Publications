function [ output ] = dbSelectSpikes( spikes, varargin )
%dbSelectSpikes Selects a subset of spikes from a spike cell array.
%   
% options
%   'validwaveforms' or 'valid':          
%   'class':          
%   'subclass':          
%   'customPath' or 'cp':          
%   'customQuery' or 'cq':          
%   'peakwidth':          
%   'valleywidth':          
%   'firingrate':          
%   'session':    
%   'tetrode': i.e. 'T07' or 'R02'
%   'name':          
%   'sortby' or 'sort': 'classType', 'session', 'up', 'upv'         
%   'region': 'Str', 'NAcc' 'MI', 'AStr', 'NStr', 'Pir'
%
% Examples: 
%  bad = dbselectSpikes( spikeDB, 'cp',
%         '.waveform.unfiltered.peaks.peakToValleyTime', 'cq', '== 0' );
%  d27 = dbSelectSpikes( spikeDB, 'session', 'C0320070627' );
%  spikeSorted = dbSelectSpikes( spikeDB, 'sortBy', 'upv' );

classTypeQuery = '';
subclassTypeQuery = '';
peakWidthQuery = '';
valleyWidthQuery = '';
firingRateQuery = '';
sessionQuery = '';
nameQuery = '';
customTypePath = '';
customTypeQuery = '';
regionQuery = '';
tetrodeQuery = '';

% Additions by ABW 1/12/09
notSessionQuery = '';
returnIndex = 0;
returnInvertedIndex = 0;

sortBy = '';
selectValid = -1;

for iarg= 1:2:(nargin-1),   % assume an even number of varargs

    switch lower(varargin{iarg}),
    
        
    case {'validwaveforms', 'valid'}
        selectValid = varargin{iarg+1};            

    case 'class',
        classTypeQuery = varargin{iarg+1};            

    case 'subclass',
        subclassTypeQuery = varargin{iarg+1};            

    case {'custompath', 'cp'}
        customTypePath = varargin{iarg+1};    
        
    case {'customquery', 'cq'}
        customTypeQuery = varargin{iarg+1};            
        
    case 'peakwidth',
        peakWidthQuery = varargin{iarg+1};     
                            
    case 'valleywidth',
        valleyWidthQuery = varargin{iarg+1};            
    
    case 'firingrate',
        firingRateQuery = varargin{iarg+1};            

    case 'session',
        sessionQuery = varargin{iarg+1};                      
   
    case 'region',
        regionQuery = varargin{iarg+1};            
 
    case 'name',
        nameQuery = varargin{iarg+1};            
    
    case 'tetrode', 
        tetrodeQuery = varargin(iarg+1); % ex: 'T07' or 'R02'
        %tetrodeQuery = tetrodeQuery{1}; % funky cell conversion stuff
        
    case {'sortby', 'sort', 'order', 'orderby'}
        sortBy = varargin{iarg+1};            
                            
    case 'close',
        closeImage = varargin{iarg+1};   
		
	case 'notsession'
		notSessionQuery = varargin{iarg+1};
		
	case {'returnindex', 'returnidx'}
		returnIndex = varargin{iarg+1};
	
	case {'returninvertedidx', 'returninvertedindex', 'returninvidx', 'inverseidx'}
		returnInvertedIndex = varargin{iarg+1};
		if returnIndex; 
			disp('WARNING: returning inverted index');
			returnIndex = 0; 
		end % can't return both uninverted and inverted indices.
		
    end % end of switch
end % end of for iarg

j = 1;
for iSpike = 1:size(spikes,2)
    try
       
	   s{j} =  spikes{iSpike}.session;
       n{j} =  spikes{iSpike}.name;
     
	   if ~isempty(customTypeQuery)
		   eval(['x(j) =  spikes{iSpike}' customTypePath ';']);
	   end
	   catch
	      disp(j);
	   end
	   j = j+1;
end

%Start by selecting all cells
index=1:size(spikes,2);

if selectValid > -1
    tempindex = find( invalidWF == not(selectValid) );
    index = index( tempindex );
end


% 'region': 'Str', 'NAcc' 'MI', 'AStr', 'NStr', 'Pir'
if ~isempty(regionQuery)

    for iSpike = 1:size(spikes,2)
         r(iSpike) = spikes{iSpike}.location.region;
         %spikes{iSpike}.tetrode.location = r(iSpike);
    end
    
    
%1	not looked at yet   -
%2	not intersting      --
%3	motor cortex        MI
%4	nucleus accumbens	NAcc
%5	neck striatum       CpuN
%6	auditory striatum	CpuA
%7	globus pallidus     GP
%8	piriform cortex     Pir

    switch lower(regionQuery),
     
    case 'gg'
        tempindex = find( r(index) == 4 |  r(index) == 5  );
        index = index( tempindex );
    case 'mi'
        tempindex = find( r(index) == 3 );
        index = index( tempindex );        
    case 'str'
        tempindex = find( r(index) == 4 |  r(index) == 5  | r(index) == 6 );
        index = index( tempindex );
    case {'nstr', 'cpun'}
        tempindex = find( r(index) == 5 );
        index = index( tempindex );
    case {'astr', 'cpua'}
        tempindex = find( r(index) == 6 );
        index = index( tempindex );
    case 'nacc'
        tempindex = find( r(index) == 4 );
        index = index( tempindex );
    case 'pir'
        tempindex = find( r(index) == 8 );
        index = index( tempindex );
    case 'gp'
        tempindex = find( r(index) == 7 );
        index = index( tempindex );
    case {'nodb', 'notindb', 'error'}
        tempindex = find( r(index) == 0 );
        index = index( tempindex );
    
    end
end


if ~isempty(customTypeQuery)
    eval(['tempindex = find( x ' customTypeQuery ');']);
    index = index( tempindex );
end

if ~strcmp( firingRateQuery, '' )
    eval(['tempindex = find( f ' firingRateQuery ');']);
    index = index( tempindex );
end

if ~strcmp( peakWidthQuery, '' )
    eval(['tempindex = find( p(index) ' peakWidthQuery ');']);
    index = index( tempindex );
end

if ~strcmp( valleyWidthQuery, '' )
    eval(['tempindex = find( v(index) ' valleyWidthQuery ');']);
    index = index( tempindex );  
end

if ~strcmp( classTypeQuery, '' )
    if ~isempty( index )
        tempindex = find( c(index) == classTypeQuery );
        index = index( tempindex );
    end
end

if ~strcmp( subclassTypeQuery, '' )
    tempindex = find( sc(index) == subclassTypeQuery );
    index = index( tempindex );
end

if ~strcmp( sessionQuery, '' )
    tempindex = find( strcmp( sessionQuery, s( index ) )); 
    index = index( tempindex );
end

if ~strcmp( notSessionQuery, '' )
	tempindex = find( ~strcmp( notSessionQuery, s( index ) ));
	index = index( tempindex );
end

if ~strcmp( tetrodeQuery, '' )
    tempindex = find( strcmp( tetrodeQuery, t( index ) )); 
    index = index( tempindex );
end

% if tetrodeQuery ~= 0
%     tempindex = find(t(index) == tetrodeQuery);
%     index = index ( tempindex );
% end

if ~strcmp( nameQuery, '' )
    tempindex = find( strcmp( nameQuery, n( index ) )); 
    index = index( tempindex );
end

switch lower(sortBy)
   
    case ''
    
    case {'firingrate', 'f'}
        X = [ f(index); 1:size(f(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));
        
    case {'valleywidth', 'v'}
        X = [ v(index); 1:size(v(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));
        
    case {'peakwidth', 'p'}
        X = [ p(index); 1:size(p(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));
        
    case {'unfilteredpeakwidth', 'up'}
        X = [up(index); 1:size(up(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));

    case {'peakvalleytime', 'pv', 'upv'}
        X = [ upv(index); 1:size(upv(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));

    case {'session', 's'}
        [SortedX,I] = sortrows( s' );
        index = index(I);
        
    case {'name', 'n'}
        [SortedX,I] = sortrows( n' );
        index = index(I);

    case {'peaktime', 'pt'}
        X = [ pt(index); 1:size(pt(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));
        
    case {'classtype', 'class'}
        %X = { c(index); 1:size(c(index),2) }';
        %[Y I] = sort(X{1});
        %index = index(I);
        X = [ co(index); 1:size(co(index),2) ]';
        SortedX = sortrows(X);
        index = index(SortedX(:,2));
        
        
    
end

if returnIndex
	output = index;
	return;
elseif returnInvertedIndex
	output = ones(size(spikes));
	output(index) = 0;
	output = find(output);
	return;
end
output = spikes(index);
