function test_T3_climb
%T3  Steigflug: 1.05*w_hover -> stationaere Beschl. ~ g*(1.05^2-1) ~ 1.0 m/s^2 aufwaerts.
%   WICHTIG: Erst nach dem Motor-Anlauf messen. Der Nulldurchgang von w (Sinken->Steigen)
%   kommt je nach Motor-Zeitkonstante spaeter, daher 2 s simulieren und Fenster [1,2] s.
quad_params;
assignin('base','Cd', zeros(3));
wh = evalin('base','w_hover');
assignin('base','w_cmd', 1.05*wh*[1;1;1;1]);

out = quad_run(2, 'quad_model_ST');
vb = getsig(out,'v_b'); t = vb.Time; w = getcomp(out,'v_b',3);

i1 = find(t >= 1, 1);                              % sicher eingeschwungen
a  = (w(end) - w(i1)) / (t(end) - t(i1));          % w=down-Komp. -> Steigflug => a<0
assert(a < 0, 'Steigflug: Beschleunigung nicht aufwaerts (a=%.3f) -- w steigt noch? Fenster/Motoranlauf pruefen', a);
assert(abs(abs(a) - 1.006) < 0.15, 'Steigflug: |a|=%.3f, erwartet ~1.0 m/s^2', abs(a));
end

% ================= lokale Helfer (keine externen Dateien nötig) =================
function ts = getsig(out, name)
el = out.logsout.get(name);
if isempty(el)
    error('quad:nolog', 'Signal "%s" ist nicht geloggt (benennen + Log-Haken setzen).', name);
end
if isa(el, 'Simulink.SimulationData.Dataset'), el = el{1}; end   % Duplikate abfangen
ts = el.Values;
end

function v = getcomp(out, name, i)
d = getsig(out, name).Data;
if ndims(d) == 3, v = squeeze(d(i,1,:)); else, v = d(:,i); end   % [3x1xN] oder [Nx3]
v = v(:);
end