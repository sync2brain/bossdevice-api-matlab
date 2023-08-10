# bossdevice-api-matlab
[![CI](https://github.com/sync2brain/bossdevice-api-matlab/actions/workflows/main.yml/badge.svg)](https://github.com/sync2brain/bossdevice-api-matlab/actions/workflows/main.yml) [![GitHub issues by-label](https://img.shields.io/github/issues-raw/sync2brain/bossdevice-api-matlab/bug)](https://github.com/sync2brain/bossdevice-api-matlab/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB

## Requirements
- MATLAB&reg;
- Simulink Real-Time&reg;
- Simulink Real-Time Target Support Package
- Bossdevice firmware (MLDATX file)

## Initial configuration
1. Install the bossdevice API from MATLAB with double click on `bossdevice-api-installer.mltbx`.
2. In the MATLAB Command Window, call `bd = bossdevice` to add the bossdevice with the default settings to the list of targets. It will also try to establish connection. If you want to change either the name of the bossdevice or its default IP address in your local MATLAB settings, call `bd = bossdevice('myBossdevice','192.168.7.5')`.
3. Click on the update command if prompted to update the software dependencies on the bossdevice.

## Get started
1. Create an instance of the main control class bossdevice `bd = bossdevice` in the MATLAB command window.
2. If not found in the MATLAB path, please select `mainmodel.mldatx` real-time application.
3. Start firmware with `bd.start`.
4. Explore examples and methods available in the bossdevice object.

## User manual
For a more detailed technical guidance about how to use the API, including installation, first steps and API description, please visit our [User manual](https://usermanual.sync2brain.com/).

## Feedback, questions and troubleshooting
If you have any issue to report or enhancement to request, please create a new [Issue](https://github.com/sync2brain/bossdevice-api-matlab/issues). If you have any other topic to discuss like a question about usage, a tip to share with the community or other topic of interest, please check out our on-going [Discussions](https://github.com/sync2brain/bossdevice-api-matlab/discussions).
