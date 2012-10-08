classdef config
%configuration options for rbis. 
% 
% These are designed to mostly help not crash Matlab by not overflowing
% memory in a call to SeDuMi or something similar. Modify them at your own
% risk.

% (C) D. Miller, 2012.
    properties (Constant = true)
        MAX_DATAHANKEL_ROWS = 3000
        MAX_DATAHANKEL_ROWS_DOC = 'Maximum number of total rows allowed for data hankel matrices.';
        
        MAX_DATAHANKEL_COLS = 5000
        MAX_DATAHANKEL_COLS_DOC = 'Maximum number of total columns allowed for data hankel matrices.';
        
        % Used for pretty-printing.
        PKGNAME = 'rbis'
    end
    
    methods
        function str = printParam(obj, name)
        % Pretty-print for configuration parameter names and values.
            val = obj.(name);
            doc = obj.([name, '_DOC']);
            str = sprintf(['    ', name, ' (', num2str(val), ')\n      ', doc, '\n']);         
        end
        
        function disp(obj)
        % What to display in the command window.
            fprintf([...
'  RBIS Configuration Parameters:\n'...
'  ------------------------------\n'...
'  These are default configuration parameters for RBIS. They are intended\n'...
'  to prevent Matlab from crashing. Edit the  file "rbis.config.m" to \n'...
'  change (at your own risk).\n\n'...
obj.printParam('MAX_DATAHANKEL_ROWS'), '\n' ...
obj.printParam('MAX_DATAHANKEL_COLS'), '\n']);
        end
    end
end

