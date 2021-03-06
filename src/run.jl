# @doc doc"""
# lag{Float64}(x::Array{Float64}, n::Int64=1)
# 
# Lag an array by `n` steps.
# 
# - If `n` == 0, then `x` is returned.
# - If `n` > 0, then rows of `x` are shifted downwards `n` times.
# - If `n` < 0, then rows of `x` are shifted upwards `n` times.
# """ ->
# function lag{Float64}(x::Array{Float64}, n::Int64=1)
#     @assert abs(n)<size(x,1) "Argument n out of bounds."
#     if n == 0
#         return x
#     elseif n > 0
#         out = zeros(x)
#         out[1:n,:] = NaN
#         out[n+1:end,:] = x[1:end-n,:]
#         return out
#     elseif n < 0
#         out = zeros(x)
#         out[end+n+1:end,:] = NaN
#         out[1:end+n,:] = x[1-n:end,:]
#         return out
#     end
# end

# @doc doc"""
# Lag an array by `n` steps.
# 
# - If `n` == 0, then `x` is returned.
# - If `n` > 0, then rows of `x` are shifted downwards `n` times.
# - If `n` < 0, then rows of `x` are shifted upwards `n` times.
# """ ->
# function lag{Float64}(x::Array{Float64}, n::Int64=1)
#     @assert abs(n)<size(x,1) "Argument n out of bounds."
#     if n == 0
#         return x
#     elseif n > 0
#         out = zeros(x)
#         out[1:n,:] = NaN
#         out[n+1:end,:] = x[1:end-n,:]
#         return out
#     elseif n < 0
#         out = zeros(x)
#         out[end+n+1:end,:] = NaN
#         out[1:end+n,:] = x[1-n:end,:]
#         return out
#     end
# end

@doc doc"""
Lagged differencing
""" ->
function diffn{Float64}(x::Vector{Float64}, n::Int64=1)
    @assert n<size(x,1) && n>0 "Argument n out of bounds."
    out = zeros(x)
    out[1:n] = NaN
    @inbounds for i=n+1:size(x,1)
        out[i] = x[i] - x[i-n]
    end
    return out
end

@doc doc"""
Lagged differencing
""" ->
function diffn{Float64}(X::Array{Float64,2}, n::Int64=1)
    @assert n<size(X,1) && n>0 "Argument n out of bounds."
    out = zeros(X)
    @inbounds for j = 1:size(X,2)
        out[:,j] = diffn(X[:,j], n)
    end
    return out
end

@doc doc"""
Compute the mode of an arbitrary array

(Adapted from StatsBase: https://raw.githubusercontent.com/JuliaStats/StatsBase.jl/master/src/scalarstats.jl)
""" ->
function mode{Float64}(a::AbstractArray{Float64})
    isempty(a) && error("mode: input array cannot be empty.")
    cnts = Dict{Float64,Int64}()
    # first element
    mc = 1
    mv = a[1]
    cnts[mv] = 1
    # find the mode along with table construction
    @inbounds for i = 2 : length(a)
        x = a[i]
        if haskey(cnts, x)
            c = (cnts[x] += 1)
            if c > mc
                mc = c
                mv = x
            end
        else
            cnts[x] = 1
            # in this case: c = 1, and thus c > mc won't happen
        end
    end
    return mv
end

@doc doc"""
Compute a running or rolling arithmetic mean of an array.
""" ->
function runmean{Float64}(x::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        fi = 1.0:size(x,1)
        @inbounds for i = n:size(x,1)
            out[i] = sum(x[1:i])/fi[i]
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = mean(x[i-n+1:i])
        end
    end
    return out
end


@doc doc"""
Compute a running or rolling summation of an array.
""" ->
function runsum{Float64}(x::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    if cumulative
        out = cumsum(x)
        out[1:n-1] = NaN
    else
        out = zeros(x)
        out[1:n-1] = NaN
        @inbounds for i = n:size(x,1)
            out[i] = sum(x[i-n+1:i])
        end
    end
	return out
end

@doc doc"""
Welles Wilder summation of an array
""" ->
function wilder_sum{Float64}(x::Vector{Float64}, n::Int64=10)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    nf = float(n)  # type stability -- all arithmetic done on floats
    out = zeros(x)
    out[1] = x[1]
    @inbounds for i = 2:size(x,1)
        out[i] = x[i] + out[i-1]*(nf-1.0)/nf
    end
    return out
end

@doc doc"""
Compute the running or rolling mean absolute deviation of an array
""" ->
function runmad{Float64}(x::Vector{Float64}, n::Int64=10, cumulative::Bool=true; fun::Function=median)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    center = 0.0
    if cumulative
        fi = collect(1.0:size(x,1))
        @inbounds for i = n:size(x,1)
            center = fun(x[1:i])
            out[i] = sum(abs(x[1:i]-center)) / fi[i]
        end
    else
        fn = float(n)
        @inbounds for i = n:size(x,1)
            center = fun(x[i-n+1:i])
            out[i] = sum(abs(x[i-n+1:i]-center)) / fn
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling variance of an array
""" ->
function runvar{Float64}(x::Vector{Float64}, n::Int64=10, cumulative=true)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        @inbounds for i = n:size(x,1)
            out[i] = var(x[1:i])
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = var(x[i-n+1:i])
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling standard deviation of an array
""" ->
function runsd{Float64}(x::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    return sqrt(runvar(x, n, cumulative))
end

@doc doc"""
Compute the running or rolling covariance of two arrays
""" ->
function runcov{Float64}(x::Vector{Float64}, y::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    @assert length(x) == length(y) "Dimension mismatch: length of `x` not equal to length of `y`."
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        @inbounds for i = n:length(x)
            out[i] = cov(x[1:i], y[1:i])
        end
    else
        @inbounds for i = n:length(x)
            out[i] = cov(x[i-n+1:i], y[i-n+1:i])
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling correlation of two arrays
""" ->
function runcor{Float64}(x::Vector{Float64}, y::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    @assert length(x) == length(y) "Dimension mismatch: length of `x` not equal to length of `y`."
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    out[1:n-1] = NaN
    if cumulative
        @inbounds for i = n:length(x)
            out[i] = cor(x[1:i], y[1:i])
        end
    else
        @inbounds for i = n:length(x)
            out[i] = cor(x[i-n+1:i], y[i-n+1:i])
        end
    end
    return out
end

@doc doc"""
Compute the running or rolling maximum of an array.
""" ->
function runmax{Float64}(x::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    if cumulative
        out[n] = maximum(x[1:n])
        @inbounds for i = n+1:size(x,1)
            out[i] = max(out[i-1], x[i])
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = maximum(x[i-n+1:i])
        end
    end
    out[1:n-1] = NaN
    return out
end

@doc doc"""
Compute the running or rolling minimum of an array.
""" ->
function runmin{Float64}(x::Vector{Float64}, n::Int64=10, cumulative::Bool=true)
    @assert n<size(x,1) && n>0 "Argument n is out of bounds."
    out = zeros(x)
    if cumulative
        out[n] = minimum(x[1:n])
        @inbounds for i = n+1:size(x,1)
            out[i] = min(out[i-1], x[i])
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = minimum(x[i-n+1:i])
        end
    end
    out[1:n-1] = NaN
    return out
end
