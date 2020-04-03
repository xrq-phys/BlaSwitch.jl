# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

module BlaSwitch

export update_bla, set_BLA_to, set_BLA_to_bli, set_BLA_to_mkl

println("=======================================================")
println(" Use this small package to select BLAS vendor you like.")
println(" Usually set_BLA_to(libname, libpath) followed by      ")
println("   update_bla() would just work.                       ")
println(" Created by RuQing Xu                                  ")
println("   in Dept. Phys., Univ. Tokyo                         ")
println("=======================================================")

include("bla_setter.jl")

end # module
