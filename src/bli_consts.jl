# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# TODO: OS/env adaption
const libblis = "libblis.dylib"
const BLI_ROOT = "/usr/local/lib"

function bli_set_num_threads(n::Int64)
    ccall((:bli_thread_set_num_threads, libblis), Nothing, (Int64, ), n)
end

