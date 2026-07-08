function setupAddon(~)
% This is the workaround required to run the pipeline on R2024b after the bug introduced in add-ons path in Update 8

if batchStartupOptionUsed && ~isMATLABReleaseOlderThan("R2024b","release",8) && isMATLABReleaseOlderThan("R2025a")
    matlab.addons.install(fullfile(getenv('USERPROFILE'),'Downloads','Advanced.Logger.for.MATLAB.2.0.2.mltbx'));
    matlab.addons.install(fullfile(getenv('USERPROFILE'),'Downloads','streaming-instrumentation-utils-SLRT-v1.0.0.mltbx'));
end

end
