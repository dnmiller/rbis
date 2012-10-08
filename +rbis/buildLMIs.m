function [P, Q, M] = buildLMIs(n, props, args)
%buildLMIs: Construct LMIs to describe a convex region of the complex
%plane.
% 
%   [P, Q, M] = buildLMIs(n, props, args)
% 
%       Construct YALMIP LMI objects that describe a convex region of the
%       complex plane. P is a symmetric matrix, Q is a full matrix, and M
%       is a matrix containing the n x n matrices P and Q that describes an
%       LMI region. The LMIs are such that any set (P, Q, M) for which P >=
%       0 and M >= 0 will have a third parameter A = P\Q which has
%       eigenvalues within the complex plane described by M.
% 
%       The props parameter describes the LMI regions. There are three
%       combinations of LMI regions, and any intersection of the three also
%       forms an LMI region. The three regions have the following possible
%       descriptions:
% 
%           - 'Stable' - force stable eigenvalues
%               - requires all eigenvalues to satisfy |z| < 1 - ds
%               - ds may be optionally set by the 'DeltaS' property
%               - by default, ds = 1e-4
% 
%           - 'Real' - force strictly real eigenvalues
%               - requires all eigenvalues to satisfy |Im(z)| < dr.
%               - dr may be optionally set by the 'DeltaR' property.
%               - by default, dr = 1e-8.
% 
%           - 'Positive' - force eigenvalues with positive real parts
%               - requires all eigenvalues to satisfy Re(z) > dp.
%               - dp may be optionally set by the 'DeltaP' property.
%               - by default, dp = 1e-4.
% 
%       props may be either a string or a cell array of strings. args are
%       the Delta* properties described in Property, Value pairs.
% 
%       Examples:
% 
%           [P, Q, M] = buildLMIs(5, 'Stable', 'DeltaS', 0.1)
% 
%           P, Q, and M will be such that the eigenvalues of the 5 x 5
%           matrix P\Q has eigenvalues within the circle of radius 1 - 0.1.
% 
%           [P, Q, M] = buildLMIs(10, {'Stable', 'Positive'})
% 
%           P, Q, and M will be such that the eigenvalues of the 10 x 10
%           matrix P\Q has eigenvalues within the circle of radius 1 - 1e-4
%           and of real part > 1e-8.
% 
%       A call to YALMIP such as
% 
%       solvesdp([P >= 0; M >= 0], J)
% 
%       will minimize the cost-function J, which is likely a YALMIP object
%       described in terms of P and Q.
% 
% Source: Miller, de Callafon, "Subspace Identification with Eigenvalue
% Constraints," to appear in Automatica sometime in 2012 or 2013.

% (C) D. Miller, 2012.

% TODO: parse props.
    if isempty(props.DeltaS)
        ds = 1e-4;
    else
        ds = props.DeltaS;
    end
    
    if isempty(props.DeltaR)
        dr = 1e-8;
    else
        dr = props.DeltaR;
    end
    
    if isempty(props.DeltaP)
        dp = 1e-4;
    else
        dp = props.DeltaP;
    end
    
    P = sdpvar(n);
    Q = sdpvar(n, n, 'full');

    % This is our constraint matrix. It is a block-diagonal matrix
    % in which each constraint corresponds to one block.
    M = [];

    if any(strcmpi(props.Eigenvalues, 'Stable'));
        M = blkdiag(M, [
                (1 - ds)*P,     Q;
                Q',             (1 - ds)*P]);
    end

    if any(strcmpi(props.Eigenvalues, 'Real'))
        M = blkdiag(M, [
                dr*P,           0.5*(Q' - Q)
                0.5*(Q - Q'),   dr*P]);
    end

    if any(strcmpi(props.Eigenvalues, 'Positive'));
        M = blkdiag(M, [
                2*dp*P,         zeros(n);
                zeros(n),       Q + Q' - 2*dp*P]);
    end
end
