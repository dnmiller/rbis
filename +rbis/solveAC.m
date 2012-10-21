function varargout = solveAC(Y0Pi, Y1Pi, n, ny, region, varargin)
%solveAC: Determine A and C via shift invariance of the projected
%output-data matrices Y0Pi and Y1Pi.
%
%   [A, C] = solveAC(Y0Pi, Y1Pi, n, ny) 
% 
%       Estimate A and C matrices of a linear system using
%       dynamic-invariance of the output data, as outlined in the
%       reference.
% 
%       - Y0Pi is a matrix of output data projected onto some matrix Pi.
%       This can be either an orthogonal projection or oblique projection,
%       so long as the "future input" is removed.
% 
%       - Y1Pi is a matrix of time-shifted output data projected onto the
%       same Pi.
% 
%       - n is the system order.
% 
%       - ny is the dimension of the output signal.
% 
%   [A, C] = solveAC(Y0Pi, Y1Pi, n, ny, regions, ...)
% 
%       Estimates A and C subject to semidefinite constraints. The region
%       parameter describes the LMI regions. There are three combinations
%       of LMI regions, and any intersection of the three also forms an LMI
%       region. The three regions have the following possible descriptions:
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
%       Note: The solutions often do not match constraints entirely. The
%       solutions can usually be constrained to the desired regions by
%       artificially increasing the value of the delta parameters.
% 
%   [A, C, sig] = solveAC(Y0Pi, Y1Pi, n, ny, ...) 
% 
%       Return the singular values of Y0Pi as well.
% 
%   The function is general enough to be used with matrices generated from
%   either raw data or covariance function estimates.
% 
%   Note that YALMIP and SDPT3 are required for eigenvalue constraints.
%
% Source: Miller and de Callafon, Subspace Identifcation Using Dynamic
% Invariance in Shifted Time-Domain Data, CDC 2010.

% (C) 2012 D. Miller
pkgname = 'rbis';
errid = @(x) [pkgname, ':solveAC:', x];
import rbis.buildLMIs;
import rbis.isInRegion;

narginchk(4, 11);

assert(size(Y0Pi, 1) >= n, errid('Y0PiDimTooSmall'), ...
        'Invalid dimensions: size(Y0Pi, 1) must be >= n.');
assert(rank(Y0Pi) >= n, errid('Y0PiRankTooSmall'), ...
        'Rank of Y0Pi must be >= n.');

validateattributes(n, {'numeric'}, {'scalar', 'positive', 'integer'});
validateattributes(ny, {'numeric'}, {'scalar', 'positive', 'integer'});

% Region shortcut. Passing varargin causes problems downstream if it's an
% empty cell array.
if nargin == 5
    inRegion = @(A) isInRegion(A, region);
elseif nargin > 5
    inRegion = @(A) isInRegion(A, region, varargin{:});
else
    inRegion = @(A) true;
end
    
% Take the SVD of the unshifted data.
[U, S, V] = svd(Y0Pi, 0);
Un = U(:, 1:n);
Sn = S(1:n, 1:n);
Vn = V(:, 1:n);

% Find observability and C matrices.
Gamma = Un * sqrt(Sn);
C = Gamma(1:ny, :);

% Solve for the system dynamics with the shifted projection.
Gamma_inv = sqrt(Sn) \ Un';
OmegaUp_inv = Vn / sqrt(Sn);

A = Gamma_inv*Y1Pi*OmegaUp_inv;

% This only executes if more than 4 arguments are present.
if ~inRegion(A)
    assert(exist('sdpt3', 'file') == 2, errid('NoSDPT3'), ...
            'SDPT3 is required for eigenvalue constraints.');
    if nargin == 5
        [P, Q, M] = buildLMIs(n, region);
    else
        [P, Q, M] = buildLMIs(n, region, varargin{:});
    end

    Ob0 = Gamma(1:end-ny, :);
    Ob1 = Gamma(ny+1:end, :);
    % If there are constraints on the eigenvalues, we must solve an SDP. We
    % use the MOESP formula for A here because it is better conditioned and
    % will usually result in a better answer.
    Constraints = [P > 0; M > 0];
%     Costs = norm(Gamma*Q - Y1Pi*OmegaUp_inv*P, 'fro');
    Costs = norm(Ob0*Q - Ob1*P, 'fro');

    % Shift is a magic option that makes some solvers be more strict about
    % feasibility.
    assign(P, eye(n));
    assign(Q, A);
    options = sdpsettings(...
        'solver', 'SDPT3', ...
        'verbose', true, ...
        'usex0', 1);

    d = solvesdp(Constraints, Costs, options);

    assert(d.problem == 0, errid('YALMIPError'), ...
                ['YALMIP reported a problem: ', yalmiperror(d.problem)]);

    A = double(P)\double(Q);

    if ~inRegion(A)
        disp('WARNING: Solution did not satisfy all constraints. Possible numerical issues.');
    end
end 

if nargout > 0
    varargout{1} = A;
end
if nargout > 1
    varargout{2} = C;
end
if nargout > 2
    varargout{3} = Sn;
end

end
