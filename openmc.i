cm2_per_barn = 1e-24
cm_per_m = 100.0
joule_per_ev = 1.60218e-19

N0     = ${fparse 0.025 / cm2_per_barn / (cm_per_m^3)}  # initial number density, (atom / m^3)
q      = ${fparse 1.0e6 * joule_per_ev}                 # energy release per absorption (J)
k      = 0.6                                            # solid thermal conductivity (W/m-K)
sigma0 = ${fparse 4.0 * cm2_per_barn / (cm_per_m^2)}    # absorption cross section (m^2)
alpha  = ${fparse -0.0001 * cm_per_m}                   # linear Doppler coefficient (1 / m-K)
T0     = 293.6                                          # surface temperature (K)
Y0     = ${fparse 6.65e11 * (cm_per_m^2)}

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

  # Variables added to convert into proper heat source term for the power in the solid,
  # as well as for the density applied to the OpenMC cells
  [number_density] # atoms / m^3
    family = MONOMIAL
    order = CONSTANT
  []
  [heat_source] # W / m^3
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

  [density] # This is the density actually sent to OpenMC, which here needs to be units of kg/m^3
    type = ParsedAux
    variable = density
    args = 'number_density'
    function = 'number_density / ${N0} * 1000'
  []

  # Number density, for linear Doppler feedback. This is based on Eq. (3a) in the paper.
  [number_density]
     # assume linear doppler effect
     type = ParsedAux
     variable = number_density
     args = 'temp'
     function = '${N0} * (1.0 - ${alpha} / ${sigma0} / ${N0} * (temp - ${T0}))'
  []

  # Change the unit of the 'flux' (neutrons / m^2 / s) into a volumetric power. This is
  # based on Eq. (5b) in the paper, which shows the volumetric power is q / k * Sigma * flux
  [changing_units]
    type = ParsedAux
    variable = heat_source
    args = 'flux number_density'
    function = 'flux * ${q} / ${k} * (${sigma0} * number_density)'
    #                                 |__________________________|
    #                                            ^
    #                                            |
    #                               [ this is the macroscopic XS]
  []
[]

[Problem]
  type = OpenMCCellAverageProblem
  check_zero_tallies = false
  source_strength = ${fparse 6.65e11 * 4}
  tally_score = flux
  tally_name = flux
  scaling = 100.0

  fluid_blocks = '0'

  tally_type = mesh
  mesh_template = meshes/solid_in.e
  fluid_cell_level = 0
[]

[Executioner]
  type = Transient
  dt = 2.0
  steady_state_detection = true
  check_aux = true
  steady_state_tolerance = 1e-3
[]

[MultiApps]
  [solid]
    type = TransientMultiApp
    app_type = CardinalApp
    input_files = 'solid.i'
    execute_on = timestep_begin
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
  [heat_source]
    type = ElementIntegralVariablePostprocessor
    variable = heat_source
    execute_on = 'transfer initial timestep_end'
  []
  [max_flux]
    type = ElementExtremeValue
    variable = flux
  []
[]
[Outputs]
  exodus = true
[]
