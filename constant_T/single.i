E0 = 0.01       # Macroscopic cross section, 1/cm
Y0 = 1e11       # Face flux, n/cm2-s

[Mesh]
  [solid]
    type = FileMeshGenerator
    file = meshes/solid_in.e
  []
[]

[AuxVariables]
  [analytic]
    family = MONOMIAL
    order = CONSTANT
  []
  [diff]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [analytic]
    type = FunctionAux
    variable = analytic
    function = analytic
  []
  [diff]
    type = ParsedAux
    variable = diff
    args = 'analytic flux'
    function = 'flux - analytic'
  []
[]

[Functions]
  [analytic]
    type = ParsedFunction
    value = '${Y0} * exp(-${E0} * x)'
  []
[]

[Problem]
  type = OpenMCCellAverageProblem
  output = 'unrelaxed_tally_std_dev'
  verbose = false
  check_zero_tallies = false
  check_equal_mapped_tally_volumes = true
  source_strength = ${fparse Y0 * 2.0 * 2.0}
  tally_score = flux
  tally_name = flux

  particles = 100000
  max_batches = 1000
  solid_blocks = '0'

  initial_properties = xml

  tally_type = cell
  tally_blocks = '0'

  solid_cell_level = 0
[]

[Executioner]
  type = Transient
  dt = 1.0
  num_steps = 1
[]


[Postprocessors]
  [max_flux]
    type = ElementExtremeValue
    variable = flux
  []
  [max_analytic]
    type = ElementExtremeValue
    variable = analytic
  []
  [max_diff]
    type = ElementExtremeValue
    variable = diff
    value_type = max
  []
  [min_diff]
    type = ElementExtremeValue
    variable = diff
    value_type = min
  []
  [max_std_dev]
    type = ElementExtremeValue
    variable = unrelaxed_tally_std_dev
  []
[]

[Outputs]
  exodus = true
[]
