function myToolboxFactoryTree = createToolboxFactoryTree()
    myToolboxFactoryTree = matlab.settings.FactoryGroup.createToolboxGroup('bossdeviceAPI', ...
        'Hidden',false);

    tgGroup = addGroup(myToolboxFactoryTree,'TargetSettings','Hidden',false);
    addSetting(tgGroup,'TargetName','FactoryValue','bossdevice','Hidden',false,'ValidationFcn',@mustBeTextScalar);
    addSetting(tgGroup,'TargetIPAddress','FactoryValue','192.168.7.5','Hidden',false,'ValidationFcn',@mustBeTextScalar);
end