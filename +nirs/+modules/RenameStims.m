classdef RenameStims < nirs.modules.AbstractModule
    
    properties
        listOfChanges = {};
        % list = {  old_name1, new_name1; 
        %           old_name2, new_name2    };
    end
    
    methods
        function obj = RenameStims( prevJob )
           obj.name = 'Rename Stim Conditions';
           if nargin > 0
               obj.prevJob = prevJob;
           end
        end
        
        function data = runThis( obj, data )
            
            % get all stim names across all files
            [names, idx] = nirs.getStimNames( data );
            for i = 1:length(obj.list)
                lst = strcmp(names, obj.list{i,1});
                names(lst) = repmat( (obj.list(i,2)), [sum(lst) 1] );
            end
            
            % for each file rename stims
            for i = 1:length(data)
                lst = idx == i;
                
                if any(lst)
                    keys = names(lst);
                    values = data(i).stimulus.values;

                    ukeys = unique(keys,'stable');
                    uvalues = {};
                    for j = 1:length(ukeys)
                       lst = strcmp(ukeys{j},keys);
                       uvalues{j} = nirs.design.mergeStims( values(lst), ukeys{j} );
                    end

                    data(i).stimulus = nirs.Dictionary(ukeys, uvalues);
                end
            end
        end
    end
    
end
