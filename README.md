# sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB
[![CI](https://github.com/sync2brain/bossdevice-api-matlab/actions/workflows/main.yml/badge.svg)](https://github.com/sync2brain/bossdevice-api-matlab/actions/workflows/main.yml) [![GitHub issues by-label](https://img.shields.io/github/issues-raw/sync2brain/bossdevice-api-matlab/bug)](https://github.com/sync2brain/bossdevice-api-matlab/issues?q=is%3Aissue+is%3Aopen+label%3Abug) ![GitHub](https://img.shields.io/github/license/sync2brain/bossdevice-api-matlab) [![View bossdevice-api-matlab on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/133972-bossdevice-api-matlab)

## Requirements
- MATLAB&reg; Supported releases are R2023a and R2023b in their latest update available.
- Simulink Real-Time&reg;
- [Simulink Real-Time Target Support Package](https://www.mathworks.com/matlabcentral/fileexchange/76387-simulink-real-time-target-support-package)
- [bossdevice](https://sync2brain.com/) hardware
- bossdevice firmware (MLDATX file included in the toolbox installer)

## Enable bossdevice communication over Control PC
1. Turn on the bossdevice and connect the `Control PC` Ethernet port on your bossdevice to an available Ethernet port on your computer.
2. On your computer, follow [these steps](https://www.mathworks.com/help/slrealtime/gs/development-computer-communication-setup-windows.html) to configure the local Ethernet interface on your PC with the IP address `192.168.7.2`.
3. If you are working on Windows, please set the Development-to-Target Computer Ethernet Interface as `Private`. Follow the steps documented [here](https://www.mathworks.com/help/slrealtime/ug/troubleshoot-communication-failure-through-firewall.html).

## Initial toolbox configuration
1. Download `bossdevice-api-installer.mltbx` from the latest [release](https://github.com/sync2brain/bossdevice-api-matlab/releases) available in the GitHub project.
2. Start MATLAB and install the bossdevice API toolbox with double click on `bossdevice-api-installer.mltbx`.
3. In the MATLAB Command Window, call `bd = bossdevice` to add the bossdevice with the default settings to the list of targets. It will also try to establish connection. If you want to change either the name of the bossdevice or its default IP address in your local MATLAB settings, call `bd = bossdevice('bossdevice','192.168.7.5')` replacing the function arguments with the name and IP address you want to set on the real-time device.
4. Click on the update command if prompted to update the software dependencies on the bossdevice.

## Get started
1. Create an instance of the main control class bossdevice `bd = bossdevice` in the MATLAB command window from any working path, since the toolbox has already been added to your MATLAB path.
2. If not found in the MATLAB path or you want to use a custom firmware version, please select `mainmodel.mldatx` real-time application.
3. Initialize the bossdevice with `bd.initialize` and run the signal processing application on the remote device with `bd.start` in the MATLAB command window.
4. Explore examples with `demo_script_name` and methods available in the bossdevice object.

## User manual
Please download and install the toolbox in MATLAB for a complete access to the user manual. You will find more details about API properties and methods, example scripts and further technical information.

## Feedback, questions and troubleshooting
If you have any issue to report or enhancement to request, please create a new [Issue](https://github.com/sync2brain/bossdevice-api-matlab/issues). If you have any other topic to discuss like a question about usage, a tip to share with the community or other topic of interest, please check out our on-going [Discussions](https://github.com/sync2brain/bossdevice-api-matlab/discussions).
