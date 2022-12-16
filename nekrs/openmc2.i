joule_per_ev = 1.60218e-19

q      = ${fparse 1.0e6}                 # energy release per absorption (eV)
Sigma0 = ${fparse 4.0 * 0.025}           # Initial macroscopic XS, 1/cm
T0     = 293.6                           # surface temperature (K)
Y0     = 6.65e11                         # source intensity (n / cm2-s)
alpha  = -0.0001                         # Linear doppler Coefficient

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
  [nek_temp]
    # This initial value will be used in the first heat source sent to nekRS
    initial_condition = 293.6 
  []
[]

[AuxKernels]
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
    function = 'flux * ${q} * ${joule_per_ev} * ${Sigma0} * (1+(${alpha}/${Sigma0})*(temp-${T0}))'
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

  particles = 1000
  max_batches = 100000
  #first_iteration_particles = 10000
  solid_blocks = '0'

  tally_type = mesh
  mesh_template = meshes/solid_in.e
  solid_cell_level = 0
  relaxation = robbins_monro
  #relaxation = dufek_gudowski
  #relaxation = constant
  #relaxation_factor = 0.7
  tally_trigger = rel_err
  tally_trigger_threshold = 1e-2
  output = unrelaxed_tally_std_dev
[]

[Executioner]
#attempt1- time step is 100.0
#attempt2- time step is 10.0
#attempt3 - time step is 1000.0
  type = Transient
  steady_state_detection = true
  dt = 1000.0
  #steady state tolerance of 1e-5 instead of 1e-3
  steady_state_tolerance = 1e-5
  check_aux = true
[]

[MultiApps]
  [nek]
    type = TransientMultiApp
    app_type = CardinalApp
    input_files = 'nek.i'
    execute_on = timestep_end
    sub_cycling = true
  []
[]

[Transfers]
  [nek_temp]
    type = MultiAppMeshFunctionTransfer
    source_variable = temp
    variable = temp
    from_multi_app = nek
  []
  [source_to_solid]
    type = MultiAppMeshFunctionTransfer
    source_variable = heat_source
    variable = heat_source
    to_multi_app =nek
  []
  [source_integral]
    type = MultiAppPostprocessorTransfer
    to_postprocessor = source_integral
    from_postprocessor = source_integral
    to_multi_app = nek
  []
[]

[Postprocessors]
  [max_heat_source]
    type = ElementExtremeValue
    variable = heat_source
    execute_on = 'timestep_end'
  []
  [max_flux]
    type = ElementExtremeValue
    variable = flux
  []
  [source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = heat_source
  []
[]

[Outputs]
  exodus = true
  perf_graph = true
[]
