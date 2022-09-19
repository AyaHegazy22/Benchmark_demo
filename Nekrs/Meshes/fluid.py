#!/bin/python
import os
import math
import sys
HOME = os.getenv('HOME')

os.system(HOME + "/aurora_build/cardinal/cardinal-opt -i fluid.i " + \
  " --mesh-only --n-threads=10")
  
os.system(HOME + "/aurora_build/cardinal/cardinal-opt -i convert.i " + \
  " --mesh-only --n-threads=10")
  
os.system("mv convert_in.e fluid.exo")
