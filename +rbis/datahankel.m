function Y = datahankel(d, m)
%datahankel: Build a data Hankel matrix from a signal.
% 
%   Y = datahankel(D, m)
%
%       Construct a block-Hankel matrix of m block rows from the N-by-p
%       signal D, where is N is the number of samples in the signal and p
%       is the dimension of the signal.
% 
%       If size(d, 3) > 1, then d is treated as an r x c x N signal. 
% 
%   The second version is intended for building data matrices with
%   matrix-valued signals, such as correlation functions.

% (C) D. Miller, 2012.
import rbis.blkhankel;
import rbis.config;
pkgname = 'rbis';
errid = @(x) [pkgname, ':datahankel:', x];

% Validate arguments.
narginchk(2, 2);
nargoutchk(0, 1);
validateattributes(d, {'numeric'}, {'nonempty', 'real', 'finite'});
validateattributes(m, {'numeric'}, {'scalar', 'positive', 'integer'});

assert(ndims(d) < 4, errid('BadInput'), ...
    'd cannot have more than 3 dimensions.');

% Determine if the signal is vector- or matrix-valued.
if ismatrix(d)
    % If vector-valued, the signal is row-wise by sample.
    rdim = size(d, 2);
    cdim = 1;
    N = size(d, 1);
else
    % If the signal is matrix valued, then the dimensions are matrix dims.
    rdim = size(d, 1);
    cdim = size(d, 2);
    N = size(d, 3);
end

assert(N >= m, errid('TooShortInput'), ...
        'Block rows cannot exceed length of signal.');

nrows = rdim*m;
ncols = cdim*(N - m + 1);

% Size-limit checks.
assert(nrows <= config.MAX_DATAHANKEL_ROWS, errid('TooManyRows'), ...
        ['Data hankel matrix would have ' num2str(rdim*m) ' rows. ' ...
         'Maximum is ' num2str(config.MAX_DATAHANKEL_ROWS) '. '...
         'See ' pkgname '.config to change.']);
     
assert(ncols <= config.MAX_DATAHANKEL_COLS, errid('TooManyColumns'),...
        ['Data hankel matrix would have ', num2str(ncols), ' columns. ' ...
         'Maximum is ' num2str(config.MAX_DATAHANKEL_COLS) '. '...
         'See ' pkgname '.config to change.']);

% We compute the first block column of the data matrix and the last block
% row, then let the blkhankel function do the rest of the work.
if ismatrix(d)
    row = d';
    col = row(:);
    col = col(1:m*rdim);
    row = row(:,m:end);
else
    col = zeros(nrows, cdim);
    for i = 1:m
        col(rdim*(i-1)+1:rdim*i, :) = d(:, :, i);
    end
    row = zeros(rdim, ncols);
    k = 1;
    for i = m:N
        row(:, cdim*(k-1)+1:cdim*k) = d(:, :, i);
        k = k + 1;
    end
end

% Build a block-Hankel matrix from the data.
Y = blkhankel(col, row);
end
