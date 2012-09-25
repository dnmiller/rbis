function test_hokalman
% Unit test for datahankel.
pkgname = 'rbis';
% Bug in Matlab prevents anonymous handles to imported functions.
f1 = @() rbis.hokalman([]);
f3 = @() rbis.hokalman([], [], []);
f = @(x, y) rbis.hokalman(x, y);
import rbis.hokalman;

m = rbis.test.mxunit;
msg = @(x) [pkgname, ':hokalman:', x];

fprintf(['Testing ', pkgname, '.hokalman...']);

% Test number of input arguments
m.assertExceptionThrown(@hokalman, 'MATLAB:narginchk:notEnoughInputs');
m.assertExceptionThrown(f1, 'MATLAB:narginchk:notEnoughInputs');
m.assertExceptionThrown(f3, 'MATLAB:TooManyInputs');

fprintf('Passed\n');
end
