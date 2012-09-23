classdef mxunit
% mxunit: An implementation of the Matlab-xUnit test framework.
% 
%   This is an implementation of the Matlab-xUnit test framework in a
%   single class. The idea is to include everything in a single file so
%   that it can be distributed with test suites for Matlab packages. The
%   original license appears below.
%
% -------------------------------------------------------------------------
% Copyright (c) 2010, The MathWorks, Inc.
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution
%     * Neither the name of the The MathWorks, Inc. nor the names
%       of its contributors may be used to endorse or promote products
%       derived from this software without specific prior written
%       permission.
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% -------------------------------------------------------------------------

    methods (Static = true)
        
% -------------------------------------------------------------------------
        function assertExceptionThrown(f, expectedId, custom_message)
%assertExceptionThrown: Assert that specified exception is thrown
% 
%   assertExceptionThrown(f, expectedId) calls the function handle f with
%   no input arguments. If the result is a thrown exception whose
%   identifier is expectedId, then assertExceptionThrown returns silently.
%   If no exception is thrown, then assertExceptionThrown throws an
%   exception with identifier equal to 'assertExceptionThrown:noException'.
%   If a different exception is thrown, then assertExceptionThrown throws
%   an exception identifier equal to
%   'assertExceptionThrown:wrongException'.
%
%   assertExceptionThrown(F, expectedId, msg) prepends the string msg to
%   the assertion message.
%
%   Example
%   -------
%   % This call returns silently.
%   f = @() error('a:b:c', 'error message');
%   assertExceptionThrown(f, 'a:b:c');
%
%   % This call returns silently.
%   assertExceptionThrown(@() sin, 'MATLAB:minrhs');
%
%   % This call throws an error because calling sin(pi) does not error.
%   assertExceptionThrown(@() sin(pi), 'MATLAB:foo');

%   Steven L. Eddins
%   Copyright 2008-2010 The MathWorks, Inc.

noException = false;
try
    f();
    noException = true;
    
catch exception
    if ~strcmp(exception.identifier, expectedId)
        message = sprintf('Expected exception %s but got exception %s.', ...
            expectedId, exception.identifier);
        if nargin >= 3
            message = sprintf('%s\n%s', custom_message, message);
        end
        throwAsCaller(MException('assertExceptionThrown:wrongException', ...
            '%s', message));
    end
end

if noException
    message = sprintf('Expected exception "%s", but none thrown.', ...
        expectedId);
    if nargin >= 3
        message = sprintf('%s\n%s', custom_message, message);
    end
    throwAsCaller(MException('assertExceptionThrown:noException', '%s', message));
end
% -------------------------------------------------------------------------
        end
    end
end