using Polynomials
using UnicodePlots

function LagrangeInterpolatingPolynomial(x::Array{<:Real,1}, j::Int)
    p = Poly([1.0])
    d = 1.0
    for k = 1:length(x)
        if k != j 
            pₖ = Poly([-x[k], 1.0])
            dₖ = (x[j] - x[k])
            p *= pₖ
            d *= dₖ
        end
    end
    return p / d
end

function ∂LagrangeInterpolatingPolynomial(x::Array{<:Real,1}, j::Int)
    p = LagrangeInterpolatingPolynomial(x, j)
    ∂p∂x = polyder(p, 1)
    return ∂p∂x
end

function piecewise(xx::Array{<:Real,1}, pieces::Array{<:Real,1}, lower::Poly{Float64}, upper::Poly{Float64})
    y = copy(xx)
    for i = 1:length(xx)
        x = xx[i]
        if x < pieces[1]
            y[i] = 0
        elseif x > pieces[1] && x < pieces[2]
            y[i] = lower(x)
        elseif x >= pieces[2] && x < pieces[3]
            y[i] = upper(x)
        else 
            y[i] = 0
        end
    end
    return y
end

struct basisPolynomial
    basisPolynomial() = new([0.0], 0, 0, 0, 0)
    basisPolynomial(s    ::Array{<:Real, 1}, 
                    p₀   ::Poly{<:Real}, 
                    ∂p₀∂x::Poly{<:Real}, 
                    p₁   ::Poly{<:Real}, 
                    ∂p₁∂x::Poly{<:Real}) = new(s, p₀, ∂p₀∂x, p₁, ∂p₁∂x)

    support::Array{<:Real, 1}
    p₀   ::Poly{<:Real}
    ∂p₀∂x::Poly{<:Real}
    p₁   ::Poly{<:Real}
    ∂p₁∂x::Poly{<:Real}
end

function piecewise(x::Array{<:Real,1}, basis::basisPolynomial)
    return piecewise(x, 
                     basis.support, 
                     basis.p₀,
                     basis.p₁)
end


# In order to use P2 basis, we need the total number of points to be odd.
N = 7
@assert N >= 5
@assert N%2 == 1

nodes    = collect(range(0.0, stop=1.0, length=N))
elements = [[j for j = i:i+2] for i = 1:2:N-2]

# Generate basis of P2 functions
basis = []

for i = 1:length(elements)
    for j = 1:length(elements[i])
        p₀ = Poly([0.0])
        p₁ = Poly([0.0])
        ∂p₀∂x = Poly([0.0])
        ∂p₁∂x = Poly([0.0])

        if j == 1
            if i == 1
                p₀    = Poly([0.0])
                ∂p₀∂x = Poly([0.0])

                ind = elements[1]
                dx  = nodes[ind[2]] - nodes[ind[1]]
                support = [nodes[ind[1]]-dx, nodes[ind[1]], nodes[ind[2]]]
            else 
                n     = [nodes[elements[i-1][1]], nodes[elements[i-1][2]], nodes[elements[i-1][end]]]
                p₀    = LagrangeInterpolatingPolynomial(n, length(elements[i-1]))
                ∂p₀∂x = polyder(p₀)   
            end
            n     = [nodes[elements[i][1]], nodes[elements[i][2]], nodes[elements[i][end]]]
            p₁    = LagrangeInterpolatingPolynomial(n, 1)
            ∂p₁∂x = polyder(p₁)

            if i != 1 
                ind0 = elements[i-1]
                ind1 = elements[i]
                support = [nodes[ind0[1]], nodes[ind1[1]], nodes[ind1[end]]]
            end
        
        elseif j == length(elements[i])
            if i == length(elements)
                p₁      = Poly([0.0])
                ∂p₁∂x   = Poly([0.0]) 

                ind     = elements[length(elements)]
                dx      = nodes[ind[2]] - nodes[ind[1]]
                support = [nodes[ind[end-1]], nodes[ind[end]], nodes[ind[end]]+dx]
            else 
                n     = [nodes[elements[i+1][1]], nodes[elements[i+1][2]], nodes[elements[i+1][end]]]
                p₁    = LagrangeInterpolatingPolynomial(n, 1)
                ∂p₁∂x = polyder(p₁)
            end
            n     = [nodes[elements[i][1]], nodes[elements[i][2]], nodes[elements[i][end]]]
            p₀    = LagrangeInterpolatingPolynomial(n, length(elements[i]))
            ∂p₀∂x = polyder(p₀) 

            if i != length(elements)
                ind0 = elements[i]
                ind1 = elements[i+1]
                support = [nodes[ind0[1]], nodes[ind1[1]], nodes[ind1[end]]]
            end
        
        else
            n     = [nodes[elements[i][1]], nodes[elements[i][2]], nodes[elements[i][end]]]
            p₀    = LagrangeInterpolatingPolynomial(n, j)
            ∂p₀∂x = polyder(p₀) 

            p₁      = p₀
            ∂p₁∂x   = ∂p₀∂x
            support = [nodes[elements[i][1]], nodes[elements[i][2]], nodes[elements[i][end]]]
        end

        push!(basis, basisPolynomial(support, p₀, ∂p₀∂x, p₁, ∂p₁∂x))
    end
end

for i = 1:length(basis)
    x = collect(range(0.0, stop=1.0, length=100))
    plot = lineplot(x, piecewise(x, basis[i]))
    println(plot)
    println(basis[i])
end



