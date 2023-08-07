function toolboxOptions = releaseTask(toolboxVersion)
%GENERATETOOLBOX Function that generates a toolbox for the boss device API

arguments
    toolboxVersion {mustBeTextScalar} = '0.0'
end

projObj = currentProject;

% Toolbox Parameter Configuration
toolboxOptions = matlab.addons.toolbox.ToolboxOptions(fullfile(projObj.RootFolder,"toolbox"), "bossdevice-api-matlab");

toolboxOptions.ToolboxName = "Bossdevice API Toolbox";
toolboxOptions.ToolboxVersion = toolboxVersion;
toolboxOptions.Summary = "sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB."; 
toolboxOptions.Description = "For a more detailed description refer to the toolbox README.md file. ↵↵ Contact email: support@sync2brain.com";
toolboxOptions.AuthorName = "sync2brain";
toolboxOptions.AuthorEmail = "support@sync2brain.com";
toolboxOptions.AuthorCompany = "sync2brain";
toolboxOptions.ToolboxImageFile = fullfile(projObj.RootFolder,"images/sync2brain-Logo-hell.png");
toolboxOptions.ToolboxGettingStartedGuide = fullfile(projObj.RootFolder,"toolbox/gettingStarted.mlx");

if ~exist(fullfile(projObj.RootFolder,"releases"), 'dir')
   mkdir(fullfile(projObj.RootFolder,"releases"))
end
toolboxOptions.OutputFile = fullfile(projObj.RootFolder,"releases/bossdevice-api-installer.mltbx");

toolboxOptions.MinimumMatlabRelease = "R2023a";
% toolboxOptions.MaximumMatlabRelease = "R2023a"; % Won't limit maximum MATLAB release
toolboxOptions.SupportedPlatforms.Glnxa64 = true;
toolboxOptions.SupportedPlatforms.Maci64 = false;
toolboxOptions.SupportedPlatforms.MatlabOnline = false;
toolboxOptions.SupportedPlatforms.Win64 = true;

% Required Additional Software
% TODO: Automate download and installation of bossdevice firmware. DownloadURL must point to a ZIP file (MLDATX firmware fiel) in the downloads section of sync2brain
% toolboxOptions.RequiredAdditionalSoftware = ...
%     struct("Name","Bossdevice firmware", ...
%            "Platform","win64", ...
%            "DownloadURL","https://sync2brain.com/downloads", ...
%            "LicenseURL","https://sync2brain.com/wp-content/uploads/2022/06/sync2brain-bossdevice-research-EULA_V1.0.pdf");

% Generate toolbox
matlab.addons.toolbox.packageToolbox(toolboxOptions);

end