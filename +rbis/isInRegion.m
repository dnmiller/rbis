function result = isInRegion(A, region, varargin)
%isInRegion: Determine whether the eigenvalues of a matrix are in an LMI
%region or not.
% 
%   result = isInRegion(A, region, ...)
% 
%       Return true if the eigenvalues of A are in the LMI region defined
%       by region. region is a string or cell-array of strings. The
%       remaining arguments describe the region in Property, Value pairs.
% 
%       This is meant to be a test to avoid unnecessary optimizations. If
%       the function returns true, then the problem is solved. If not, than
%       a semidefinite program is necessary. 
% 
%       See the documentation of buildLMIs.m for argument descriptions.

% (C) 2012 D. Miller
pkgname = 'rbis';
errid = @(x) [pkgname, ':isInRegion:', x];

narginchk(2, 8);

% Use Matlab's built-in inputParser object to parse the input arguments.
ismat = @(x) validateattributes(x, ...
    {'numeric'}, {'nonempty', '2d'});
isdelta = @(x) validateattributes(x, ...
    {'numeric'}, {'real', 'scalar', 'finite', 'nonnan'});

p = inputParser;
p.addRequired('A', ismat);
p.addRequired('Region', @(r) ischar(r) || iscell(r));
p.addParamValue('DeltaS', 1e-4, isdelta);
p.addParamValue('DeltaR', 1e-8, isdelta);
p.addParamValue('DeltaP', 1e-4, isdelta);
p.parse(A, region, varargin{:});

ds = p.Results.DeltaS;
dr = p.Results.DeltaR;
dp = p.Results.DeltaP;

% Error-check the deltas.
assert(1 - ds > eps, errid('BadDeltaS'), 'DeltaS must be < 1 - eps.');
assert(dp >= 0, errid('BadDeltaP'), 'DeltaP must be >= 0.');

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

% These describe "LMI regions," which mean that if a complex number is
% in some convex region of the complex plane, then f(z) > 0 (f(z) is a
% matrix function).
if props('Stable')
    alpha_s = (1 - ds)*eye(2);
    beta_s = [0, 1; 0, 0];
    f_s = @(z) alpha_s + beta_s*z + beta_s'*z';
else
    f_s = @(z) [];
end

if props('Real')
    alpha_r = dr*eye(2);
    beta_r = [0, 0.5; -0.5, 0];
    f_r = @(z) alpha_r + beta_r*z + beta_r'*z';
else
    f_r = @(z) [];
end

if props('Positive')
    alpha_p = dp*[2, 0; 0, -2];
    beta_p = [0, 0; 0, 1];
    f_p = @(z) alpha_p + beta_p*z + beta_p'*z';
else
    f_p = @(z) [];
end

f = @(z) blkdiag(f_s(z), f_r(z), f_p(z));

lambda = eig(A);
result = true;
for k = 1:length(lambda)
    if any(eig(f(lambda(k))) < 0)
        result = false;
        break;
    end
end

end