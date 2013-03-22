function [B, D, x0] = solveBDx0(y, u, A, C, nk, type, solve_x0)
%solveBD: Estimate B, D, and an initial condition x0 for an LTI system.
%
%   [B, D, x0] = solveBDx0(y, u, A, C, nk)
%
%       Determine a least-squares estimate of the input matrices B and D
%       and an initial condition x0 given matrices A and C, input u, and
%       output y of an LTI system.
%       
%       Input arguments:
%       y   - output data
%       u   - input data
%       A   - state dynamics matrix
%       C   - state-to-output matrix
%       nk  - number of time delays in system (optional, default is 1)
%       
%       y and u should be in "signal form," where each row is a different
%       sample. Thus if the system has output dimension ny and N samples
%       are taken, y should be N-by-ny. 
%
%       D will be a zero-matrix if nk > 0. (Default is 1 if omitted).
%
%       If nk > 1, it assumed that A does not include the time delays
%       already. Instead, u will be shifted by nk-1 places prior to
%       estimating B and D.
%   
%   [B, D, x0] = solveBDx0(y, u, A, C, nk, 'raw') 
% 
%       Same as above.
% 
%   [B, D, Rxz0] = solveBDx0(Ryz, Ruz, A, C, nk, 'cov')
% 
%       Determine a least-squares estimate of the input matrices B and D
%       and the initial value of the covariance function Rxz(0) given
%       matrices A and C, input cross-covariance function Ruz (z is some
%       external instrument, possibly u), and cross-covariance function
%       Ryz. We assume that if size(Ryz, 3) = 1, then the covariance
%       functions are in the form returned by the xcov function of the
%       Signal Processing Toolbox, and it is assumed that dim(z) = dim(u).
%       If size(Ryz, 3) > 1, then they have the form returned by the
%       freqresp function of the Control Systems Toolbox.
% 
%   [B, D, x0] = solveBDx0(y, u, A, C, nk, 'raw', 0) 
%       or
%   [B, D, Rxz0] = solveBDx0(Ryz, Ruz, A, C, nk, 'cov', 0)
%       
%       Same as above, but force a zero initial condition. By default, the
%       initial condition is always estimated.
% 
%
% References:
% [1] Miller and de Callafon, IFAC World Congress, 2011. 
% [2] Verhaegen and Verdult, Filtering and System Identification: A
%       Least-Squares Approach, 2007.


% v1.1 
% (C) 2011 D. Miller, UCSD

% By default, assume one time delay.
if nargin < 5
    nk = 1;
end
if nargin < 6
    type = 'raw';
end
if nargin < 7
    solve_x0 = true;
end

% Only accept stable A.
if any(abs(eig(A)) >= 1)
    error('Least-squares solution is only valid with a stable A matrix.');
end

% To deal with time delays, shift the output backwards.
if nk < 0
    error('Invalid number of time delays (cannot be < 0).');
elseif nk > 1
    u = u(1:end-nk+1,:);
    y = y(nk:end, :);
end

% Determine the signal dimensions based on the data type.
if strcmp(type, 'raw')
    [B, D, x0] = solve_raw(y, u, A, C, nk, solve_x0);
elseif strcmp(type, 'cov')
    [B, D, x0] = solve_corr(y, u, A, C, nk, solve_x0);
else
    error('Invalid "type" argument. Must be "raw" or "cov".');
end

end


function [B, D, x0] = solve_raw(y, u, A, C, nk, solve_x0)
    % Calculate the least-squares solution in the raw-data case.
    
    % Find the problem dimensions based on the dimensions of the input.
    N = size(y, 1);
    if N ~= size(u, 1)
        error('y and u signals must have same number of samples.');
    end
    ny = size(y, 2);
    nu = size(u, 2);
    n = size(A, 1);
    
    if any(size(A) ~= [n, n])
        error('A matrix must be square.');
    elseif any(size(C) ~= [ny, n])
        error('Incompatible dimensions of C matrix.');
    end
    
    % Calculate the regressor for B.
    phiB = zeros(n*nu, ny*N);
    
    % The regressor for B is actually a state sequence of a dual system,
    % but with each input channel considered independently. See ref [1] for
    % details.
%     fprintf('\nComputing B regressor...   ');
    num = ny*nu;
    ik = 1;
    for i = 1:nu
        for j = 1:ny
%             fprintf('\b\b\b\b%03d%%', round(ik/num*100));
            ik = ik+1;
            uk = [zeros(N, j-1), u(:, i), zeros(N, ny-j)];
            x = ltitr(A', C', uk);
            
            % Copy the state sequence into the regressor for B.
            for k = 1:N
                phiB(n*(i-1)+1:n*i, ny*(k-1)+j) = x(k, :)';
            end
        end
    end

    % Calculate the regressor for x0.
%     fprintf('Computing x0 regressor...\n\n');
    if solve_x0
        phix0 = zeros(n, ny*N);
        for k = 1:n
            CAk = C*ltitr(A, zeros(n, 1), zeros(N, 1), [zeros(1, k-1), 1, zeros(1, n-k)])';
            phix0(k, :) = CAk(:)';
        end   
    else
        phix0 = [];
    end
    
    
    % Calculate the regressor for D if needed.
%     fprintf('Computing D regressor..\n\n');
    if nk == 0
        phiD = zeros(nu*ny, ny*N);
        for k = 1:N
            % This for-loop takes advantage of the fact that we're taking a
            % kroneker product with an identity, so the matrix has a
            % special structure that lets us avoid use of the Matlab kron
            % function, which is horribly slow.
            for i = 1:nu
                phiD(ny*(i-1)+1:ny*i, ny*(k-1)+1:ny*k) = eye(ny)*u(k, i);
            end
        end
    else
        phiD = [];
    end
    
    % Vectorize y to use in the least-squares problem.
    y = y';
    y = y(:);
    
    % Find the least-squares solution for x0, B, D.
    theta = [phiB', phix0', phiD']\y;
    
    % Extract the parameters from theta.
    B = reshape(theta(1:n*nu), n, nu);
    
    if solve_x0
        x0 = theta(n*nu+1:n*(nu+1));
    else
        x0 = zeros(n, 1);
    end
    
    if nk == 0
        if solve_x0
            D = reshape(theta(n*(nu+1)+1:end), ny, nu);
        else
            D = reshape(theta(n*nu+1:end), ny, nu);
        end
    else
        D = zeros(ny, nu);
    end
end


function [B, D, Rxz0] = solve_corr(Ryz, Ruz, A, C, nk, solve_x0)
    % Calculate the least-squares solution in the correlation-function
    % case.
    
    % If size(Ryz, 3) > 1 or size(Ruz, 3) > 1, then reshape.
    if size(Ryz, 3) > 1
        ny = size(Ryz, 1);
        nz = size(Ryz, 2);
        nu = size(Ruz, 1);
        if size(Ruz, 2) ~= nz
            error('size(Ruz, 2) ~= size(Ryz, 2). Signals must have same instrument.');
        end
        
        N = size(Ryz, 3);
        if size(Ruz, 3) ~= N
            error('size(Ruz, 3) ~= size(Ryz, 3). Signals must have same number of samples.');
        end
        
        % Reshape the signals for the least-squares procedure.
        Ryz = reshape(Ryz(:), ny*nz, N)';
        Ruz = reshape(Ruz(:), nu*nz, N)';
    else
        % We assume that z = u if the signal is not in the above format.
        N = size(Ruz, 1);
        if N ~= size(Ryz, 1)
            error('Ryz and Ruz signals must have same number of samples.');
        end

        nu = sqrt(size(Ruz, 2));
        nz = nu;
        if floor(nu) ~= nu
            error('Invalid size of Ruz signal array.');
        end

        ny = size(Ryz, 2)/nu;
        if floor(ny) ~= ny
            error('Invalid size of Ryz signal array.');
        end
    end
    
    n = size(A, 1);

    % Calculate the regressor for B.
    phiB = zeros(n*nu, ny*nz*N);

    % The regressor is a state-sequence of a dual system. See ref [1] for
    % details.
    for i = 1:nu
        for j = 1:ny*nz
            beta = floor((j-1)/ny) + 1;
            gamma = mod(j - 1, ny) + 1;
            uk = [zeros(N, gamma - 1), ...
                  Ruz(:, nu*(beta - 1) + i), ...
                  zeros(N, ny - gamma)];
            x = ltitr(A', C', uk);
            for k = 1:N
                phiB(n*(i-1)+1:n*i, ny*nz*(k-1)+j) = x(k, :)';
            end
        end
    end

    % Solve for the initial cross-correlation of the state and the
    % instrument.
    if solve_x0
        phiRxz0 = zeros(n*nz, nz*ny*N);
        
        row_idx = reshape(repmat((1:ny*nz:N*ny*nz)-1, ny, 1), [], 1)' + repmat(1:ny, 1, N);
        for k = 1:n
            CAk = C*ltitr(A, zeros(n, 1), zeros(N, 1), [zeros(1, k-1), 1, zeros(1, n-k)])';
            for i = 1:nz
                phiRxz0(n*(i-1)+k, row_idx+(i-1)*ny) = CAk(:)';
            end
        end        
    else
        phiRxz0 = [];
    end

    % Add regressor for feed-through term if needed.
    if nk == 0
        phiD = zeros(nu*ny, ny*nz*N);
        for k = 1:N
            % This for-loop takes advantage of the fact that we're taking a
            % kroneker product with an identity, so the matrix has a
            % special structure that lets us avoid use of the Matlab kron
            % function, which is horribly slow.
            phiDk = zeros(ny*nu, ny*nz);
            for i = 1:nu
                for j = 1:nz
                    phiDk(ny*(i-1)+1:ny*i, ny*(j-1)+1:ny*j) = eye(ny)*Ruz(k, nz*(i-1)+j);
                end
            end
            phiD(:, nz*ny*(k-1)+1:nz*ny*k) = phiDk;
        end
    else
        phiD = [];
    end

    % Vectorize y for use in the least-squares solution.
    y = Ryz';
    y = y(:);

    % Solve the least-squares problem. Letting phi be sparse seems to
    % generally speed up the least-squares solution for large data sets.
    %
    % Update, this seems to now be slower as of Matlab 2012. Reverting back
    % to old solution.
%     phi = sparse([phiB', phiRxz0', phiD']);
    phi = [phiB', phiRxz0', phiD'];
    theta = phi\y;

    % Extract the parameters from the regressor vector.
    B_idx = 1:n*nu;
    B = reshape(theta(B_idx), n, nu);

    if solve_x0
        Rxz_idx = B_idx(end)+1:B_idx(end)+n*nz;
        Rxz0 = reshape(theta(Rxz_idx), n, nz);
    else
        Rxz0 = zeros(n, nu);
    end

    if nk == 0
        if solve_x0
            start_idx = Rxz_idx(end);
        else
            start_idx = B_idx(end);
        end
        D_idx = start_idx+1:start_idx+ny*nu;
        D = reshape(theta(D_idx), ny, nu);
    else
        D = zeros(ny, nu);
    end

end
