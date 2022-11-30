using Plots, Parameters, Roots, Tables

SM = @with_kw (
    A = 1, # firm productivity
    ρ = 0.5, # exponent in matching function
    ψ = 0.35, # matching efficiency
    μ = 0.5, # worker bargaining power
    β = 0.96^(1/12), # (monthly) discount factor
    b = 0.4, # worker outside option
    πeu = 0.015 # exogenous separation rate
)

m(u, v, p) = p.ψ * u^p.ρ * v^(1-p.ρ)

## Functions: Define relevant function (equations that solve the model)
beveridge(u; p) = ((p.πeu*(1-u))/(p.ψ*u^p.ρ))^(1/(1-p.ρ))
wage_supply(θ, κ; p) = p.μ*p.A + (1-p.μ)*p.b + p.μ*κ*θ
wage_demand(θ, κ; p) = p.A - κ*(1-p.β*(1-p.πeu)) / (p.ψ*p.β*θ^(-p.ρ))

## Plots: Beveridge, Wage Supply and Demand
u_grid = range(0.01, 0.2, 50)
θ_grid = range(0.1, 1, 50)

plot(u_grid, beveridge.(u_grid; p=SM()), label = "Beveridge Curve (ψ = 0.35)")
plot!(u_grid, beveridge.(u_grid; p=SM(ψ=0.5)), label = "Beveridge Curve (ψ = 0.5)")
plot!(u_grid, beveridge.(u_grid; p=SM(πeu=0.02)), label = "Beveridge Curve (πeu = 0.02)")
savefig("bld/beveridge_curve.png")

plot(θ_grid, wage_supply.(θ_grid, 2; p=SM()), label = "Wage Supply")
plot!(θ_grid, wage_demand.(θ_grid, 2; p=SM()), label = "Wage Demand")
plot!(legend=:topleft)
savefig("bld/labor_market_eq.png")

function solve_model(p; target_πue = false, κ = false)
    
    @unpack A, ρ, ψ, μ, β, b, πeu = p

    m(u, v) = ψ * u^ρ * v^(1-ρ)

    function compute_equilibrium_θ(κ)
        f(θ) = wage_supply(θ, κ; p) - wage_demand(θ, κ; p)
        return find_zero(f, 1)
    end
    
    equilibrium_πue(θ) = m(θ^-1, 1) * θ

    # Calibrate κ if target_πue is specified
    if target_πue != false
        g(κ) = equilibrium_πue(compute_equilibrium_θ(κ)) - target_πue
        κ_calib = find_zero(g, 1)
    else κ_calib = κ
    end

    # Equilibrium w
    θ_supply(w, κ) = (w - μ*A - (1-μ)*b)/(μ*κ)
    θ_demand(w, κ) = (κ*(1-β*(1-πeu))/(ψ*β*(A-w)))^(-1/ρ)

    function compute_equilibrium_w(κ)
        f(w) = θ_supply(w, κ) - θ_demand(w, κ)
        return find_zero(f, 0)
    end

    equilibrium_u(u, θ) = πeu*(1-u) + (1-m(1,θ))*u - u
    function compute_equilibrium_u(θ)
        f(u) = equilibrium_u(u, θ)
        return find_zero(f, 0.05)
    end

    equilibrium_v(u, θ) = θ * u

    eqθ = compute_equilibrium_θ(κ_calib)
    eqw = compute_equilibrium_w(κ_calib)
    equ = compute_equilibrium_u(eqθ)
    eqv = equilibrium_v(equ, eqθ)
    eqπue = equilibrium_πue(eqθ)

    return (θ = eqθ, w = eqw, u = equ, κ = κ_calib, v = eqv, πue = eqπue)
end

# Get calibrated κ with standard parameters
p = SM()
κ_calib = solve_model(p; target_πue = 0.25).κ

## Comparative Statics
# Increase in μ --> less vacancies, higher wage, higher u
μ_grid = range(0.2, 0.8, 50)

cs_μ = [solve_model(SM(μ = μ); κ = κ_calib) for μ in μ_grid]
plot(μ_grid, columntable(cs_μ).v, label = "Vacancies")
plot!(μ_grid, columntable(cs_μ).w, label = "Wage")
plot!(μ_grid, columntable(cs_μ).u, label = "Unemployment")
plot!(legend=:right)

savefig("bld/comp_stats_mu.png")

# Increase in b --> less vacancies, higher wages, higher unemployment
b_grid = range(0.2, 0.8, 50)

cs_b = [solve_model(SM(b = b); κ = κ_calib) for b in b_grid]
plot(b_grid, columntable(cs_b).v, label = "Vacancies")
plot!(b_grid, columntable(cs_b).u, label = "Unemployment", legend=:left)
plot!(b_grid, columntable(cs_b).w, label = "Wage", legend=:right)
plot!(legend=:topright)

savefig("bld/comp_stats_b.png")

# Increase in matching efficiency --> Higher v, higher w, less u
ψ_grid = range(0.1, 2, 50)

cs_ψ = [solve_model(SM(ψ = ψ); κ = κ_calib) for ψ in ψ_grid]
plot(ψ_grid, columntable(cs_ψ).v, label = "Vacancies")
plot!(ψ_grid, columntable(cs_ψ).u, label = "Unemployment", legend=:left)
plot!(ψ_grid, columntable(cs_ψ).w, label = "Wage", legend=:right)
plot!(ψ_grid, columntable(cs_ψ).θ, label = "Tightness", legend=:left)
plot!(legend=:bottomright)

savefig("bld/comp_stats_ψ.png")
# TODO vacancies are not right
πeu_grid = range(0.001, 0.1, 50)

cs_πeu = [solve_model(SM(πeu = πeu); κ = κ_calib) for πeu in πeu_grid]
plot(πeu_grid, columntable(cs_πeu).v, label = "Vacancies")
plot!(πeu_grid, columntable(cs_πeu).u, label = "Unemployment", legend=:left)
plot!(πeu_grid, columntable(cs_πeu).w, label = "Wage", legend=:right)
plot!(πeu_grid, columntable(cs_πeu).θ, label = "Tightness", legend=:left)
plot!(legend=:right)

savefig("bld/comp_stats_πeu.png")
# TODO again, vacancies are wrong

SM(A = 2)

# Model solution for b = 0.4
A_grid = range(0.75, 1.25, 50)

solutions = [solve_model(SM(A = a); κ = κ_calib).u for a in A_grid]

plot(A_grid, solutions, label = "Unemployment Rate (b = 0.4)")

# Model solution for b = 0.95
p_highb = SM(b = 0.7)
κ_calib_highb = solve_model(p_highb; target_πue = 0.25).κ
A_grid_highb = range(0.8, 1.25, 50)
solutions_highb = [solve_model(SM(A = a, b = 0.7); κ = κ_calib_highb).u for a in A_grid_highb]

plot!(A_grid_highb, solutions_highb, label = "Unemployment Rate (b = 0.7)")

x = range(0, 2, 1000)
plot(x, log.(1 .+ x))
plot(x, log.(1 .+ x))
plot!(x, log.(x))

# kappa = 1.025
# 