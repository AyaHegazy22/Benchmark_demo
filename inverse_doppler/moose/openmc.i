joule_per_ev = 1.60218e-19

q      = ${fparse 1.0e6}                 # energy release per absorption (eV)
Sigma0 = ${fparse 4.0 * 0.025}           # Initial macroscopic XS, 1/cm
T0     = 293.6                           # surface temperature (K)
Y0     = 6.65e11                         # source intensity (n / cm2-s)

[Mesh]
  [solid]
    type = FileMeshGenerator
    file = ../../meshes/solid_in.e
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
    function = 'flux * ${q} * ${joule_per_ev} * ${Sigma0} * sqrt(${T0} / temp)'
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

  particles = 10000

  solid_blocks = '0'

  tally_type = mesh
  mesh_template = ../../meshes/solid_in.e
  solid_cell_level = 0
[]

[Executioner]
  type = Transient
  steady_state_detection = true
  check_aux = true
  steady_state_tolerance = 1e-3
[]

[MultiApps]
  [solid]
    type = TransientMultiApp
    app_type = CardinalApp
    input_files = 'solid.i'
    execute_on = timestep_end
    sub_cycling = true
  []
[]

[Transfers]
  [solid_temp]
    type = MultiAppMeshFunctionTransfer
    source_variable = T
    variable = temp
    from_multi_app = solid
  []
  [source_to_solid]
    type = MultiAppMeshFunctionTransfer
    source_variable = heat_source
    variable = power
    to_multi_app = solid
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
[]

[Outputs]
  exodus = true
[]
