joule_per_ev = 1.60218e-19

q      = ${fparse 1.0e6}                 # energy release per absorption (eV)
Sigma0 = ${fparse 4.0 * 0.025}           # Initial macroscopic XS, 1/cm
T0     = 293.6                           # surface temperature (K)
Y0     = 6.65e11                         # source intensity (n / cm2-s)
alpha =  -0.0001                         # 1 / cm-K
A  = ${fparse 1+(2*-0.0001*6.65e11* 1.60218e-19*1.0e6/(0.006*(4.0 * 0.025)^2))}   #constant A is given in EQ.23

[Mesh]
  [solid]
    type = FileMeshGenerator
    file =meshes/solid_in.e
  []
[]

[Problem]
  type = FEProblem
[]

[Variables]
  [T]
    initial_condition = 294.0
  []
[]

[Kernels]
  [diffusion]
    type = HeatConduction
    variable = T
    block = '0'
  []
  [source]
    type = CoupledForce
    variable = T
    v = power
    block = '0'
  []
[]

[BCs]
  [left_boundary]
    type = DirichletBC
    variable = T
    boundary = 'left'
    value = 294.0
  []
  [insulated]
    type = NeumannBC
    variable = T
    boundary = 'right top bottom front back'
    value = 0
  []
[]


[Materials]
  [absorbing]
    type = HeatConductionMaterial
    thermal_conductivity = ${fparse 0.6 / 100.0} # W/cm-K
    block = '0'
  []
[]

[Postprocessors]
  [T_solid]
    type = ElementExtremeValue
    variable = T
  []
[]

[AuxVariables]
  [power]
    family = MONOMIAL
    order = CONSTANT
  []
[]


[Variables]
    [temp]
    family = MONOMIAL
    order = CONSTANT
  []
[]


[AuxKernels]
  [power]
    type = ParsedAux
    variable = power
    args = 'T'
    function = '4*${Y0}*${A}*exp(-sqrt(${A})*${Sigma0}*x)/((1+sqrt(${A}))-(1-sqrt(${A}))*exp(-sqrt(${A})*${Sigma0}*x))^2* ${q} * ${joule_per_ev} * ${Sigma0} * (1+0.0001/(${Sigma0})*(T-${T0}))'
    execute_on = 'timestep_begin'
    use_xyzt = true
  []
[]

#

[Executioner]
  type = Transient
  nl_abs_tol = 1e-5
  nl_rel_tol = 1e-16
  steady_state_detection = true 
  petsc_options_value = 'hypre boomeramg'
  petsc_options_iname = '-pc_type -pc_hypre_type'
[]

[Outputs]
  exodus = true
[]