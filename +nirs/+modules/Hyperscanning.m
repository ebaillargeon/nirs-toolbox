classdef Hyperscanning < nirs.modules.AbstractModule
    %% Hyper-scanning - Computes all-to-all connectivity model between two seperate files
    % Outputs nirs.core.ConnStats object
    
    properties
        corrfcn;  % function to use to compute correlation (see +nirs/+sFC for options)
        divide_events;  % if true will parse into multiple conditions
        min_event_duration;  % minimum duration of events
        link;
        symetric;
    end
    methods
        function obj = Hyperscanning( prevJob )
            obj.name = 'Hypercanning';
            obj.corrfcn = @(data)nirs.sFC.ar_corr(data,'4xFs',true);  %default to use AR-whitened robust correlation
            obj.divide_events=false;
            obj.min_event_duration=30;
            obj.symetric=true;
            if nargin > 0
                obj.prevJob = prevJob;
            end
        end
        
        function connStats = runThis( obj, data )
            
            for i=1:height(obj.link)
                idxA = obj.link.ScanA(i);
                idxB = obj.link.ScanB(i);
                
                dataA = data(idxA).data;
                timeA = data(idxA).time+obj.link.OffsetA(i);
                dataB = data(idxB).data;
                timeB = data(idxB).time+obj.link.OffsetB(i);
                
                % Make sure we are using the same time base
                time=[max(timeA(1),timeB(1)):1/data(1).Fs:min(timeA(end),timeB(end))];
                for id=1:size(dataA,2)
                    dataA(1:length(time),id)=interp1(timeA,dataA(:,id),time);
                    dataB(1:length(time),id)=interp1(timeB,dataB(:,id),time);
                end
                dataA=dataA(1:length(time),:);
                dataB=dataB(1:length(time),:);
                
                dataA=dataA-ones(length(time),1)*mean(dataA,1);
                dataB=dataB-ones(length(time),1)*mean(dataB,1);
                
                dataA=dataA./(ones(length(time),1)*mad(dataA,1,1));
                dataB=dataB./(ones(length(time),1)*mad(dataB,1,1));
                
                connStats(i)=nirs.core.sFCStats();
                connStats(i).type = obj.corrfcn;
                connStats(i).description= ['Connectivity model of ' data(i).description];
                connStats(i).probe=data(idxA).probe;
                connStats(i).demographics={data(idxA).demographics; data(idxB).demographics};
                
                cond={};
                if(obj.divide_events)
                    stimNames=unique({data(idxA).stimulus.keys{:} data(idxB).stimulus.keys{:}});
                    stim=Dictionary;
                    for idx=1:length(stimNames)
                        onsets=[];
                        dur=[];
                        s=data(idxA).stimulus(stimNames{idx});
                        if(~isempty(s))
                            onsets=[onsets s.onset];
                            dur=[dur s.dur];
                        end
                        s=data(idxB).stimulus(stimNames{idx});
                        if(~isempty(s))
                            onsets=[onsets; s.onset];
                            dur=[dur; s.dur];
                        end
                        ss=nirs.design.StimulusEvents;
                        ss.name=stimNames{idx};
                        ss.onset=onsets;
                        ss.dur=dur;
                        ss.amp=ones(size(dur));
                        stim(stimNames{idx})=ss;
                    end
                    
                    
                    Basis=Dictionary;
                    Basis('default')=nirs.design.basis.BoxCar;
                    [X, names] = nirs.design.createDesignMatrix(stim,time,Basis);
                    mask{1}=1*(sum(abs(X),2)==0);
                    cond{1}='rest';
                    
                    for idx=1:size(X,2);
                        if(~all(X(:,idx)==0))
                            mask{end+1}=(X(:,idx)>0)*1;
                            cond{end+1}=names{idx};
                        else
                            disp(['discluding stimulus: ' names{idx}]);
                        end
                    end
                    
                else
                    mask={ones(length(time),1)};
                    cond={'rest'};
                end
                
                connStats(i).R=[];
                for cIdx=1:length(mask)
                    tmp=data(idxA);
                    
                    dd=[dataA dataB].*(mask{cIdx}*ones(1,size(dataA,2)*2));
                    if(obj.symetric)
                        Z=zeros(40,size(dd,2));
                        dd=[dd; Z; [dataB dataA].*(mask{cIdx}*ones(1,size(dataA,2)*2))];
                    end
                    tmp.time=time;
                    tmp.data=dd;
                   
                    [r,p,dfe]=obj.corrfcn(tmp);
                    
                    connStats(i).probe = nirs.util.createhyperscanprobe(connStats(i).probe);
                    
                    r(1:end/2,1:end/2)=0;
                    r(1+end/2:end,1+end/2:end)=0;
                    
                    
                    connStats(i).dfe(cIdx)=dfe;
                    connStats(i).R(:,:,cIdx)=r;
                    
                end
                connStats(i).conditions=cond;
                disp(['Finished ' num2str(i) ' of ' num2str(height(obj.link))])
                
                
            end
            
        end
    end
end
        