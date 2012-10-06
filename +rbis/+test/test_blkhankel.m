function test_blkhankel
% Unit test for blkhankel.
pkgname = 'rbis';
% Bug in Matlab prevents anonymous handles to imported functions.
f1 = @() rbis.blkhankel([]);
f3 = @() rbis.blkhankel([], [], []);
f = @(x, y) rbis.blkhankel(x, y);
import rbis.blkhankel;

msg = @(x) [pkgname, ':blkhankel:', x];

fprintf(['Testing ', pkgname, '.blkhankel...']);
% Test number input arguments
assertExceptionThrown(@blkhankel, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f1, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f3, 'MATLAB:TooManyInputs');

% Test dimension checking.
x = zeros(10, 1);
blkhankel(x, x);
x = zeros(9, 2);
y = zeros(1, 10);
blkhankel(x, y);
x = 0;
y = 0;
blkhankel(x, y);
x = zeros(10, 1);
y = 0;
blkhankel(x, y);
x = 0;
y = zeros(1, 10);
blkhankel(x, y);
x = zeros(9, 2);
y = zeros(2, 10);
assertExceptionThrown(@() f(x, y), msg('BadDims'));
x = zeros(10, 2);
y = zeros(2, 9);
assertExceptionThrown(@() f(x, y), msg('BadDims'));

% Test functionality.
assertBlkEq = @(x, y, z) assertEqual(z, blkhankel(x, y));
x = 0;
y = 0:5;
assertBlkEq(x, y, y);
x = (0:5)';
y = 5;
assertBlkEq(x, y, x);
x = (1:5)';
y = 5:10;
assertBlkEq(x, y, hankel(x, y));

    function [x, y, Z] = test_with_block_dim(r, c)
        blks = cell(6, 1);
        for i = 1:6
            blks{i} = randn(r, c);
        end
        x = [blks{1}; blks{2}; blks{3}];
        y = [blks{3}, blks{4}, blks{5}, blks{6}];
        Z = [blks{1}, blks{2}, blks{3}, blks{4}
             blks{2}, blks{3}, blks{4}, blks{5}
             blks{3}, blks{4}, blks{5}, blks{6}];
    end
[x, y, Z] = test_with_block_dim(2, 2);
assertBlkEq(x, y, Z);
[x, y, Z] = test_with_block_dim(3, 2);
assertBlkEq(x, y, Z);
[x, y, Z] = test_with_block_dim(2, 3);
assertBlkEq(x, y, Z);

fprintf('Passed\n');
end
