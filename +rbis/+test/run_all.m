function run_all

try
    rbis.test.test_blkhankel;
    rbis.test.test_datahankel;
catch err
    msg = sprintf('%s\n\n%s', err.message, ...
    	'Core functions failed. Something is wrong. Please report this error.');
    throw(MException('rbis:TestAll:CorTests', msg));
end
