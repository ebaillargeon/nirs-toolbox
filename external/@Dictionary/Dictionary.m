% Copyright (c) 2015, Jeffrey W Barker (jwb52@pitt.edu)
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 
% 1. Redistributions of source code must retain the above copyright
% notice, this list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
% A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
% BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
% OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
% AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
% LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
% WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

classdef Dictionary
    
    properties( SetAccess = private )
        keys
        values
    end
    
    properties( Dependent = true )
        count
    end
    
    properties ( Access = private )
        indices;
        MAX_SIZE = 2^32;
    end
    
    methods
        
        % constructor
        function obj = Dictionary( keys, vals )
            % insert initial key/value pairs set is unique
            if nargin == 2
                assert( length(keys)==length(vals) ...
                    && iscell(vals) ...
                    && iscell(keys) ...
                    && Dictionary.areUniqueKeys(keys) )  
                
                obj.keys        = keys;
                obj.values      = vals;
            elseif nargin == 1
                error('Constructor takes zero or two arguments.')
            else
                obj.keys    = {};
                obj.values  = {};
            end
            
            % hash the keys and store index to key/value
            obj = obj.rehash();
        end
        
        % update with list of keys and vals
        function obj = update(obj, keys, vals)
            assert( length(keys)==length(vals) ...
                    && iscell(vals) ...
                    && iscell(keys) ...
                    && Dictionary.areUniqueKeys(keys) )
                
            for i = 1:length(keys)
                obj.put(keys{i},vals{i});
            end
        end
        
        % number of items in dictionary
        function count = get.count( obj )
            count = length(obj.keys);
        end
        
        % delete items
        function obj = delete( obj, keys )
            if ischar(keys)
                keys = {keys};
            end
            
            for k = 1:length(keys)
               [i, keyexists] = obj.getindex(keys{k});
               if keyexists
                   idx = obj.indices(i);
                   obj.keys(idx) = [];
                   obj.values(idx) = [];

                   lst = obj.indices > idx;
                   obj.indices(lst) = obj.indices(lst) - 1;
               end
            end
            
        end
        
        % check if keys exists
        function out = iskey( obj, key )
            [~,keyexists] = obj.getindex(key);
            out = keyexists;
        end
        
        % check if empty
        function out = isempty( obj )
           out = obj.count == 0;
        end
        
        % assignment, i.e. dict('hello') = 1234
        function obj = subsasgn(obj,s,b)
            if strcmp(s.type,'()')
                % assert( ischar(s.subs{1}) )
                newKey      = s.subs{1};
                newValue    = b;

                obj = obj.put( newKey, newValue );
            else
               	obj = builtin('subsasgn',obj,s,b);
            end
        end
        
        % retrieval; i.e. dict('hello') returns 1234
        function out = subsref(obj,s)
            if length(s) == 1 && strcmp(s.type,'()')
                % assert( ischar(s.subs{1}) )
                key = s.subs{1};
                out = obj.get( key );
            else
                out = builtin('subsref',obj,s);
            end
        end
    end
    
    methods( Static )
        function [h, b] = hash( key )
            % this is faster than anything that can be 
            % implemented in pure matlab code
            b = getByteStreamFromArray(key);
            h = typecast(java.lang.String(b).hashCode(),'uint32');
            h = h(2);
        end
        
        function out = areUniqueKeys( keys )
            for i = 1:length( keys )
               b{i} = cast(getByteStreamFromArray(keys{i}),'char');
            end
            out = (length(b) == length(unique(b)));
        end
    end
    
    methods ( Access = private )
        % insert new items
        function obj = put( obj, newKey, newValue )
            [i, keyexists] = obj.getindex( newKey );
            
            if keyexists % key already exists
                idx = obj.indices(i);
                obj.values{idx} = newValue;
            else
                % add index
                obj.indices(i) = length(obj.keys)+1;
                
                % append keys and values
                obj.keys    {end+1} = newKey;
                obj.values  {end+1} = newValue;
            end
        end
        
        % get items
        function out = get( obj, key )
            [i, keyexists] = obj.getindex(key);
            
            if keyexists
                idx = obj.indices(i);
                out = obj.values{idx};
            else
                out = [];
            end
        end
        
        % find index
        function [i, keyexists] = getindex( obj, key )
            [i, b] = obj.hash( key );
            i = uint64(i) + 1;
            
            % while full and keys don't match
            while obj.indices(i) > 0 && ...
                ~isequal(b, getByteStreamFromArray(obj.keys{obj.indices(i)}))
            
                % increment index; 
                % wrap to beginning if necessary
                if i == uint64(2^32)
                    i = 1;
                else
                    i = i + 1;
                end
            end
            
            keyexists = obj.indices(i) > 0;
        end
        
        % rehash indices
        function obj = rehash( obj )
            nz = max( 1024, 2*obj.count );
            obj.indices = sparse([], [], [], obj.MAX_SIZE, 1, nz);
            for k = 1:length(obj.keys)
                   i = obj.getindex(obj.keys{k});
                   obj.indices(i) = k;
            end
        end
    end
    
end
