function testTask(~)
        % Run unit tests
        testlist = '../tests';
        
        if ~exist("../tests", 'dir')
            
            disp('No tests have been defined')

        else
           
            results = runtests(testlist,OutputDetail="terse");
            assertSuccess(results);
            
        end

end

