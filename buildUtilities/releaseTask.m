function [toolboxOptions] = releaseTask(toolboxVersion)
%GENERATETOOLBOX Function that generates a toolbox for the boss device API

arguments
    toolboxVersion (1,:) {mustBeText} = '0.0'
end

% Toolbox Parameter Configuration

toolboxFolder = "../../bossdevice-api-matlab";
identifier = "bossdevice-api-matlab";
toolboxOptions = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier);

toolboxOptions.ToolboxName = "Bossdevice API Toolbox";
toolboxOptions.ToolboxVersion = toolboxVersion;
toolboxOptions.Summary = "sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB."; 
toolboxOptions.Description = "For a more detailed description refer to the toolbox README.md file. ↵↵ Contact email: support@sync2brain.com";
toolboxOptions.AuthorName = "sync2brain";
toolboxOptions.AuthorEmail = "support@sync2brain.com";
toolboxOptions.AuthorCompany = "sync2brain";
toolboxOptions.ToolboxImageFile = "../images/toolboxPackaging.jpg";
toolboxOptions.ToolboxFiles = ["../images","../toolbox", "../LICENSE", ...
    "../README.md", "../Bossdeviceapimatlab.prj",...
     "../buildUtilities", "../resources"];
currentdir = pwd;
toolboxOptions.ToolboxMatlabPath = [currentdir(1:end-14),'toolbox'];
%toolboxOptions.AppGalleryFiles = ""; %Not applicable
toolboxOptions.ToolboxGettingStartedGuide = "../toolbox/gettingStarted.mlx";

if ~exist("../releases", 'dir')
   mkdir("../releases")
end
toolboxOptions.OutputFile = "../releases/bossdevice-toolbox-installer.mltbx";

toolboxOptions.MaximumMatlabRelease = "R2023a"; 
toolboxOptions.MinimumMatlabRelease = "R2023a"; 
toolboxOptions.SupportedPlatforms.Glnxa64 = true;
toolboxOptions.SupportedPlatforms.Maci64 = true;
toolboxOptions.SupportedPlatforms.MatlabOnline = true;
toolboxOptions.SupportedPlatforms.Win64 = true;
%toolboxOptions.ToolboxJavaPath = ""; %Not applicable

%Required Add-ons
% toolboxOptions.RequiredAddons = ...
%     [struct("Name","Simulink Desktop Real-Time", ...
%            "Identifier","WT", ...
%            "EarliestVersion","5.16", ...
%            "LatestVersion","5.16",...
%            "DownloadURL", "https://www.mathworks.com/products/simulink-desktop-real-time.html"),...
%     struct("Name","Embedded Coder", ...
%            "Identifier","EC", ...
%            "EarliestVersion","7.10", ...
%            "LatestVersion","7.10",...
%            "DownloadURL", "https://www.mathworks.com/products/simulink-desktop-real-time.html")];

% Required Additional Software 
% --> Not Applicable

% Generate toolbox
matlab.addons.toolbox.packageToolbox(toolboxOptions);

end

