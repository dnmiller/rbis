clear all;

%% Test raw data
n = 5;
ny = 2;
nu = 1;
N = 5000;
err = 1e-9;

% Sometimes this will fail randomly if the generated system is
% ill-conditioned, so we add some additional assurances.
G = drss(n, ny, nu);
while any(eig(G.a) > 1 - 1e-3) 
    G = drss(n, ny, nu);
end
    

x0 = rand(n, 1);
u = rand(N,nu);
y = lsim(G, u, 0:N-1, x0);

tic
[Be, De, x0e] = rbis.solveBDx0(y, u, G.a, G.c, 0);
toc

if any(any(abs(G.b - Be) > err)) || ...
   any(any(abs(x0 - x0e) > err)) || ...
   any(any(abs(G.d - De) > err))
    error('test failed')
else
    disp('test passed')
end


%% Test corr data
n = 3;
ny = 2;
nu = 1;
N = 300;
err = 1e-9;

% Sometimes this will fail randomly if the generated system is
% ill-conditioned.
G = drss(n, ny, nu);
G.d = zeros(ny, nu);

Ruu = randn(N, nu*nu);
% Unfortunately, we cannot just simulate input-output behavior and
% calculate the correlations of the data, because the result is only exact
% when N -> infinity.
Ryu = zeros(size(Ruu, 1), ny*nu);
Rxu0 = randn(n, nu);
% Rxu0 = zeros(n, nu);
for i = 1:nu
    Ryu(:, ny*(i-1)+1:ny*i) = lsim(G, Ruu(:, nu*(i-1)+1:nu*i), 0:N-1, Rxu0(:, i));
end
    
tic
[Be, De, Rxu0e] = cobra.solveBDx0(Ryu, Ruu, G.a, G.c, 0, 'corr');
toc

if any(any(abs(G.b - Be) > err)) || ...
   any(any(abs(Rxu0 - Rxu0e) > err)) || ...
   any(any(abs(G.d - De) > err))
    error('test failed')
else
    disp('test passed')
end


%% Test corr data with different instrument
n = 5;
ny = 4;
nu = 3;
nr = 2;
err = 1e-9;
N = 10;

% Sometimes this will fail randomly if the generated system is
% ill-conditioned.
G = drss(n, ny, nu);
G.d = zeros(ny, nu);

Rur = randn(nu, nr, N);

Rxr0 = randn(n, nr);
% Rxr0 = zeros(n, nu);
Ryr = zeros(ny, nr, N);
for i = 1:nr
    tmp = lsim(G, squeeze(Rur(:, i, :))', 0:N-1, Rxr0(:, i));
    for k = 1:ny
        Ryr(k, i, :) = reshape(tmp(:, k), 1, 1, N);
    end
end


    
tic
[Be, De, Rxr0e] = cobra.solveBDx0(Ryr, Rur, G.a, G.c, 1, 'corr');
toc

if any(any(abs(G.b - Be) > err)) || ...
   any(any(abs(Rxr0 - Rxr0e) > err)) || ...
   any(any(abs(G.d - De) > err))
    error('test failed')
else
    disp('test passed')
end