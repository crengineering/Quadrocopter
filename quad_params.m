% ---- Quadrocopter-Parameter (Beispiel: 450er-Klasse) ----
m    = 1.20;                % kg   Abflugmasse
g    = 9.81;                % m/s^2
l    = 0.225;               % m    Armlänge Zentrum->Rotor
d    = l/sqrt(2);           % m    effektiver Hebelarm (X-Konfig)
Ixx  = 1.0e-2;  Iyy = 1.0e-2;  Izz = 1.8e-2;   % kg m^2
Ivec = [Ixx; Iyy; Izz];
kT   = 5.0e-6;              % N/(rad/s)^2   Schubkoeffizient
kQ   = 5.0e-8;              % Nm/(rad/s)^2  Momentenkoeffizient
tau  = 0.05;                % s    Zeitkonstante Motor+ESC
w_max= 1200;                % rad/s max. Rotordrehzahl
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
ned_xy_kP = [1.44, 1.44];
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


% ---- Trimm: Schwebedrehzahl aus 4*kT*w^2 = m*g ----
w_hover = sqrt(m*g/(4*kT));           % -> 990.5 rad/s, muss < w_max sein!
fprintf('Hover: %.1f rad/s (%.0f%% von w_max)\n', w_hover, 100*w_hover/w_max);