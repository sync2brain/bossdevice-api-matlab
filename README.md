# bossdevice-api-matlab
sync2brain's bossdevice RESEARCH Application Programmable Interface (API) for MATLAB

## Requirements
- MATLAB
- Simulink Real-Time
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
