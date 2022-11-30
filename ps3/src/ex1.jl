using Plots, RollingFunctions, Distributions, Statistics

λ = 0.2 # probability of job offer
α = 1 - 0.3 # acceptance probability

πᵤ = λ*α

# Calculate expected unemployment rate
T = πᵤ^-1

term(t, p) = t * p * (1-p)^(t-1)
sumup(x) = [sum(x[1:i]) for i in 1:length(x)]

terms = term.(1:50, πᵤ)
partialsums = sumup(terms)

plot(partialsums, label = "Partial Sums")
plot!(terms, label = "Sequence")
hline!([T], linestyle=:dash, label = "Analytic Solution")
plot!(legend=:right)

# Interpret as Bernoulli Process
X = Geometric(πᵤ)

1/πᵤ == mean(X) + 1 # Note defined as number of failures before first success thus one less
