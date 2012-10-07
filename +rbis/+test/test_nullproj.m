function test_nullproj
% Unit test for nullproj.
pkgname = 'rbis';

% Bug in Matlab prevents anonymous handles to imported functions.
f1 = @() rbis.nullproj([]);
f3 = @() rbis.nullproj([], [], []);

import rbis.nullproj;

msg = @(x) [pkgname, ':nullproj:', x];

fprintf(['Testing ', pkgname, '.nullproj...']);
% Test number of input arguments
assertExceptionThrown(@nullproj, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f1, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f3, 'MATLAB:TooManyInputs');

% Compare basic projection to analytical
np_analytical = @(Y, X) Y*(eye(size(X, 2)) - X'/(X*X')*X);

% Ridiculous Matlab bug means imported functions are not in nested scope.
f = @(Y, X) nullproj(Y, X);
    function test_with_dims(ry, cy, rx, cx)
        Y = randn(ry, cy);
        X = randn(rx, cx);
        assertElementsAlmostEqual(np_analytical(Y, X), f(Y, X));
    end

test_with_dims(1, 1, 1, 1);
test_with_dims(2, 1, 1, 1);
test_with_dims(2, 2, 1, 2);
test_with_dims(2, 2, 2, 2);
test_with_dims(2, 3, 2, 3);
test_with_dims(2, 3, 3, 3);
test_with_dims(1, 5, 3, 5);

Y = randn;
X = randn(2, 1);
assertExceptionThrown(@() nullproj(Y, X), msg('InvalidDims'));

fprintf('Passed\n');
end
