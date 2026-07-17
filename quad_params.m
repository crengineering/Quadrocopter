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
om0 = [0; 0; 0];   % Anfangs-Drehrate [p;q;r], Default 0

% ---- Mixer (Konvention aus Abschnitt 03) ----
MIX = [ kT     kT     kT     kT;
       -d*kT  -d*kT   d*kT   d*kT;
        d*kT  -d*kT  -d*kT   d*kT;
        kQ    -kQ     kQ    -kQ ];

MIX_inv = inv(MIX);

% ---- Trimm: Schwebedrehzahl aus 4*kT*w^2 = m*g ----
w_hover = sqrt(m*g/(4*kT));           % -> 990.5 rad/s, muss < w_max sein!
fprintf('Hover: %.1f rad/s (%.0f%% von w_max)\n', w_hover, 100*w_hover/w_max);