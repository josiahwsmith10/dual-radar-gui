%% Set AMC4030 Parameters
mm_per_rev = 72;
pulses_per_rev = 51200;
pulses_per_mm = pulses_per_rev/mm_per_rev;
xAlwaysOffset_pulses = 10;

%% Set Scanning Parameters
xStep_mm = 0.948710310126582;
xStep_pulses = xStep_mm*pulses_per_mm;
N = 256;
pulses_tot = 179.2e3;

%% Get Forward and Backward Breakpoints
x1 = round(xAlwaysOffset_pulses + xStep_pulses*(0:N-1))';
x1b = pulses_tot - flip(x1);