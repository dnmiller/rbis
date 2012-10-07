function [L Q] = lq(A)
%lq: Triangular-orthogonal decomposition.
%
%   [L, Q] = lq(A), where A is m-by-n, produces an m-by-m lower triangular
%   matrix L and an n-by-n unitary matrix Q so that A = L*Q.
narginchk(1, 1);
nargoutchk(0, 2);
validateattributes(A, {'numeric'}, {'2d'});

[Q, L] = qr(A', 0);

Q = Q';
L = L';
