import math

joule_per_ev = 1.60218e-19
cm_per_m = 100.0

q      = 1.0e6
Sigma0 = 4.0 * 0.025
T0     = 293.6
Y0     = 6.65e11
alpha  = -0.0001
k      = 0.6

A  = 1 + (2*alpha*Y0*joule_per_ev*q*cm_per_m / (k*Sigma0*Sigma0))   #constant A is given in EQ.23
phi0 = Y0 * q / k / T0 / Sigma0 * joule_per_ev * cm_per_m

print(phi0)

x = 0.0
ex = math.exp(-math.sqrt(A)*Sigma0*x)
T = T0+ 2*phi0*T0*(1-ex)/(1-ex+math.sqrt(A)*(1+ex))
flux = 4.0 * Y0 * A * ex / ((1.0 + math.sqrt(A)) - (1.0 - math.sqrt(A)) * ex)**2
print(T, flux)
