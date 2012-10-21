function test_solveAC
% Unit test for isInRegion.
pkgname = 'rbis';
import rbis.*;

% Bug in Matlab prevents anonymous handles to imported functions.
f3 = @() rbis.solveAC([], [], []);
f12 = @() rbis.solveAC([], [], [], [], [], [], [], [], [], [], [], []);

msg = @(x) [pkgname, ':solveAC:', x];

fprintf(['Testing ', pkgname, '.solveAC...']);
% Test number of input arguments
assertExceptionThrown(@solveAC, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f3, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f12, 'MATLAB:narginchk:tooManyInputs');

    function test_with_dims_no_constraints(n, nu, ny, m, N, force_rank)
        if nargin < 6
            force_rank = true;
        end
        import rbis.*;
        G = drss(n, ny, nu);

        u = randn(N, nu);
        y = lsim(G, u);
        Y = datahankel(y, m);
        U = datahankel(u, m);
        Y0Pi = nullproj(Y(1:end-ny, :), U);
        Y1Pi = nullproj(Y(ny+1:end, :), U);
        % Sometimes the random inputs are weird and give bad results. This
        % is due to a combination of poorly conditioned u and a really
        % poorlly conditioned system returned by drss.
        while rank(Y0Pi) < n && force_rank
            u = randn(N, nu);
            y = lsim(G, u);
            Y = datahankel(y, m);
            U = datahankel(u, m);
            Y0Pi = nullproj(Y(1:end-ny, :), U);
            Y1Pi = nullproj(Y(ny+1:end, :), U);
        end
        [A, ~] = solveAC(Y0Pi, Y1Pi, n, ny);
        assertElementsAlmostEqual(sort(eig(G)), sort(eig(A)));
    end

assertExceptionThrown(@() test_with_dims_no_constraints(1, 1, 1, 2, 3, false), ...
        msg('Y0PiRankTooSmall'));
test_with_dims_no_constraints(1, 1, 1, 2, 4, false);
assertExceptionThrown(@() test_with_dims_no_constraints(2, 1, 1, 2, 4, false), ...
        msg('Y0PiDimTooSmall'));
assertExceptionThrown(@() test_with_dims_no_constraints(2, 1, 1, 3, 6, false), ...
        msg('Y0PiRankTooSmall'));
test_with_dims_no_constraints(2, 1, 1, 3, 7, false);
assertExceptionThrown(@() test_with_dims_no_constraints(2, 2, 1, 3, 9, false), ...
        msg('Y0PiRankTooSmall'));
test_with_dims_no_constraints(2, 2, 1, 3, 10, false);
assertExceptionThrown(@() test_with_dims_no_constraints(2, 1, 2, 3, 6, false), ...
        msg('Y0PiRankTooSmall'));
test_with_dims_no_constraints(2, 1, 2, 3, 7, true);

n = 2;
ny = 1;
nu = 1;
zv = [];
rp = 0.6;
ip = 0.1;
pv = [rp + ip*1i, rp - ip*1i];
kv = prod(1 - pv)/prod(1 - zv);
G = zpk(zv, pv, kv, []);
u = randn(1000, nu);
y = lsim(G, u);
Y = datahankel(y, 10);
U = datahankel(u, 10);
Y0Pi = nullproj(Y(1:end-ny, :), U);
Y1Pi = nullproj(Y(ny+1:end, :), U);
while rank(Y0Pi) < n && force_rank
    u = randn(N, nu);
    y = lsim(G, u);
    Y = datahankel(y, m);
    U = datahankel(u, m);
    Y0Pi = nullproj(Y(1:end-ny, :), U);
    Y1Pi = nullproj(Y(ny+1:end, :), U);
end
[A, ~] = solveAC(Y0Pi, Y1Pi, n, ny, 'Real');
assertEqual(eig(A), real(eig(A)));

n = 2;
ny = 1;
nu = 1;
zv = [];
rp = 0.6;
ip = 0.6;
pv = [rp + ip*1i, rp - ip*1i];
kv = prod(1 - pv)/prod(1 - zv);
G = zpk(zv, pv, kv, []);
u = randn(100, nu);
y = lsim(G, u);
Y = datahankel(y, 10);
U = datahankel(u, 10);
Y0Pi = nullproj(Y(1:end-ny, :), U);
Y1Pi = nullproj(Y(ny+1:end, :), U);
while rank(Y0Pi) < n && force_rank
    u = randn(N, nu);
    y = lsim(G, u);
    Y = datahankel(y, m);
    U = datahankel(u, m);
    Y0Pi = nullproj(Y(1:end-ny, :), U);
    Y1Pi = nullproj(Y(ny+1:end, :), U);
end
[A, ~] = solveAC(Y0Pi, Y1Pi, n, ny, 'Stable', 'DeltaS', 0.8);
assertTrue(all(abs(eig(A) < 0.8) ) );

fprintf('Passed\n');
end
