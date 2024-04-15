function openBossdeviceDoc
%OPENBOSSDEVICEDOC Open the bossdevice documentation
%   Prompts user to build HTML documentation if not available or open doc sources

thisFolder = fileparts(which(mfilename));
docInit = fullfile(thisFolder,'bossdevice_api_landing_page.html');

if ~exist(docInit,'file')
    answer = questdlg('HTML documentation was not found. Do you want to build it from sources now or open the doc sources directly?',...
        'HTML documentation not found',...
        'Build HTML doc','Open doc sources','Cancel','Open doc sources');
    switch answer
        case 'Build HTML doc'
            buildDoc;
            openDoc = true;
        case 'Open doc sources'
            open('docSource/bossdevice_api_landing_page.mlx');
            openDoc = false;
        case 'Cancel'
            openDoc = false;
    end
else
    openDoc = true;
end

if openDoc
    web(docInit);
end

end