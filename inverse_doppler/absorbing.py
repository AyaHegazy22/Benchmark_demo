import os
from argparse import ArgumentParser
import matplotlib.pyplot as plt
import numpy as np
np.random.BitGenerator = np.random.bit_generator.BitGenerator
import openmc
import openmc.mgxs
import h5py
import math

# Parameters specified in the benchmark document
sigma0 = 4.0     # barns
alpha = -0.0001  # 1 / cm-K
N0 = 0.025       # atom/barn-cm
T0 = 293.6       # Kelvin

# User settings
dT = 50.0        # Temperature spacing we want in our data set
Tmin = T0        # Minimum temperature for data set
Tmax = 1000.0    # Maximum temperature for data set

###############################################################

temps = list(np.arange(np.floor(T0), np.ceil(Tmax), dT))

# Generate the multigroup cross section data set
groups = openmc.mgxs.EnergyGroups(np.logspace(1, 20, 2))
abs_xsdata = openmc.XSdata('abs', groups, temperatures=temps)
abs_xsdata.order = 0

# The scattering matrix is ordered with incoming groups as rows and outgoing groups as columns
# (i.e., below the diagonal is up-scattering).
scatter_matrix = \
    [[[0.0 ]]]
scatter_matrix = np.array(scatter_matrix)
scatter_matrix = np.rollaxis(scatter_matrix, 0, 3)

for i in range(len(temps)):
  E = sigma0 * N0 * math.sqrt(T0 / temps[i])
  abs_xsdata.set_total([E], temperature=temps[i])
  abs_xsdata.set_absorption([E], temperature=temps[i])
  abs_xsdata.set_scatter_matrix(scatter_matrix, temperature=temps[i])

# Initialize the library
mg_cross_sections_file = openmc.MGXSLibrary(groups)

# Add the UO2 data to it
mg_cross_sections_file.add_xsdata(abs_xsdata)

# And write to disk
mg_cross_sections_file.export_to_hdf5('mgxs.h5')

# For every cross section data set in the library, assign an openmc.Macroscopic object to a material
materials = {}
for xs in ['abs']:
    materials[xs] = openmc.Material(name=xs)
    materials[xs].set_density('macro', 1.)
    materials[xs].add_macroscopic(xs)

# Instantiate a Materials collection, register all Materials, and export to XML
materials_file = openmc.Materials(materials.values())

# Set the location of the cross sections file to our pre-written set
materials_file.cross_sections = 'mgxs.h5'

materials_file.export_to_xml()

# geometry
x_plane1 = openmc.XPlane(0, boundary_type = 'vacuum')
x_plane2 = openmc.XPlane(200.0, boundary_type = 'vacuum')
y_plane1 = openmc.YPlane(0, boundary_type = 'vacuum')
y_plane2 = openmc.YPlane(2.0, boundary_type = 'vacuum')
z_plane1 = openmc.ZPlane(0, boundary_type = 'vacuum')
z_plane2 = openmc.ZPlane(2.0, boundary_type = 'vacuum')

abs_cells = []
for material in materials.values():
   abs_cells.append(openmc.Cell(fill = material, region = +x_plane1 & -x_plane2 & +y_plane1 & -y_plane2  & +z_plane1 & -z_plane2))

root = openmc.Universe(name = 'root')
root.add_cells(abs_cells)
geometry = openmc.Geometry(root)
geometry.export_to_xml()

# settings
settings = openmc.Settings()
settings.energy_mode = 'multi-group'

# source in one side
# TODO: figure out how to do a plane source, if possible
settings.run_mode = 'fixed source'
lower_left = (0.0, 0.0, 0.0)
upper_right = (0.1, 2.0, 2.0)
uniform_dist = openmc.stats.Box(lower_left, upper_right)

source = openmc.Source()
source.strength = 1.0
source.space = uniform_dist
source.angle = openmc.stats.Monodirectional(reference_uvw=[1.0, 0.0, 0.0])
settings.source = source

settings.temperature = {'default': 300.0,

                        # We need to use 'nearest' for now because OpenMC is missing some logic
                        # inside to know how to let us set temperatures via interpolation when
                        # using multigroup mode
                        'method': 'nearest',

                        'range': (294.0, 3000.0)}

settings.batches = 50
settings.particles = 1000

settings.export_to_xml()

openmc.run()
