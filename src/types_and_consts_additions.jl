# These are the additions to the types_and_consts.jl file not from clang.jl

function Base.convert(::Type{Matrix}, J::DlsMat)
    _dlsmat = unsafe_load(J)
    # own is false as memory is allocated by sundials
    unsafe_wrap(Array, _dlsmat.data, (_dlsmat.M, _dlsmat.N); own = false)
end

CVRhsFn_wrapper(fp::CVRhsFn) = fp
CVRhsFn_wrapper(f) = @cfunction($f, Cint, (realtype, N_Vector, N_Vector, Ptr{Cvoid})).ptr

ARKRhsFn_wrapper(fp::ARKRhsFn) = fp
ARKRhsFn_wrapper(f) = @cfunction($f, Cint, (realtype, N_Vector, N_Vector, Ptr{Cvoid})).ptr

CVRootFn_wrapper(fp::CVRootFn) = fp
function CVRootFn_wrapper(f)
    @cfunction($f, Cint,
               (realtype, N_Vector, Ptr{realtype}, Ptr{Cvoid})).ptr
end

CVQuadRhsFn_wrapper(fp::CVQuadRhsFn) = fp
function CVQuadRhsFn_wrapper(f)
    @cfunction($f, Cint,
               (realtype, N_Vector, N_Vector, Ptr{Cvoid})).ptr
end

IDAResFn_wrapper(fp::IDAResFn) = fp
function IDAResFn_wrapper(f)
    @cfunction($f, Cint,
               (realtype, N_Vector, N_Vector, N_Vector, Ptr{Cvoid})).ptr
end

IDARootFn_wrapper(fp::IDARootFn) = fp
function IDARootFn_wrapper(f)
    @cfunction($f, Cint,
               (realtype, N_Vector, N_Vector, Ptr{realtype}, Ptr{Cvoid})).ptr
end

KINSysFn_wrapper(fp::KINSysFn) = fp
KINSysFn_wrapper(f) = @cfunction($f, Cint, (N_Vector, N_Vector, Ptr{Cvoid})).ptr

function Base.convert(::Type{Matrix}, J::SUNMatrix)
    _sunmat = unsafe_load(J)
    _mat = convert(SUNMatrixContent_Dense, _sunmat.content)
    mat = unsafe_load(_mat)
    # own is false as memory is allocated by sundials
    unsafe_wrap(Array, mat.data, (mat.M, mat.N); own = false)
end

# sparse SUNMatrix uses zero-offset indices, so provide copyto!, not convert
function Base.copyto!(Asun::SUNMatrix, Acsc::SparseArrays.SparseMatrixCSC{Float64, Int64})
    _sunmat = unsafe_load(Asun)
    _mat = convert(SUNMatrixContent_Sparse, _sunmat.content)
    mat = unsafe_load(_mat)
    # own is false as memory is allocated by sundials
    indexvals = unsafe_wrap(Vector{Int}, mat.indexvals, (mat.NNZ); own = false)
    indexptrs = unsafe_wrap(Vector{Int}, mat.indexptrs, (mat.NP + 1); own = false)
    data = unsafe_wrap(Vector{Float64}, mat.data, (mat.NNZ); own = false)

    if size(indexvals) != size(Acsc.rowval) || size(indexptrs) != size(Acsc.colptr)
        error("Sparsity Pattern in receiving SUNMatrix doesn't match sending SparseMatrix")
    end

    @. indexvals = Acsc.rowval - 1
    @. indexptrs = Acsc.colptr - 1
    data .= Acsc.nzval

    return nothing
end

abstract type SundialsMatrix end
struct DenseMatrix <: SundialsMatrix end
struct BandMatrix <: SundialsMatrix end
struct SparseMatrix <: SundialsMatrix end

abstract type SundialsLinearSolver end
struct Dense <: SundialsLinearSolver end
struct Band <: SundialsLinearSolver end
struct SPGMR <: SundialsLinearSolver end
struct SPFGMR <: SundialsLinearSolver end
struct SPBCGS <: SundialsLinearSolver end
struct PCG <: SundialsLinearSolver end
struct PTFQMR <: SundialsLinearSolver end
struct KLU <: SundialsLinearSolver end
struct LapackBand <: SundialsLinearSolver end
struct LapackDense <: SundialsLinearSolver end

abstract type SundialsNonLinearSolver end
struct Newton <: SundialsNonLinearSolver end
struct FixedPoint <: SundialsNonLinearSolver end

abstract type StiffnessChoice end
struct Explicit <: StiffnessChoice end
struct Implicit <: StiffnessChoice end
