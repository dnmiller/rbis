function H = blkhankel(C, R)
%blkhankel: Construct a block-Hankel matrix.
% 
%   H = blkhankel(C, R) 
%
%       Construct a block-Hankel matrix with the first block column C and
%       the last block row R. 
%
%       The total rows of C must be a multiple of the rows of R, and the
%       last block row of R must be equal to the first block column of C.

% (C) D. Miller, 2012.
pkgname = 'rbis';
errid = @(x) [pkgname, ':blkhankel:', x];

narginchk(2, 2);
nargoutchk(0, 1);
validateattributes(C, {'numeric'}, {'nonempty'});
validateattributes(R, {'numeric'}, {'nonempty'});

cdim = size(C);
rdim = size(R);
blkrows = cdim(1)/rdim(1);
blkcols = rdim(2)/cdim(2);

% Error check dimensions of the input matrices.
assert(mod(blkrows, 1) == 0, errid('BadDims'), ...
        'Row dimension of C must be multiple of row dimension of R.');
assert(mod(blkcols, 1) == 0, errid('BadDims'), ...
       'Column dimension of R must be multiple of column dimension of C.');

coldim = cdim(2);
rowdim = rdim(1);

% Make sure the last block element of C and the first block element of R
% are the same. No precedence rules as with the built-in hankel function,
% just throw an error.
assert(all(all(C(end-rowdim+1:end,:) == R(:,1:coldim))), ...
        errid('BlocksNotEqual'), ...
        'Last block-element of C must be first block-element of R.')

% Build the block-Hankel matrix.
H = [C, zeros(cdim(1), rdim(2) - coldim)];
colidx_prev = 1:coldim;
for i = 2:blkcols
    colidx = (i-1)*coldim+1:i*coldim;
    H(:, colidx) = [H(rowdim+1:end, colidx_prev); R(:, colidx)];
    colidx_prev = colidx;
end
