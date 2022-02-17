mutable struct SelectOp <: AbstractSelectOp
    name::String
    p::libgb.GxB_SelectOp
    juliaop::Union{Function, Nothing}
    function SelectOp(name, p::libgb.GxB_SelectOp, juliaop)
        d = new(name, p, juliaop)
        function f(selectop)
            libgb.GxB_SelectOp_free(Ref(selectop.p))
        end
        return finalizer(f, d)
    end
end

const SelectUnion = Union{AbstractSelectOp, libgb.GxB_SelectOp}

Base.unsafe_convert(::Type{libgb.GxB_SelectOp}, selectop::SelectOp) = selectop.p

const TRIL = SelectOp("GxB_TRIL", libgb.GxB_SelectOp(C_NULL), LinearAlgebra.tril)
const TRIU = SelectOp("GxB_TRIU", libgb.GxB_SelectOp(C_NULL), LinearAlgebra.triu)
const DIAG = SelectOp("GxB_DIAG", libgb.GxB_SelectOp(C_NULL), LinearAlgebra.diag)

"""
    offdiag(A::GBArray, k=0)

Select the entries **not** on the `k`th diagonal of A.
"""
function offdiag end #I don't know of a function which does this already.
const OFFDIAG = SelectOp("GxB_OFFDIAG", libgb.GxB_SelectOp(C_NULL), offdiag)
offdiag(A::GBArray, k=0) = select(offdiag, A, k)

const NONZERO = SelectOp("GxB_NONZERO", libgb.GxB_SelectOp(C_NULL), nonzeros)
const EQ_ZERO = SelectOp("GxB_EQ_ZERO", libgb.GxB_SelectOp(C_NULL), nothing)
const GT_ZERO = SelectOp("GxB_GT_ZERO", libgb.GxB_SelectOp(C_NULL), nothing)
const GE_ZERO = SelectOp("GxB_GE_ZERO", libgb.GxB_SelectOp(C_NULL), nothing)
const LT_ZERO = SelectOp("GxB_LT_ZERO", libgb.GxB_SelectOp(C_NULL), nothing)
const LE_ZERO = SelectOp("GxB_LE_ZERO", libgb.GxB_SelectOp(C_NULL), nothing)
const NE = SelectOp("GxB_NE_THUNK", libgb.GxB_SelectOp(C_NULL), !=)
const EQ = SelectOp("GxB_EQ_THUNK", libgb.GxB_SelectOp(C_NULL), ==)
const GT = SelectOp("GxB_GT_THUNK", libgb.GxB_SelectOp(C_NULL), >)
const GE = SelectOp("GxB_GE_THUNK", libgb.GxB_SelectOp(C_NULL), >=)
const LT = SelectOp("GxB_LT_THUNK", libgb.GxB_SelectOp(C_NULL), <)
const LE = SelectOp("GxB_LE_THUNK", libgb.GxB_SelectOp(C_NULL), <=)

function SelectOp(name)
    simple = Symbol(replace(string(name[5:end]), "_THUNK" => ""))
    constquote = quote
        const $simple = SelectOp($name, libgb.GxB_SelectOp(C_NULL))
    end
    @eval($constquote)
end

function _loadselectops()
    TRIL.p = load_global("GxB_TRIL", libgb.GxB_SelectOp)
    TRIU.p = load_global("GxB_TRIU", libgb.GxB_SelectOp)
    DIAG.p = load_global("GxB_DIAG", libgb.GxB_SelectOp)
    OFFDIAG.p = load_global("GxB_OFFDIAG", libgb.GxB_SelectOp)
    NONZERO.p = load_global("GxB_NONZERO", libgb.GxB_SelectOp)
    EQ_ZERO.p = load_global("GxB_EQ_ZERO", libgb.GxB_SelectOp)
    GT_ZERO.p = load_global("GxB_GT_ZERO", libgb.GxB_SelectOp)
    GE_ZERO.p = load_global("GxB_GE_ZERO", libgb.GxB_SelectOp)
    LT_ZERO.p = load_global("GxB_LT_ZERO", libgb.GxB_SelectOp)
    LE_ZERO.p = load_global("GxB_LE_ZERO", libgb.GxB_SelectOp)
    NE.p = load_global("GxB_NE_THUNK", libgb.GxB_SelectOp)
    EQ.p = load_global("GxB_EQ_THUNK", libgb.GxB_SelectOp)
    GT.p = load_global("GxB_GT_THUNK", libgb.GxB_SelectOp)
    GE.p = load_global("GxB_GE_THUNK", libgb.GxB_SelectOp)
    LT.p = load_global("GxB_LT_THUNK", libgb.GxB_SelectOp)
    LE.p = load_global("GxB_LE_THUNK", libgb.GxB_SelectOp)
end


Base.getindex(::AbstractSelectOp, ::DataType) = nothing

function validtypes(::AbstractSelectOp)
    return Any
end

Base.show(io::IO, ::MIME"text/plain", s::SelectUnion) = gxbprint(io, s)
juliaop(op::AbstractSelectOp) = op.juliaop

"""
    select(SuiteSparseGraphBLAS.TRIL, A, k=0)
    select(tril, A, k=0)

Select the entries on or below the `k`th diagonal of A.

See also: `LinearAlgebra.tril`
"""
TRIL
SelectOp(::typeof(LinearAlgebra.tril)) = TRIL
"""
    select(SuiteSparseGraphBLAS.TRIU, A, k=0)
    select(triu, A, k=0)

Select the entries on or above the `k`th diagonal of A.

See also: `LinearAlgebra.triu`
"""
TRIU
SelectOp(::typeof(LinearAlgebra.triu)) = TRIU
"""
    select(DIAG, A, k=0)

Select the entries on the `k`th diagonal of A.

See also: `LinearAlgebra.diag`
"""
DIAG
SelectOp(::typeof(LinearAlgebra.diag)) = DIAG
"""
    select(OFFDIAG, A, k=0)

Select the entries **not** on the `k`th diagonal of A.
"""
OFFDIAG
SelectOp(::typeof(offdiag)) = OFFDIAG
"""
    select(NONZERO, A)
    select(nonzeros, A)
Select all entries in A with nonzero value.
"""
NONZERO
SelectOp(::typeof(nonzeros)) = NONZERO

# I don't believe these should have Julia equivalents.
# Instead select(==, A, 0) will find EQ_ZERO internally.
"""
    select(EQ_ZERO, A)

Select all entries in A equal to zero.
"""
EQ_ZERO
"""
    select(GT_ZERO, A)

Select all entries in A greater than zero.
"""
GT_ZERO
"""
    select(GE_ZERO, A)

Select all entries in A greater than or equal to zero.
"""
GE_ZERO
"""
    select(LT_ZERO, A)

Select all entries in A less than zero.
"""
LT_ZERO
"""
    select(LE_ZERO, A)

Select all entries in A less than or equal to zero.
"""
LE_ZERO
"""
    select(NE, A, k)
    select(!=, A, k)
Select all entries not equal to `k`.
"""
NE
SelectOp(::typeof(!=)) = NE
"""
    select(EQ, A, k)
    select(==, A, k)
Select all entries equal to `k`.
"""
EQ
SelectOp(::typeof(==)) = EQ
"""
    select(GT, A, k)
    select(>, A, k)
Select all entries greater than `k`.
"""
GT
SelectOp(::typeof(>)) = GT
"""
    select(GE, A, k)
    select(>=, A, k)
Select all entries greater than or equal to `k`.
"""
GE
SelectOp(::typeof(>=)) = GE
"""
    select(LT, A, k)
    select(<, A, k)
Select all entries less than `k`.
"""
LT
SelectOp(::typeof(<)) = LT
"""
    select(LE, A, k)
    select(<=, A, k)
Select all entries less than or equal to `k`.
"""
LE
SelectOp(::typeof(<=)) = LE