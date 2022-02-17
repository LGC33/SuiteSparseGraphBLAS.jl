"""
    kron!(A::GBMatrix, B::GBMatrix, op = BinaryOps.TIMES; kwargs...)::GBMatrix

In-place version of [kron](@ref).
"""
function LinearAlgebra.kron!(
    C::GBArray,
    A::GBArray,
    B::GBArray,
    op = *;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    mask, accum = _handlenothings(mask, accum)
    desc = _handledescriptor(desc; in1=A, in2=B)
    op = BinaryOp(op)(eltype(A), eltype(B))
    accum = getaccum(accum, eltype(C))
    if op isa TypedBinaryOperator
        libgb.GxB_kron(C, mask, accum, op, parent(A), parent(B), desc)
    elseif op isa TypedMonoid
        libgb.GrB_Matrix_kronecker_Monoid(C, mask, accum, op, parent(A), parent(B), desc)
    elseif op isa TypedSemiring
        libgb.GrB_Matrix_kronecker_Semiring(C, mask, accum, op, parent(A), parent(B), desc)
    else
        throw(ArgumentError("$op is not a valid monoid binary op or semiring."))
    end
    return C
end

"""
   kron(A::GBMatrix, B::GBMatrix, op = BinaryOps.TIMES; kwargs...)::GBMatrix

Kronecker product of two matrices using `op` as the multiplication operator.
Does not support `GBVector`s at this time.

# Arguments
- `A::GBMatrix`: optionally transposed.
- `B::GBMatrix`: optionally transposed.
- `op::MonoidBinaryOrRig = BinaryOps.TIMES`: the binary operation which replaces the arithmetic
    multiplication operation from the usual kron function.

# Keywords
- `mask::Union{Nothing, GBMatrix} = nothing`: optional mask.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc = nothing`
"""
function LinearAlgebra.kron(
    A::GBArray,
    B::GBArray,
    op = *;
    mask = nothing,
    accum = nothing,
    desc = nothing
)
    t = inferbinarytype(eltype(A), eltype(B), op)
    C = GBMatrix{t}(size(A,1) * size(B, 1), size(A, 2) * size(B, 2))
    kron!(C, A, B, op; mask, accum, desc)
    return C
end