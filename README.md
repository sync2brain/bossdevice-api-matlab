# sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB
[![CI](https://github.com/sync2brain/bossdevice-api-matlab/actions/workflows/main.yml/badge.svg)](https://github.com/sync2brain/bossdevice-api-matlab/actions/workflows/main.yml) [![GitHub issues by-label](https://img.shields.io/github/issues-raw/sync2brain/bossdevice-api-matlab/bug)](https://github.com/sync2brain/bossdevice-api-matlab/issues?q=is%3Aissue+is%3Aopen+label%3Abug) ![GitHub](https://img.shields.io/github/license/sync2brain/bossdevice-api-matlab) [![View bossdevice-api-matlab on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/133972-bossdevice-api-matlab) [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=sync2brain/bossdevice-api-matlab&project=Bossdeviceapimatlab.prj)

## Requirements
- MATLAB&reg; R2024a or newer.
- [Simulink&reg; Real-Time&trade;](https://www.mathworks.com/products/simulink-real-time.html)
- [Simulink&reg; Real-Time&trade; Target Support Package](https://www.mathworks.com/matlabcentral/fileexchange/76387-simulink-real-time-target-support-package) (no additional license required, installable from within MATLAB when you have Simulink Real-Time installed)
- [bossdevice&reg; real-time digital processor](https://sync2brain.com/boss-device-research)
- [bossdevice&reg; firmware](https://sync2brain.com/bossdevice-research-downloads)
### Optional
The following products are required for some advanced functionality such as designing custom filters but are not strictly required for a standard operation or triggering of the bossdevice.
- [Signal Processing Toolbox&trade;](https://www.mathworks.com/products/signal.html)

## Enable bossdevice communication over Control PC
This step is strictly required to enable communication between the Control PC and the bossdevice over a point-to-point Ethernet connection. If your bossdevice is on, you cannot establish a connection from MATLAB or you get an error message like `Error communicating with target '192.168.7.5': Unable to connect to target computer '192.168.7.5': No response from target computer after 10 pings.`, this step is probably not fully completed yet.
1. Turn on the bossdevice and connect the `Control PC` Ethernet port on your bossdevice to an available Ethernet port on your computer.
2. On your computer, follow [these steps](https://www.mathworks.com/help/slrealtime/gs/development-computer-communication-setup-windows.html) to configure the local Ethernet interface on your PC with the IP address `192.168.7.2`. Please note you may use as well a different local IP address on your PC as long as it is different from the bossdevice's IP address and it is located in the same subnet. This enables eventual access over an internal network too.
3. The first time you connect from within MATLAB to the bossdevice, you may see a user prompt from your firewall. Please accept or allow the connection between the Control PC and the bossdevice.
![image](https://github.com/user-attachments/assets/ee89285f-68e3-4102-a68b-03c2160c2b33)

### Optional
If you cannot connect to the bossdevice facing message errors like `Error: Cannot connect to target 'bossdevice': Cannot connect to target.` or experience frequent disconnection issues, please check out the following recommended steps.

4. If you are working on Windows, to ensure a stable and robust connection between the development PC and the bossdevice, please start PowerShell with administrator rights, and execute the command `New-NetFirewallRule -DisplayName "bossdevice" -Direction Inbound -RemotePort 5505-5507,5510-5512,5515-5517 -Protocol UDP -Action Allow -Profile Any -RemoteAddress 192.168.7.5`. See [reference](https://www.mathworks.com/matlabcentral/answers/2020516-how-can-i-establish-communication-with-a-speedgoat-target-computer-via-an-ethernet-interface-configu).

## Installation and initial toolbox configuration
1. Download `bossdevice-api-installer.mltbx` from the latest [release](https://github.com/sync2brain/bossdevice-api-matlab/releases) available in the GitHub project.
2. Download the bossdevice firmware binary file for your MATLAB Release from [our downloads portal](https://sync2brain.com/bossdevice-research-downloads).
3. Start MATLAB and install the bossdevice API toolbox with double click on `bossdevice-api-installer.mltbx`.
4. In the MATLAB Command Window, call `bd = bossdevice` to add the bossdevice with the default settings to the list of targets. If you want to change either the name of the bossdevice or its default IP address in your local MATLAB settings, call `bd = bossdevice('bossdevice','192.168.7.5')` replacing the function arguments with the name and IP address you want to set on the real-time device.
5. When prompted, select the bossdevice firmware binary file with the mldatx extension you have downloaded above. Please note you may run `bd.installFirmwareOnToolbox` afterwards to copy the firmware file into your local toolbox folder, so that you can skip this step in later sessions.
6. Open the documentation `openBossdeviceDoc` or `bd.doc`.

Optionally, for more information about how to get, install and manage add-ons for MATLAB like the bossdevice API toolbox, please visit [this documentation page](https://www.mathworks.com/help/matlab/matlab_env/get-add-ons.html).

## Get started
1. Create an instance of the main control class bossdevice `bd = bossdevice` in the MATLAB command window from any working path, since the toolbox has already been added to your MATLAB path.
2. If not found in the MATLAB path or you want to use a custom firmware version, please select `mainmodel.mldatx` real-time application.
3. Initialize the bossdevice with `bd.initialize`.
4. If your version of the bossdevice does not match your current version of MATLAB, you may get a `Target computer software version mismatch` error. In that scenario, please simply click on the underlined `update(tg)` command. The bossdevice hardware will be upgraded automatically. After some seconds, you can rerun `bd.initialize`.
5. Run the signal processing application on the remote device with `bd.start` in the MATLAB command window.
6. Open the documentation `openBossdeviceDoc` and explore examples with `demo_script_name` and methods available in the bossdevice object.

## User manual
Visit our online documentation available [here](https://sync2brain.github.io/bossdevice-api-matlab/).

Download and install the toolbox in MATLAB for a complete access to the user manual with the command `openBossdeviceDoc` in the MATLAB console. You will find more details about API properties and methods, example scripts and further technical information.

## Feedback, questions and troubleshooting
If you have any issue to report or enhancement to request, please create a new [Issue](https://github.com/sync2brain/bossdevice-api-matlab/issues). If you have any other topic to discuss like a question about usage, a tip to share with the community or other topic of interest, please check out our on-going [Discussions](https://github.com/sync2brain/bossdevice-api-matlab/discussions).
