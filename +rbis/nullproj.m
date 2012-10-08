function M = nullproj(Y, X)
% nullproj: Project one matrix onto the nullspace of another.
% 
%   M = nullproj(Y, X) 
% 
%       Project Y onto the nullspace of X and return the result as M. This
%       is a more-efficient and numerically stable equivalent to forming
%       the product
% 
%           M = Y*(eye(size(X, 2)) - X'/(X*X')*X)

% (C) D. Miller, 2012.
pkgname = 'rbis';
import rbis.lq;
errid = @(x) [pkgname, ':nullproj:', x];

narginchk(2, 4);
validateattributes(Y, {'numeric'}, {'2d', 'nonempty'});
validateattributes(X, {'numeric'}, {'2d', 'nonempty'});

% Validate dimensions.
[rY, c] = size(Y);
rX = size(X, 1);
assert(c == size(X, 2), errid('InvalidDims'), ...
                'Matrices must have same column-dimension.');
assert(c >= rX, errid('InvalidDims'), ...
                'X matrix cannot have more columns than rows.');
assert(rank(X) <= rX, errid('EmptyNullspace'), 'X has empty null-space.');

% Check for trivail nullspaces, since the LQ-decomposition does not
% work in those cases.
if rank(X) == c
    M = zeros(rY, rX);
else
    % Take the LQ decomposition of the compositite matrix.
    [L, Q] = lq([X; Y]);
    M = L(rX+1:end, rX+1:end)*Q(rX+1:end, :);
end
