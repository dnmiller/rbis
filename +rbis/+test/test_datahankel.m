function test_datahankel
% Unit test for datahankel.
pkgname = 'rbis';
% Bug in Matlab prevents anonymous handles to imported functions.
f1 = @() rbis.datahankel([]);
f3 = @() rbis.datahankel([], [], []);
f = @(x, y) rbis.datahankel(x, y);
import rbis.datahankel;
import rbis.config;

msg = @(x) [pkgname, ':datahankel:', x];

fprintf(['Testing ', pkgname, '.datahankel...']);

% Test number of input arguments
assertExceptionThrown(@datahankel, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f1, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f3, 'MATLAB:TooManyInputs');

% Smallest input.
f(0, 1);
assertExceptionThrown(@() f(0, 2), msg('TooShortInput'));
% Too many rows.
rmax = config.MAX_DATAHANKEL_ROWS;
d = zeros(rmax + 1, 1);
r = rmax + 1;
assertExceptionThrown(@() f(d, r), msg('TooManyRows'));
% Too many columns.
cmax = config.MAX_DATAHANKEL_COLS;
d = zeros(3, 2, cmax/2+1);
r = 1;
assertExceptionThrown(@() f(d, r), msg('TooManyColumns'));

assertMatEq = @(d, r, Y) assertEqual(Y, datahankel(d, r));
% Test scalar signal.
d = (1:9)';
r = 3;
Y = [1, 2, 3, 4, 5, 6, 7; 2, 3, 4, 5, 6, 7, 8; 3, 4, 5, 6, 7, 8, 9];
assertMatEq(d, r, Y);
% Test vector signal.
x = randn(1, 4);
d = repmat(x, 5, 1);
r = 2;
Y = [d'; d'];
Y = Y(:, 1:end-1);
assertMatEq(d, r, Y);
% Test matrix signal.
x = cell(9, 1);
d = zeros(3, 2, 9);
for i = 1:9
    x{i} = randn(3, 2);
    d(:, :, i) = x{i};
end
r = 2;
Y = [x{1}, x{2}, x{3}, x{4}, x{5}, x{6}, x{7}, x{8}
     x{2}, x{3}, x{4}, x{5}, x{6}, x{7}, x{8}, x{9}];
assertMatEq(d, r, Y);
x = cell(4, 1);
d = zeros(2, 2, 4);
for i = 1:4
    x{i} = randn(2, 2);
    d(:, :, i) = x{i};
end
r = 3;
Y = [x{1}, x{2}
     x{2}, x{3}
     x{3}, x{4}];
assertMatEq(d, r, Y);

fprintf('Passed\n');
end
