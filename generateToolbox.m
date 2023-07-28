function [toolboxOptions] = generateToolbox(toolboxVersion)
%GENERATETOOLBOX Function that generates a toolbox for the boss device API

version = toolboxVersion;

% Toolbox Parameter Configuration

toolboxFolder = "../bossdevice-api-matlab";
identifier = "bossdevice-api-matlab";
opts = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier);

opts.ToolboxName = "Bossdevice API Toolbox";
opts.ToolboxVersion = version; % Should be set by Github action
opts.Summary = "sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB."; 
opts.Description = "For a more detailed description refer to the toolbox README.md file. Contact email: support@sync2brain.com";
opts.AuthorName = "sync2brain";
opts.AuthorEmail = "support@sync2brain.com";
opts.AuthorCompany = "sync2brain";
opts.ToolboxImageFile = "./images/toolboxPackaging.jpg";
opts.ToolboxFiles = ["./images","./toolbox", "LICENSE", "README.md", ".gitignore", ".gitattributes"];
opts.ToolboxMatlabPath = "./toolbox";
%opts.AppGalleryFiles = ""; %Not applicable
opts.ToolboxGettingStartedGuide = "./toolbox/gettingStarted.mlx";
opts.OutputFile = "./releases/bossdevice-toolbox-installer.mltbx";
opts.MaximumMatlabRelease = ""; %TBD
opts.MinimumMatlabRelease = ""; %TBD
opts.SupportedPlatforms.Glnxa64 = true;
opts.SupportedPlatforms.Maci64 = true;
opts.SupportedPlatforms.MatlabOnline = true;
opts.SupportedPlatforms.Win64 = true;
%opts.ToolboxJavaPath = ""; %Not applicable

% %Required Add-ons (TO BE CONFIRMED)
% opts.RequiredAddons = ...
%     struct("Name","Embedded Coder", ...
%            "Identifier","xxx", ...   % TBC Identifier missing
%            "EarliestVersion","7.0", ...
%            "LatestVersion","7.10", ...
%            "DownloadURL","https://www.mathworks.com/products/embedded-coder.html");
% 
% opts.RequiredAddons = ...
%     struct("Name","Simulink Desktop Real-Time", ...
%            "Identifier","xxx", ...  % TBC Identifier missing
%            "EarliestVersion","5.0", ...
%            "LatestVersion","5.16", ...
%            "DownloadURL","https://www.mathworks.com/products/simulink-desktop-real-time.html");

% Required Additional Software 
% --> Not Applicable

toolboxOptions = opts;

% Generate toolbox
matlab.addons.toolbox.packageToolbox(opts);

end

