function C = mtimes(A,B)
%MTIMES Implement scalar multiplication for a ttensor.
%
%   See also TTENSOR.
%
%MATLAB Tensor Toolbox.
%Copyright 2006, Sandia Corporation. 

% This is the MATLAB Tensor Toolbox by Brett Bader and Tamara Kolda. 
% http://csmr.ca.sandia.gov/~tgkolda/TensorToolbox.
% Copyright (2006) Sandia Corporation. Under the terms of Contract
% DE-AC04-94AL85000, there is a non-exclusive license for use of this
% work by or on behalf of the U.S. Government. Export of this data may
% require a license from the United States Government.
% The full license terms can be found in tensor_toolbox/LICENSE.txt
% $Id: mtimes.m,v 1.5 2006/09/02 00:51:03 tgkolda Exp $

if ~isa(B,'ttensor') && numel(B) == 1
    C = ttensor(B * A.core, A.u);
elseif ~isa(A,'ttensor') && numel(A) == 1
    C = ttensor(A * B.core, B.u);
else
    error('Use mtimes(full(A),full(B)).');
end