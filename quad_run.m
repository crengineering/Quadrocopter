function simOut = quad_run(stopTime)
mdl = 'quad_model';
quad_params;
if ~bdIsLoaded(mdl), load_system(mdl); end

refs = find_mdlrefs(mdl);
for k = 1:numel(refs)
    if ~bdIsLoaded(refs{k}), load_system(refs{k}); end
    applyConfig(refs{k}, 'quadCfg');
end

if nargin >= 1, set_param(mdl, 'StopTime', num2str(stopTime)); end
simOut = sim(mdl);
end

function applyConfig(mdl, cfgName)
cfg = code_config();
cfg.Name = cfgName;
try                                            % am ConfigSet, nicht am Modell
    cfg.set_param('MinAlgLoopOccurrences','on');
catch
    warning('quad:minalg', ...
        'MinAlgLoopOccurrences nicht setzbar — in der Simulink-GUI setzen und code_config neu exportieren.');
end
if any(strcmp(getConfigSets(mdl), cfgName))
    if strcmp(getActiveConfigSet(mdl).Name, cfgName)
        others = setdiff(getConfigSets(mdl), cfgName);
        setActiveConfigSet(mdl, others{1});
    end
    detachConfigSet(mdl, cfgName);
end
attachConfigSet(mdl, cfg);
setActiveConfigSet(mdl, cfgName);
end