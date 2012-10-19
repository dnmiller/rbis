function [P, Q, M] = buildLMIs(n, region, varargin)
%buildLMIs: Construct LMIs to describe a convex region of the complex
%plane.
% 
%   [P, Q, M] = buildLMIs(n, region, ...)
% 
%       Construct YALMIP LMI objects that describe a convex region of the
%       complex plane. P is a symmetric matrix, Q is a full matrix, and M
%       is a matrix containing the n x n matrices P and Q that describes an
%       LMI region. The LMIs are such that any set (P, Q, M) for which P >=
%       0 and M >= 0 will have a third parameter A = P\Q which has
%       eigenvalues within the complex plane described by M.
% 
%       The region parameter describes the LMI regions. There are three
%       combinations of LMI regions, and any intersection of the three also
%       forms an LMI region. The three regions have the following possible
%       descriptions:
% 
%           - 'Stable' - force stable eigenvalues
%               - requires all eigenvalues to satisfy |z| < 1 - ds
%               - ds may be optionally set by the 'DeltaS' property
%               - by default, ds = 1e-4
% 
%           - 'Real' - force strictly real eigenvalues
%               - requires all eigenvalues to satisfy |Im(z)| < dr.
%               - dr may be optionally set by the 'DeltaR' property.
%               - by default, dr = 1e-8.
% 
%           - 'Positive' - force eigenvalues with positive real parts
%               - requires all eigenvalues to satisfy Re(z) > dp.
%               - dp may be optionally set by the 'DeltaP' property.
%               - by default, dp = 1e-4.
% 
%       region may be either a string or a cell array of strings. The
%       remaining arguments are the Delta* properties described in
%       Property, Value pairs.
% 
%       Examples:
% 
%           [P, Q, M] = buildLMIs(5, 'Stable', 'DeltaS', 0.1)
% 
%           P, Q, and M will be such that the eigenvalues of the 5 x 5
%           matrix P\Q has eigenvalues within the circle of radius 1 - 0.1.
% 
%           [P, Q, M] = buildLMIs(10, {'Stable', 'Positive'})
% 
%           P, Q, and M will be such that the eigenvalues of the 10 x 10
%           matrix P\Q has eigenvalues within the circle of radius 1 - 1e-4
%           and of real part > 1e-8.
% 
%       A call to YALMIP such as
% 
%       solvesdp([P >= 0; M >= 0], J)
% 
%       will minimize the cost-function J, which should be a YALMIP object
%       described in terms of P and Q. 
% 
% Source: Miller, de Callafon, "Subspace Identification with Eigenvalue
% Constraints," to appear in Automatica sometime in 2012 or 2013.

% Note: There's no unit test for this. We assume the deterministic solution
% tests are sufficient to verify that they function correctly. There is,
% however a unit test for the similar isInRegion.

% (C) D. Miller, 2012.
pkgname = 'rbis';
errid = @(x) [pkgname, ':buildLMIs:', x];

assert(exist('sdpvar', 'file') == 2, errid('NoYALMIP'), ...
    'YALMIP function sdpvar not found on current path. Aborting.');
narginchk(2, 8);

% Use Matlab's built-in inputParser object to parse the input arguments.
isorder = @(x) validateattributes(x, ...
    {'numeric'}, {'real', 'scalar', 'integer', 'positive'});
isdelta = @(x) validateattributes(x, ...
    {'numeric'}, {'real', 'scalar', 'finite', 'nonnan', 'positive'});

p = inputParser;
p.addRequired('n', isorder);
p.addRequired('Region', @(r) ischar(r) || iscell(r));
p.addParamValue('DeltaS', 1e-4, isdelta);
p.addParamValue('DeltaR', 1e-8, isdelta);
p.addParamValue('DeltaP', 1e-4, isdelta);
p.parse(n, region, varargin{:});

ds = p.Results.DeltaS;
dr = p.Results.DeltaR;
dp = p.Results.DeltaP;

% Force single-region entries to be cell arrays.
if ischar(region)
    region = {region};
end
region = region(:);
assert(~isempty(region) && length(region) < 4, errid('BadRegions'), ...
            'Must supply between 1 and 3 regions.');

% Store region options in a map with char keys and logical values.
validRegions = {'Stable', 'Real', 'Positive'};
props = containers.Map(validRegions, [false, false, false]);
for i = 1:length(region)
    validatestring(region{i}, validRegions);
    props(region{i}) = true;
end

% Build the LMIs.
P = sdpvar(n);
Q = sdpvar(n, n, 'full');

% This is our constraint matrix. It is a block-diagonal matrix in which
% each constraint corresponds to one block.
M = [];

if props('Stable')
    M = blkdiag(M, [
            (1 - ds)*P,     Q;
            Q',             (1 - ds)*P]);
end

if props('Real')
    M = blkdiag(M, [
            dr*P,           0.5*(Q' - Q)
            0.5*(Q - Q'),   dr*P]);
end

if props('Positive')
    M = blkdiag(M, [
            2*dp*P,         zeros(n);
            zeros(n),       Q + Q' - 2*dp*P]);
end
    
end
