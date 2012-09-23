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
%   matrix-valued signals, such as correlation functions. Because Matlab's
%   xcorr/xcov functions effectively vectorize signals, we must do some
%   reshaping to get them into block-matrix form.

pkgname = 'rbis';

eval(['import ' pkgname '.blkhankel']);
eval(['import ' pkgname '.config']);
msg = @(x) [pkgname ':datahankel:', x];

% Validate arguments.
narginchk(2, 2);
nargoutchk(0, 1);
validateattributes(d, {'numeric'}, {'nonempty', 'real', 'finite'});
validateattributes(m, {'numeric'}, {'scalar', 'positive', 'integer'});

assert(ndims(d) < 4, msg('BadInput'), ...
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

assert(N >= m, msg('TooShortInput'), ...
        'Block rows cannot exceed length of signal.');
    
% Memory checks.
assert(rdim*m <= config.MAX_DATAHANKEL_ROWS, msg('TooManyRows'), ...
        ['Data hankel matrix would have ' num2str(rdim*m) ' rows. ' ...
         'Maximum is ' num2str(config.MAX_DATAHANKEL_ROWS) '. '...
         'See ' pkgname '.config to change.']);
     
ncols = (N - m + 1)*cdim;
assert(ncols <= config.MAX_DATAHANKEL_COLS, msg('TooManyColumns'),...
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
    % Check if we've got a matrix signal, and reshape if so.
    if size(d, 3) > 1
        % In case the user supplied bad dimensions.
        if size(d, 1) ~= rowdim
            error('Invalid row dimension.');
        elseif size(d, 2) ~= coldim
            error('Invalid col dimension.');
        end
        d0 = d;
        d = zeros(size(d, 3), rowdim*coldim);
        for k = 1:rowdim
            for j = 1:coldim
                d(:, (k-1)*coldim + j) = squeeze(d0(k, j, :));
            end
        end
        d = reshape(d(:), rowdim*coldim, size(d, 3))';
    end
    
    N = size(d, 1);
    
    % Check that the dimensions make sense.
    if size(d, 2) ~= rowdim*coldim
        error('Number of columns of signal must = row*col.');
    end
    
    col = zeros(m*rowdim, coldim);
    for i = 1:m
        col(rowdim*(i-1)+1:rowdim*i, :) = reshape(d(i, :), coldim, rowdim)';
    end
    row = zeros(rowdim, coldim*(N-m+1));
    for i = 1:N-m+1
        row(:, coldim*(i-1)+1:coldim*i) = reshape(d(i+m-1, :), coldim, rowdim)';
    end
end

% Build a block-Hankel matrix from the data.
Y = blkhankel(col, row);
end