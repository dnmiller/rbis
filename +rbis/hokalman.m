function [A, B, C] = hokalman(G, n)
% hokalman: Generate a state-space realization from a sequence of Markov
% parameters.
% 
%   [A, B, C] = hokalman(G, n) 
% 
%       If G is a matrix, construct an nth-order system estimate from a
%       sequence of Markov parameters in G. G does _not_ contain the
%       feed-through term.
% 
%       For a single-input system, G is organized as
% 
%           G = [G1'; G2'; G3'; ...]
% 
%       so that it would be the impulse response of the system, beginning
%       with the second sample, arranged so that time increases with
%       descending rows. There must be at least 2n+1 Markov parameters to
%       construct a system estimate of rank n.
% 
%   [A, B, C] = hokalman(G, n) 
% 
%       If G is an ny x nu x N sequence of matrices, construct an nth-order
%       system estimate with output dimensions ny and input dimension nu.
% 
%   The singular-value decomposition (SVD) is used to determine the
%   state-basis, and the returned system matrices are internally-balanced
%   (see ref). The method will only realize minimal systems.
% 
% Source: Chen, Linear System Theory and Design, 1984.
pkgname = 'rbis';
import rbis.datahankel;
errid = @(x) [pkgname ':hokalman:', x];

% Validate arguments.
narginchk(2, 2);
validateattributes(n, {'numeric'}, {'scalar', 'positive', 'integer'});

% Find the dimensions.
if ismatrix(G)
    nu = 1;
    [N, ny] = size(G);
else
    [ny, nu, N] = size(G);
end
assert(N >= 2*n, errid('NotEnoughParam'), ['At least 2n Markov '...
    'parameters (excluding feed-through) are necessary to realize a system.']);

% Go for fat matrices. These dimensions are totally ad-hoc.
rows = min(2*n, ceil((N-1)/2) + 1);
H = datahankel(G, rows);

% Build a shifted pair of Hankel matrices. We cut off the first row because
% we're expecting fat matrices. 
H0 = H(1:end-ny,:);
H1 = H(ny+1:end, :);

% Decompose and build low-rank approximations of the observability and
% controllability matrices.
[U S V] = svd(H0);

Un = U(:, 1:n);
Sn = S(1:n, 1:n);
Vn = V(:, 1:n);
    
% Build the extended observability matrix and take C from its first rows.
Gamma = Un * sqrt(Sn);
C = Gamma(1:ny,:);

% Build the extended controllability matrix and take B from its first
% columns.
Omega = sqrt(Sn) * Vn';
B = Omega(:, 1:nu);
    
% Calculate A from the inverse of the extended controllability and
% observability matrices.
Gamma_inv = sqrt(Sn) \ Un';
Omega_inv = Vn / sqrt(Sn);
A = Gamma_inv * H1 * Omega_inv;
end
