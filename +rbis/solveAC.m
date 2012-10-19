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
%   [A, C, sig] = solveAC(Y0Pi, Y1Pi, n, ny, ...) 
% 
%       Return the singular values of Y0Pi as well.
% 
%   The function is general enough to be used with matrices generated from
%   either raw data or covariance function estimates.
% 
%   Note that YALMIP and an appropriate solver are required for eigenvalue
%   constraints.
%
% Source: Miller and de Callafon, Subspace Identifcation Using Dynamic
% Invariance in Shifted Time-Domain Data, CDC 2010.

% (C) 2012 D. Miller
pkgname = 'rbis';
errid = @(x) [pkgname, ':solveAC:', x];
import rbis.buildLMIs;
import rbis.isInRegion;

narginchk(4, 6);

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

% Determine if a constrained solution is necessary.
if nargin > 4
    if isInRegion(n, region, varargin)
        % We're done.
        return;
    end
    
    [P, Q, M] = buildLMIs(n, region, varargin);

    % If there are constraints on the eigenvalues, we must solve an SDP.
    Constraints = [P > 0; M > 0];
    Costs = norm(Gamma*Q - Y1Pi*OmegaUp_inv*P, 'fro');

    % Shift is a magic option that makes some solvers be more strict about
    % feasibility.
    options = sdpsettings('shift', true);

    d = solvesdp(Constraints, Costs, options);

    assert(d.problem == 0, errid('YALMIPError'), ...
                ['YALMIP reported a problem: ', yalmiperror(d.problem)]);

    A = double(P)\double(Q);
    
    if ~isInRegion(n, region, varargin)
        warning(errid('YALMIPFailuer'), ...
                    'Solution did not satisfy constraints.');
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
