function run_all

try
    rbis.test.test_blkhankel;
    rbis.test.test_datahankel;
    rbis.test.test_hokalman;
    rbis.test.test_nullproj;
    rbis.test.test_isInRegion;
    rbis.test.test_solveAC;
catch err
    if strcmp(err.identifier, 'MATLAB:UndefinedFunction')
        msg = sprintf('%s\n%s', err.message, ...
            'Missing files. Is mxunit in your path?');
        throw(MException('rbis:TestAll:UndefinedFunction', msg)); 
    else
        msg = sprintf('%s\n\n%s', err.message, ...
            'Core functions failed. Something is wrong. Please report this issue at http://github.com/dnmiller/rbis');
        throw(MException('rbis:TestAll:CoreTests', msg));
    end
end

if exist('sdpvar', 'file') ~= 2
    fprintf(['WARNING: YALMIP not detected on path. Semi-definite ', ...
        'constraints will not be\navailable.\n']);
end
