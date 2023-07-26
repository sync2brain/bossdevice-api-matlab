# bossdevice-api-matlab
sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB

## Requirements
- MATLAB&reg;
- Simulink Real-Time&reg;
- Simulink Real-Time Target Support Package
- Bossdevice firmware (MLDATX file)

## Initial configuration
1. Open Simulink Real-Time Explorer, running `slrtExplorer` in the MATLAB command window
2. In the list of target computers, select the default entry and in the Target Configurat tab
    1. Enter `bossdevice` into the name field
    2. Enter your bossdevice IP address. By default, this value is `192.168.7.5`
5. Click on the Update Software button

## Get started
1. Start MATLAB project with double-click on Bossdeviceapimatlab.prj
2. Move or copy `mainmodel.mldatx` real-time application file into the work folder
3. Create an instance of the main control class bossdevice `bd = bossdevice`
4. Start firmware with `bd.targetObject.start`
5. Explore examples and methods available in the bossdevice object

## User manual
For a more detailed technical guidance about how to use the API, including installation, first steps and API description, please visit our [User manual](https://usermanual.sync2brain.com/).

## Feedback, questions and troubleshooting
If you have any issue to report or enhancement to request, please create a new [Issue](https://github.com/sync2brain/bossdevice-api-matlab/issues). If you have any other topic to discuss like a question about usage, a tip to share with the community or other topic of interest, please check out our on-going [Discussions](https://github.com/sync2brain/bossdevice-api-matlab/discussions).
