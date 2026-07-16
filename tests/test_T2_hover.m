function test_T2_hover
quad_params;
assignin('base','Cd', zeros(3));           % Drag aus -> exaktes Gleichgewicht
wh = evalin('base','w_hover');
assignin('base','w_cmd', wh*[1;1;1;1]);

out = quad_run(5);
vb = getsig(out,'v_b'); t = vb.Time; w = getcomp(out,'v_b',3);

% "Hover" heisst NICHT w=0 (Motor-Anlauf-Dip), sondern: stationaer keine Beschleunigung.
i1   = find(t >= 1, 1);                     % nach dem Anlauftransient
a_ss = (w(end) - w(i1)) / (t(end) - t(i1)); % Rest-Beschleunigung
assert(abs(a_ss) < 1e-3, 'Hover nicht im Gleichgewicht: a_ss=%.2e m/s^2', a_ss);

assert(max(abs(getcomp(out,'om',1))) < 1e-6 && max(abs(getcomp(out,'om',2))) < 1e-6 && ...
       max(abs(getcomp(out,'om',3))) < 1e-6, 'Drehraten != 0 im Hover');
assert(max(abs(getcomp(out,'v_b',1))) < 1e-3 && max(abs(getcomp(out,'v_b',2))) < 1e-3, ...
       'Seitwaertsdrift im Hover');
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
