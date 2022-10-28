E0 = 0.01       # Macroscopic cross section, 1/cm [left half]
E1 = 0.02       # Macroscopic cross section, 1/cm [right half]
Y0 = 1e11       # Face flux, n/cm2-s

Y1 = ${fparse Y0 * exp(-E0 * 100.0) / exp(-E1 * 100.0)} # Flux at the mid-point

T0 = 295.0
T1 = 395.0

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

[ICs]
  [temp]
    type = FunctionIC
    variable = temp
    function = temp
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
    value = 'if (x < 100.0, ${Y0} * exp(-${E0} * x), ${Y1} * exp(-${E1} * x))'
  []
  [temp]
    type = ParsedFunction
    value = 'if (x < 100.0, ${T0}, ${T1})'
  []
[]

[Problem]
  type = OpenMCCellAverageProblem
  output = 'unrelaxed_tally_std_dev'
  verbose = true
  check_zero_tallies = false
  check_equal_mapped_tally_volumes = true
  source_strength = ${fparse Y0 * 2.0 * 2.0}
  tally_score = flux
  tally_name = flux

  particles = 100000
  max_batches = 1000
  solid_blocks = '0'

  initial_properties = moose

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
