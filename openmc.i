[Mesh]
  [solid]
    type = FileMeshGenerator
    file = meshes/solid_in.e
  []
[]

# These auxiliary variables are all just for visualizing the solution and
# the mapping - none of these are part of the calculation sequence

[AuxVariables]
  [cell_id]
    family = MONOMIAL
    order = CONSTANT
  []
  [heat_source]
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
  [cell_density]
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
  [cell_density]
     #assume linear doppler effect
     type = ParsedAux
     variable = solid_temp
     args = 'solid_temp'
     function ='1+0.0001/(4*0.025)*(solid_temp-294.0)'
   []
  [changing_units] #this changes the unit of the flux to heat_source for the solid
    type = ParsedAux
    variable = heat_source
    args = 'flux'
    function = 'flux*10*1.6*10E-13' #flux*macroscopic_crosssection*energy released per absorption, units of W/m^2
  []
[]

[Problem]
  type = OpenMCCellAverageProblem
  source_strength = 6.65E11
  tally_score = flux
  tally_name = flux
  scaling = 100.0
  solid_blocks = '0'
  tally_type = cell
  solid_cell_level = 0
  temperature_variables = 'solid_temp'
  temperature_blocks = '0'
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
    type = MultiAppCopyTransfer
    source_variable = T
    variable = solid_temp
    from_multi_app = solid
  []
  [source_to_solid]
    type = MultiAppCopyTransfer
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
[]
[Outputs]
  exodus = true
[]
