% ---- Quadrocopter-Parameter (F450, Prop Ø 254 mm — SYS1-012) ----
% kT und w_max GEMESSEN am Schubstand (Run 3, 2026-10-15, X2216-III 880 KV +
% HQProp 10x4.5, 14,8 V Netzteil; QuadSE/evidence/INDEX.md Zeile BB9B34CB480DCC42,
% Herleitung analysis/propulsion_rig_run3.m, Gate Chris 2026-10-16). kQ ist eine
% SCHÄTZUNG (kein Drehmomentsensor), tau und m bleiben Platzhalter.
% MIX_inv ist in sil/flight_ctrl_lct.c und AurixTricore/src/asw/CtrlReplay.c
% ausgerollt — kT/kQ/w_max IMMER an allen drei Stellen zusammen ändern.
m    = 1.20;                % kg   Abflugmasse
g    = 9.81;                % m/s^2
l    = 0.225;               % m    Armlänge Zentrum->Rotor
d    = l/sqrt(2);           % m    effektiver Hebelarm (X-Konfig)
Ixx  = 1.0e-2;  Iyy = 1.0e-2;  Izz = 1.8e-2;   % kg m^2
Ivec = [Ixx; Iyy; Izz];
kT   = 1.162e-5;            % N/(rad/s)^2   Schubkoeffizient, GEMESSEN: Sekante T/w^2 im Schwebepunkt
                            %   (300 g/Motor = 4806 rpm = 503,3 rad/s); LS-Fit >= 2000 rpm = 1.203e-5,
                            %   Exponent 2,20 -> Schubfehler +12 % bei 100 g, 0 im Schweben, -6 % bei 770 g
kQ   = 1.66e-7;             % Nm/(rad/s)^2  Momentenkoeffizient, SCHÄTZUNG: eta*(U*I-1,1 W)/w^3 im
                            %   Schwebepunkt mit eta = 0,70 (ESC+Motor); Band 0,60..0,80 -> 1.42e-7..1.90e-7.
                            %   Offen bis Drehmomentmessung (Reaktionsarm am Motorhalter)
tau  = 0.05;                % s    Zeitkonstante Motor+ESC — PLATZHALTER, nicht gemessen (Sprung mit
                            %   bidir eRPM bei 1 kHz aufzeichnen)
w_max= 782;                 % rad/s Mixer-Grenze = Spitze des gemessenen Sweeps (sp 1500, 7471 rpm,
                            %   770 g, 7,85 A) — Sweep-Grenze (Prop gelöst), nicht die Motorgrenze
Cd   = diag([0.10 0.10 0.15]);  % linearer Drag [N/(m/s)]
h0 = 2;


% ---- Mixer (Konvention aus Abschnitt 03) ----
MIX = [ kT     kT     kT     kT;
       -d*kT  -d*kT   d*kT   d*kT;
        d*kT  -d*kT  -d*kT   d*kT;
        kQ    -kQ     kQ    -kQ ];

MIX_inv = inv(MIX);

% controller parameters
% Drehraten controller; inner control loop
tau_kP = [0.10;0.10;0.216];
tau_kI = [0.125;0.125;0.324];
tau_sat_up = [1.3;1.3;0.08];
tau_sat_low =[-1.3;-1.3;-0.08];

% Lage controller; middle control loop
om_kP = [3;3;3];

% Position NED controller
ned_xy_kP = [1.44; 1.44];
ned_xy_kD = 1.92;
ned_z_kP  = 2.7;
ned_z_kD  = 2.5;

axis_switch = [0 1;
               -1 0];
% Integrator init
phi_dot_to_phi = [0;0;0];
p_ned_dot_to_p_ned = [0;0;0];
v_dot_to_v_b = [0;0;0];
om_dot_to_om = [0; 0; 0];
pt1_w_cmd_to_w = zeros(4,1);

% Diskretisierung
Ts = 0.001;    %s   Abtastzeit Regler (1 kHz)

% Subsystem variant
CTRL_IMPL = 1; % 1 = Simulink-Regler, 2 = C-Code (S-Function)


% ---- Trimm: Schwebedrehzahl aus 4*kT*w^2 = m*g ----
w_hover = sqrt(m*g/(4*kT));           % -> 503.3 rad/s (4806 rpm), muss < w_max sein!
fprintf('Hover: %.1f rad/s (%.0f%% von w_max)\n', w_hover, 100*w_hover/w_max);