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
toolboxOptions.ToolboxImageFile = "images/toolboxPackaging.jpg";
toolboxOptions.ToolboxGettingStartedGuide = "toolbox/gettingStarted.mlx";

if ~exist("releases", 'dir')
   mkdir("releases")
end
toolboxOptions.OutputFile = "releases/bossdevice-api-installer.mltbx";

toolboxOptions.MinimumMatlabRelease = "R2023a";
% toolboxOptions.MaximumMatlabRelease = "R2023a"; % Won't limit maximum MATLAB release
toolboxOptions.SupportedPlatforms.Glnxa64 = true;
toolboxOptions.SupportedPlatforms.Maci64 = false;
toolboxOptions.SupportedPlatforms.MatlabOnline = false;
toolboxOptions.SupportedPlatforms.Win64 = true;

%Required Add-ons
% Extracted information from matlab.addons.installedAddons
% RequiredAddons is commented out due to unexpected errors installing the toolbox as of R2023aU4
% toolboxOptions.RequiredAddons = ...
%     [struct("Name","Simulink Real-Time", ...
%            "Identifier","XP", ...
%            "EarliestVersion","8.2", ...
%            "LatestVersion","latest", ...
%            "DownloadURL","https://www.mathworks.com/products/simulink-real-time.html"),...
%     struct("Name","Simulink Real-Time Target Support Package", ...
%            "Identifier","SLRT_QNX", ...
%            "EarliestVersion","23.1.0", ...
%            "LatestVersion","latest", ...
%            "DownloadURL", "https://www.mathworks.com/matlabcentral/fileexchange/76387-simulink-real-time-target-support-package")];

% Required Additional Software
% TODO: Automate download and installation of bossdevice firmware. DownloadURL must point to an installer, generic file is not supported as of R2023aU4
% toolboxOptions.RequiredAdditionalSoftware = ...
%     struct("Name","Bossdevice firmware", ...
%            "Platform","win64", ...
%            "DownloadURL","https://sync2brain.com/downloads", ...
%            "LicenseURL","https://sync2brain.com/wp-content/uploads/2022/06/sync2brain-bossdevice-research-EULA_V1.0.pdf");

% Generate toolbox
matlab.addons.toolbox.packageToolbox(toolboxOptions);

end