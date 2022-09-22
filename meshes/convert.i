[Mesh] 
  [file]
    type = FileMeshGenerator
    file = fluid_in.e
 []
 [rename]
 type = RenameBoundaryGenerator
 input = file
 old_boundary = 'left right top bottom front back'
 new_boundary = '1 2 3 4 5 6'
 []
  [to_hex20]
    type = Hex20Generator
    input = rename
  []
[]
