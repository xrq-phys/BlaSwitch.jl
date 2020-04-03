# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Setter routines from MKL.jl

const BLA_PAYLOAD = """
    # START MKL INSERT
    pushfirst!(LOAD_PATH, "@v#.#")
    pushfirst!(LOAD_PATH, "@")
    MKL = Base.require(Base, :MKL) # LN 4
    MKL.MKL_jll.__init__()         # LN 5
    MKL.__init__()                 # LN 6
    popfirst!(LOAD_PATH)
    popfirst!(LOAD_PATH)
    # END MKL INSERT"""
const BLA_PAYLOAD_LINES = split(BLA_PAYLOAD, '\n')

include("bli_consts.jl")

"Replace library name"
function replace_libblas(name)
    # Determine in-line the system image script
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")
    file = joinpath(base_dir, "build_h.jl")
    lines = readlines(file)

    libblas_idx   = findfirst(match.(r"const libblas_name", lines)   .!= nothing)
    liblapack_idx = findfirst(match.(r"const liblapack_name", lines) .!= nothing)

    # Assert library is not empty
    @assert libblas_idx !== nothing && liblapack_idx !== nothing

    lines[libblas_idx] = "const libblas_name = $(repr(name))"
    lines[liblapack_idx] = "const liblapack_name = $(repr(name))"

    # Apply change
    write(file, string(join(lines, '\n'), '\n'))
end

"Insert payload to load custom library"
function insert_BLA_load(blas_load_commands)
    # In-line the system image script
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")
    file = joinpath(base_dir, "sysimg.jl")
    lines = readlines(file)
    @info "Splicing in code to load selected BLAS in $(file)"

    # Be idempotent
    if BLA_PAYLOAD_LINES[1] in lines
        return
    end

    # After this the stdlibs get included, so insert MKL to be loaded here
    start_idx = findfirst(match.(r"Base._track_dependencies\[\] = true", lines) .!= nothing)

    # Apply lines and write to file
    BLA_CUSTOM_PAYLOAD_LINES = copy(BLA_PAYLOAD_LINES)
    BLA_CUSTOM_PAYLOAD_LINES[4:6] = blas_load_commands
    splice!(lines, (start_idx + 1):start_idx, BLA_CUSTOM_PAYLOAD_LINES)
    write(file, string(join(lines, '\n'), '\n'))
end

"Reset BLAS payload loading script"
function remove_BLA_load()
    # In-line the system image script
    base_dir = joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "base")
    file = joinpath(base_dir, "sysimg.jl")
    lines = readlines(file)
    @info "Removing code to load external BLAS in $(file)"

    start_idx = findfirst(==(BLA_PAYLOAD_LINES[1]), lines)
    end_idx = findfirst(==(BLA_PAYLOAD_LINES[end]), lines)

    if start_idx === nothing || end_idx === nothing
        return
    end

    # Write
    splice!(lines, start_idx:end_idx)
    write(file, string(join(lines, '\n'), '\n'))
end

# Handles and presets
set_BLA_to(libname, libpath) = begin
    # Preprocess
    BLA_COMMANDS = """
        PATH = ""
        LIBPATH = "$(libpath)"
        push!(LOAD_PATH, "$(libpath)")"""
    BLA_COMMAND_LINES = split(BLA_COMMANDS, '\n')

    # Apply
    remove_BLA_load()
    insert_BLA_load(BLA_COMMAND_LINES)
    replace_libblas(libname)
end
set_BLA_to_bli() = set_BLA_to(libblis, BLI_ROOT)
set_BLA_to_mkl() = begin 
    remove_BLA_load()
    insert_BLA_load(BLA_PAYLOAD_LINES[4:6])
    replace_libblas("@rpath/libmkl_rt.dylib")
end

# Pasted from MKL.jl
# I don't know what's it for
function get_precompile_statments_file()
    jl_dev_ver = length(VERSION.prerelease) == 2 && (VERSION.prerelease)[1] == "DEV" # test if running nightly/unreleased version
    jl_gh_tag = jl_dev_ver ? "master" : "release-$(VERSION.major).$(VERSION.minor)"
    prec_jl_url = "https://raw.githubusercontent.com/JuliaLang/julia/$jl_gh_tag/contrib/generate_precompile.jl"
    @info "getting precompile script from: $prec_jl_url"
    prec_jl_fn = tempname()
    download(prec_jl_url, prec_jl_fn)
    prec_jl_content = read(prec_jl_fn, String)
    # PackageCompiler.jl already inits stdio and double initing it leads to bad things
    write(prec_jl_fn, replace(prec_jl_content, "Base.reinit_stdio()" => "# Base.reinit_stdio()"))
    return prec_jl_fn
end

function update_bla()
    @eval begin
        using PackageCompiler
        PackageCompiler.create_sysimage(; incremental=false, replace_default=true,
                                        script=get_precompile_statments_file())
    end
end

