function test_T1_freefall
% Reiner Integrations-/Gravitationstest -> Drag für diesen Fall AUS,
% sonst bremst -Cd*v_b und w(1s) < 9.81 (kein analytischer Sollwert mehr).
assignin('base','w_cmd',[0;0;0;0]);       % alle Motoren aus
Cd_save = evalin('base','Cd');
assignin('base','Cd', zeros(3));
c = onCleanup(@() assignin('base','Cd', Cd_save));  % danach zurücksetzen

out = quad_run(1, 'quad_model_ST');
names = out.logsout.getElementNames;
assert(any(strcmp(names,'v_b')), 'Signal v_b nicht geloggt.');

vb = out.logsout.get('v_b').Values;
w_end = squeeze(vb.Data(3,1,:));               % robust gg. 1-D/2-D-Logform
w_end = w_end(end)
assert(abs(w_end - 9.81) < 0.02, 'T1 FAIL: w(1s)=%.3f, erwartet 9.81', w_end);
end