function startup
%STARTUP  Puts the project folders on the MATLAB path.
%
%   Run once per MATLAB session from the repository root:
%
%       startup
%
%   Replaces the former MATLAB Project (Quadrocopter.prj). Everything the
%   scripts need is the path — quad_params.m, quad_run.m and the model files
%   live in the root, the rest sits in the four subfolders added below.

here = fileparts(mfilename('fullpath'));

folders = { here                          % models, quad_params, quad_run
            fullfile(here, 'tests')       % MiL test suite T1-T8
            fullfile(here, 'sil')         % C controller + legacy_code wrappers
            fullfile(here, 'pil')         % vector replay harness
            fullfile(here, 'linearize') };% trim + linearisation

for k = 1:numel(folders)
    if exist(folders{k}, 'dir')
        addpath(folders{k});
    else
        warning('quad:startup', 'Folder not found, skipped: %s', folders{k});
    end
end

fprintf('Quadrocopter project path set (%d folders).\n', numel(folders));
end
