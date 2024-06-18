function toolboxOptions = releaseTask(toolboxVersion, authorName)
%GENERATETOOLBOX Function that generates a toolbox for the boss device API

arguments
    toolboxVersion string {mustBeTextScalar} = '0.0'
    authorName string {mustBeTextScalar} = "sync2brain" % Use committer name when packaging from CI
end

% Get current project object
projObj = currentProject;

% Remove v from toolboxVersion
options.toolboxVersion = erase(toolboxVersion,"v");

% Toolbox Parameter Configuration
toolboxOptions = matlab.addons.toolbox.ToolboxOptions(fullfile(projObj.RootFolder,"toolbox"), "71e8748d-9f0b-4242-b8f1-1d61b60aa4dc");

toolboxOptions.ToolboxName = "Bossdevice API Toolbox";
toolboxOptions.ToolboxVersion = options.toolboxVersion;
toolboxOptions.Summary = projObj.Description;
toolboxOptions.Description = "For a more detailed description refer to the toolbox README.md file. ↵↵ Contact email: support@sync2brain.com";
toolboxOptions.AuthorName = authorName;
toolboxOptions.AuthorEmail = "support@sync2brain.com";
toolboxOptions.AuthorCompany = "sync2brain";
toolboxOptions.ToolboxImageFile = fullfile(projObj.RootFolder,"images/bossdevice.jpg");
% toolboxOptions.ToolboxGettingStartedGuide = fullfile(projObj.RootFolder,"toolbox/gettingStarted.mlx");

if ~exist(fullfile(projObj.RootFolder,"releases"), 'dir')
   mkdir(fullfile(projObj.RootFolder,"releases"))
end
toolboxOptions.OutputFile = fullfile(projObj.RootFolder,"releases/bossdevice-api-installer.mltbx");

toolboxOptions.MinimumMatlabRelease = "R2023b";
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
