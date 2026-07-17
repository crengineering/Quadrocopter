function test_T7_yawrate
%T7  Drallerhaltung: mit Anfangs-Gierrate und ohne Moment muss r konstant bleiben.
%   Voraussetzung: IC des om-Integrators ist auf Parameter 'om0' gesetzt.
evalin('base','quad_params;');                     % sauberer Ausgangszustand
r0 = 0.5;
assignin('base','om0', [0;0;r0]);
c = onCleanup(@() assignin('base','om0', [0;0;0]));  % om0 nicht in Folgetests lassen
assignin('base','Cd', zeros(3));
wh = evalin('base','w_hover');
assignin('base','w_cmd', wh*[1;1;1;1]);            % Hover -> kein Moment

out = quad_run(2, 'quad_model_ST');
r = getcomp(out,'om',3);

if abs(r(1) - r0) > 1e-3                            % Anfangsrate kam nicht an?
    error('quad:skip', ...
        ['Anfangs-Gierrate nicht wirksam (r(0)=%.3f statt %.1f). ' ...
         'IC des om-Integrators auf Parameter ''om0'' setzen.'], r(1), r0);
end
assert(max(abs(r - r0)) < 1e-6, 'Drallerhaltung verletzt: max|r-r0|=%.2e', max(abs(r-r0)));
end

% ---- Lokale Helfer (Signalzugriff) ----------------------------------------
function ts = getsig(out, name)
%GETSIG  Geloggtes Signal 'name' als timeseries aus out.logsout holen.
el = out.logsout.get(name);
if isempty(el)
    error('quad:signal', ...
        'Signal ''%s'' nicht in logsout gefunden -- Logging im Modell pruefen.', name);
end
if isa(el, 'Simulink.SimulationData.Dataset')      % doppelte Signalnamen
    el = el{1};
end
ts = el.Values;
end

function x = getcomp(out, name, i)
%GETCOMP  i-te Komponente des Signals 'name' ueber der Zeit (Spaltenvektor).
ts = getsig(out, name);
d  = ts.Data;
if ndims(d) == 3                                   % Logform [3x1xN]
    x = squeeze(d(i,1,:));
else                                               % Logform [Nx3]
    x = d(:,i);
end
x = x(:);                                          % immer Spaltenvektor
end
