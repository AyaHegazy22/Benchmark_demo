import os
from argparse import ArgumentParser
import matplotlib.pyplot as plt
import numpy as np
np.random.BitGenerator = np.random.bit_generator.BitGenerator
import openmc.lib
import openmc.mgxs
import h5py
import math

T0 = 295.0       # Constant temperature (left half)
T1 = 395.0       # Constant temperature (right half)
E0 = 0.01        # Constant cross section (left half)
E1 = 0.02        # Constant cross section (right half)
height = 200.0   # Length in x direction

###############################################################
#axial divisions
ap = ArgumentParser()
ap.add_argument('-n', dest='n_axial', type=int, default=100,
                help='Number of axial cell divisions')
args = ap.parse_args()
N = args.n_axial
###############################################################

# Generate the multigroup cross section data set; this is a single energy group
groups = openmc.mgxs.EnergyGroups(np.logspace(-5, 7, 2))

# Initialize the cross section data set for a pure-absorbing material, named 'abs'
abs_xsdata = openmc.XSdata('abs', groups, temperatures=[T0, T1])
abs_xsdata.order = 0

# The scattering matrix is ordered with incoming groups as rows and outgoing groups as columns
# (i.e., below the diagonal is up-scattering).
scatter_matrix = \
    [[[0.0 ]]]
scatter_matrix = np.array(scatter_matrix)
scatter_matrix = np.rollaxis(scatter_matrix, 0, 3)

# left temperature set
E = E0
abs_xsdata.set_total([E], temperature=T0)
abs_xsdata.set_absorption([E], temperature=T0)
abs_xsdata.set_fission([0.0], temperature=T0)
abs_xsdata.set_nu_fission([0.0], temperature=T0)
abs_xsdata.set_chi([1.0], temperature=T0)
abs_xsdata.set_scatter_matrix(scatter_matrix, temperature=T0)

E = E1
abs_xsdata.set_total([E], temperature=T1)
abs_xsdata.set_absorption([E], temperature=T1)
abs_xsdata.set_fission([0.0], temperature=T1)
abs_xsdata.set_nu_fission([0.0], temperature=T1)
abs_xsdata.set_chi([1.0], temperature=T1)
abs_xsdata.set_scatter_matrix(scatter_matrix, temperature=T1)

# Initialize the library
mg_cross_sections_file = openmc.MGXSLibrary(groups)

# Add the UO2 data to it
mg_cross_sections_file.add_xsdata(abs_xsdata)

# And write to disk
mg_cross_sections_file.export_to_hdf5('mgxs.h5')

# For every cross section data set in the library, assign an openmc.Macroscopic object to a material
materials = {}
materials['left'] = openmc.Material(name='left')
materials['left'].set_density('macro', 1.)
materials['left'].add_macroscopic('abs')

materials['right'] = openmc.Material(name='right')
materials['right'].set_density('macro', 1.)
materials['right'].add_macroscopic('abs')

# Instantiate a Materials collection, register all Materials, and export to XML
materials_file = openmc.Materials(materials.values())

# Set the location of the cross sections file to our pre-written set
materials_file.cross_sections = 'mgxs.h5'

materials_file.export_to_xml()

axial_coords = np.linspace(0.0, height, N + 1)
axial_mid_coords = np.linspace(height / 2.0, height + height / 2.0, N)
y_plane1 = openmc.YPlane(0.0, boundary_type = 'reflective')
y_plane2 = openmc.YPlane(2.0, boundary_type = 'reflective')
z_plane1 = openmc.ZPlane(0.0, boundary_type = 'reflective')
z_plane2 = openmc.ZPlane(2.0, boundary_type = 'reflective')

#x planes
x_surfaces = [openmc.XPlane(x0=coord) for coord in axial_coords]
x_surfaces[0].boundary_type = 'vacuum'
x_surfaces[-1].boundary_type = 'vacuum'

abs_cells = []
for i in range(N):
   layer = +x_surfaces[i] & -x_surfaces[i + 1]

   if (i < N / 2):
     abs_cells.append(openmc.Cell(fill = materials['left'], region = layer & +y_plane1 & -y_plane2  & +z_plane1 & -z_plane2))
   else:
     abs_cells.append(openmc.Cell(fill = materials['right'], region = layer & +y_plane1 & -y_plane2  & +z_plane1 & -z_plane2))

root = openmc.Universe(name = 'root')
root.add_cells(abs_cells)
geometry = openmc.Geometry(root)
geometry.export_to_xml()

# settings
settings = openmc.Settings()
settings.energy_mode = 'multi-group'
settings.verbosity = 6

# source in one side
# TODO: figure out how to do a plane source, if possible
settings.run_mode = 'fixed source'
lower_left = (0.0, 0.0, 0.0)
upper_right = (0.0001, 2.0, 2.0)
uniform_dist = openmc.stats.Box(lower_left, upper_right)

source = openmc.Source()
source.strength = 1.0
source.space = uniform_dist
source.angle = openmc.stats.Monodirectional(reference_uvw=[1.0, 0.0, 0.0])
settings.source = source

settings.temperature = {'default': T0,

                        # We need to use 'nearest' for now because OpenMC is missing some logic
                        # inside to know how to let us set temperatures via interpolation when
                        # using multigroup mode
                        'method': 'nearest'}

settings.batches = 200
settings.particles = 5000

settings.export_to_xml()

plot          = openmc.Plot()
plot.filename = 'plot'
plot.width    = (100.0, 10.0)
plot.basis    = 'xy'
plot.origin   = (100.0, 1.0, 1.0)
plot.pixels   = (1000, 100)
plot.color_by = 'material'
plots = openmc.Plots([plot])
plots.export_to_xml()


cell_filter = openmc.CellFilter(abs_cells)
flux_tally = openmc.Tally(tally_id = 1)
flux_tally.filters.append(cell_filter)
flux_tally.scores = ['flux']
tallies = openmc.Tallies([flux_tally])
tallies.export_to_xml()

with openmc.lib.run_in_memory():
  # change material temperatures, to 295 in left half of domain and 395 in right half of domain.
  # This does NOTHING to the cross sections used.
  analytic = []

  for i in range(N):
    x = height / N * i + height / N / 2.0
    mat = openmc.lib.find_material((x, 1.0, 1.0))

    if (x < height / 2.0):
      mat.temperature = T0
      analytic.append(math.exp(-E0 * x))
    else:
      mat.temperature = T1

      Y1 = math.exp(-E0 * height / 2.0) / math.exp(-E1 * height / 2.0)
      analytic.append(Y1 * math.exp(-E1 * x))

  openmc.lib.reset()

  openmc.lib.run()

  flux = openmc.lib.tallies[1].mean
  bin_vol = height / N
  t = []
  for i in range(len(flux)):
    t.append(flux[i] / bin_vol)

  plt.plot(axial_mid_coords, t, label='OpenMC')
  plt.plot(axial_mid_coords, analytic, label='Analytic')
  plt.title('Changing Material Temperatures')
  plt.xlabel('X Coordinate')
  plt.ylabel('Flux')
  plt.savefig('flux_with_material_temps.pdf')
  plt.close()
