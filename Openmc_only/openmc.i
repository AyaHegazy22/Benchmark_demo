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
    file = meshes/solid_in.e
  []
[]

[AuxVariables]
  [cell_id]
    family = MONOMIAL
    order = CONSTANT
  []
  [cell_instance]
    family = MONOMIAL
    order = CONSTANT
  []
  [material_id]
    family = MONOMIAL
    order = CONSTANT
  []
  [cell_temperature]
    family = MONOMIAL
    order = CONSTANT
  []

  # Variables added to convert into proper heat source term for the power in the solid
  [heat_source] # W / cm^3
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [temp]
    type = ParsedAux
    variable = temp
    function = '${T0}+ 2*${Y0}*${q}/(0.006*${T0}*${Sigma0})*${joule_per_ev}*${T0}*(1-exp(-sqrt(${A})*${Sigma0}*x))/(1-exp(-sqrt(${A})*${Sigma0}*x)+sqrt(${A})*(1+exp(-sqrt(${A})*${Sigma0}*x)))'
    execute_on = 'timestep_begin'
    use_xyzt = true
  []
  [material_id]
    type = CellMaterialIDAux
    variable = material_id
  []
  [cell_id]
    type = CellIDAux
    variable = cell_id
  []
  [cell_instance]
    type = CellInstanceAux
    variable = cell_instance
  []
  [cell_temperature]
    type = CellTemperatureAux
    variable = cell_temperature
  []

  # Change the unit of the 'flux' (neutrons / m^2 / s) into a volumetric power. This is
  # based on Eq. (5b) in the paper, which shows the volumetric power is q / k * Sigma * flux
  [changing_units]
    type = ParsedAux
    variable = heat_source
    args = 'flux temp'
    function = 'flux * ${q} * ${joule_per_ev} * ${Sigma0} * (1+0.0001/(${Sigma0})*(temp-${T0}))'
    execute_on = 'timestep_end'
  []
[]

[ICs]
  [temp]
    type = ConstantIC
    variable = temp
    value = ${T0}
  []
[]

[Problem]
  type = OpenMCCellAverageProblem
  verbose = true
  check_zero_tallies = false
  source_strength = ${fparse Y0 * 2.0 * 2.0} # multiply by the left area to get units of neutrons / s
  tally_score = flux
  tally_name = flux

  initial_properties = xml

  particles = 100000
  max_batches = 1000
  solid_blocks = '0'

  tally_type = mesh
  mesh_template = meshes/solid_in.e
  solid_cell_level = 0
  relaxation = robbins_monro
  tally_trigger = rel_err
  tally_trigger_threshold = 1e-2
[]

[Executioner]
  type = Transient
  dt = 1.0
  steady_state_detection = true
  check_aux = true
  steady_state_tolerance = 1e-3
[]


[Postprocessors]
  [max_heat_source]
    type = ElementExtremeValue
    variable = heat_source
    execute_on = 'timestep_begin'
  []
  [max_flux]
    type = ElementExtremeValue
    variable = flux
  []
[]

[Outputs]
  exodus = true
  perf_graph = true
[]
