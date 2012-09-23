function varargout = version
% version: Return the current version of the GRA toolbox.
%
%   Prints current version to command window if no output argument present.
%   Returns a string with current version if output argument is present.

v = '0.2';

if nargout == 0
    fprintf('Realization-Based Identification Software - v. %s\n', v);
elseif nargout == 1
    varargout{1} = v;
end

end