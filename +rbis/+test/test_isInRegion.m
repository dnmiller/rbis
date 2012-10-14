function test_isInRegion
% Unit test for isInRegion.
pkgname = 'rbis';
import rbis.isInRegion;

% Bug in Matlab prevents anonymous handles to imported functions.
f1 = @() rbis.isInRegion([]);
f9 = @() rbis.isInRegion([], [], [], [], [], [], [], [], []);

msg = @(x) [pkgname, ':isInRegion:', x];

fprintf(['Testing ', pkgname, '.isInRegion...']);
% Test number of input arguments
assertExceptionThrown(@isInRegion, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f1, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f9, 'MATLAB:narginchk:tooManyInputs');

% Test for stable region. In theory, there is no lower bound for ds, but
% the eps test below stops working when it gets < ~-0.5
ds = 1e-4;
f = @(A) isInRegion(A, 'Stable');
function test_stable
    V = magic(2);
    A = V*eye(2)*(1 - ds - eps)/V;
    assertTrue(f(A));
    A = V*eye(2)*(1 - ds + eps)/V;
    assertFalse(f(A));
end
test_stable;
ds = 1 - 2*eps;
f = @(A) isInRegion(A, 'Stable', 'DeltaS', ds);
test_stable;
ds = 0.1;
f = @(A) isInRegion(A, 'Stable', 'DeltaS', ds);
test_stable;
ds = -0.1;
f = @(A) isInRegion(A, 'Stable', 'DeltaS', ds);
test_stable;
ds = 1 - eps;
f = @() isInRegion(randn(2), 'Stable', 'DeltaS', ds);
assertExceptionThrown(f, msg('BadDeltaS'));

% Test for positive region. In theory, there is no upper for dp, but
% the eps test below stops working when it gets > ~1.
dp = 1e-4;
f = @(A) isInRegion(A, 'Positive');
function test_positive
    V = magic(2);
    A = V*eye(2)*(dp + eps)/V;
    assertTrue(f(A));
    A = V*eye(2)*(dp - eps)/V;
    assertFalse(f(A));
end
test_positive;
dp = 0;
f = @(A) isInRegion(A, 'Positive', 'DeltaP', dp);
test_positive;
dp = 1;
f = @(A) isInRegion(A, 'Positive', 'DeltaP', dp);
test_positive;
dp = -eps;
f = @() isInRegion(randn(2), 'Positive', 'DeltaP', dp);
assertExceptionThrown(f, msg('BadDeltaP'));

% Test for real region.
dr = 1e-8;
f = @(A) isInRegion(A, 'Real');
function test_real
    V = magic(2);
    A = V*eye(2)*(0.5 + 1i*dr - 1i*eps)/V;
    assertTrue(f(A));
    A = V*eye(2)*(0.5 + 1i*dr + 1i*eps)/V;
    assertFalse(f(A));
end
test_real;
dr = 0.2;
f = @(A) isInRegion(A, 'Real', 'DeltaR', dr);
test_real;
% Strictly real can't use the +/- eps test.
assertTrue(isInRegion(eye(2)*0.5, 'Real', 'DeltaR', 0));
assertFalse(isInRegion(eye(2)*(0.5 + 1i*eps), 'Real', 'DeltaR', 0));

% Try one combo region. 
A = V*eye(2)*0.5/V;
assertTrue(isInRegion(A, {'Real', 'Positive', 'Stable'}, ...
        'DeltaS', 0.1, 'DeltaP', 0.1, 'DeltaR', 0));
A = V*eye(2)*(0.5 + 0.1i)/V;
assertFalse(isInRegion(A, {'Real', 'Positive', 'Stable'}, ...
        'DeltaS', 0.1, 'DeltaP', 0.1, 'DeltaR', 0));

fprintf('Passed\n');
end
