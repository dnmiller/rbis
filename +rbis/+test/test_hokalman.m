function test_hokalman
% Unit test for datahankel.
pkgname = 'rbis';
% Bug in Matlab prevents anonymous handles to imported functions.
f1 = @() rbis.hokalman([]);
f3 = @() rbis.hokalman([], [], []);
% Import statement doesn't work with nested functions (wtf)
f = @(x, y) rbis.hokalman(x, y);
import rbis.hokalman;

msg = @(x) [pkgname, ':hokalman:', x];

fprintf(['Testing ', pkgname, '.hokalman...']);

% Test number of input arguments
assertExceptionThrown(@hokalman, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f1, 'MATLAB:narginchk:notEnoughInputs');
assertExceptionThrown(f3, 'MATLAB:TooManyInputs');

% Test number of Markov parameters.
G = randn;
n = 1;
assertExceptionThrown(@() f(G, n), msg('NotEnoughParam'));
n = 2;
assertExceptionThrown(@() f(G, n), msg('NotEnoughParam'));
G = randn(2, 1);
n = 2;
assertExceptionThrown(@() f(G, n), msg('NotEnoughParam'));
G = randn(3, 1);
n = 2;
assertExceptionThrown(@() f(G, n), msg('NotEnoughParam'));

% Assert realization for some test systems. We only use minimal systems. 
    function G = build_impulse_matrix(A, B, C, N)
        [ny, n] = size(C);
        nu = size(B, 2);
        if nu == 1
            G = zeros(N, ny);
            for i = 1:N
                G(i, :) = (C*A^(i-1)*B)';
            end
        else
            G = zeros(ny, nu, N);
            for i = 1:N
                G(:, :, i) = C*A^(i-1)*B;
            end
        end
    end

    function test_realization(n, ny, nu, N)
        A = randn(n);
        B = randn(n, nu);
        C = randn(ny, n);
        G = build_impulse_matrix(A, B, C, N);
        [Ae, Be, Ce] = f(G, n);
        Ge = build_impulse_matrix(Ae, Be, Ce, N);
        assertElementsAlmostEqual(G, Ge);
    end

% We don't let the dimensions get to high here since there's no assurance
% that the random system is stable. 

% Single-input, single-output
test_realization(1, 1, 1, 2);
test_realization(1, 1, 1, 4);
test_realization(3, 1, 1, 6);
test_realization(3, 1, 1, 8);

% Single-input, multi-output
test_realization(1, 2, 1, 2);
test_realization(2, 2, 1, 4);
test_realization(2, 2, 1, 6);
test_realization(2, 4, 1, 4);

% Multi-input, single-output
test_realization(1, 1, 2, 2);
test_realization(2, 1, 2, 4);
test_realization(2, 1, 2, 6);
test_realization(2, 1, 4, 4);

% Multi-input, multi-output
test_realization(1, 2, 2, 2);
test_realization(1, 2, 2, 4);
test_realization(2, 2, 2, 4);
test_realization(4, 2, 2, 8);

fprintf('Passed\n');
end
