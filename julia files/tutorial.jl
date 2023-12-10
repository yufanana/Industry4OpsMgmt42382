# Run line: Ctrl + Enter
print("Hello world")

# Run block: Alt + Enter
# Run cell: Shift + Enter
# Run file: "Julia: Execute File in REPL"
# Clear Julia REPL: Ctrl + L

θ = π/4
# \theta = \pi/4

## Optionally-typed variables
a = 1 + 1         
typeof(a)       # Int64
a = "Hello"     
typeof(a)       # String

# Integer Conversion
Int64(2.0)          # 2
Int64(2.4)          # Error!
floor(Int64,2.4)    # 2
ceil(Int64,2.4)     # 3
round(Int64,2.4)    # 2

# Integer Division
a = 1/2             # 0.5 (Float64)
div(10,3)           # 3
÷(10,3)             # 3
rem(10,3)           # 1
10%3                # 1

## Boolean variables
# && and || are short-circuited
# not: !x

if @isdefined(ge) && ge>0
    print("ge exists and is greater than 0")
end

if 3 > 2 || expensive_computation(b) > 0
    do_something()
end

# Bool is subtype of Integer
true + true         # 2

## Strings
"Hello"             # string
'H'                 # char
'Hello'             # error: character literal contains multiple characters

# Concatenate
"Hello " * "wor" * "ld"
string("Hello", " ", "world")

# Convert Number to String
string(1/7)               # Returns "0.14285714285714285".
"$(1/7)"                  # Returns "0.14285714285714285".
`@sprintf("%6.4f",1/7)`   # Returns `"0.1429"`

string("Approximated pi to 25/8, which is ", 25/8)
"Approximated pi to 25/8, which is $(25/8)"

rmse = 1.5; mse = 1.1; R2 = 0.94
"Our model has a R^2 of $(R2), rmse of $(rmse), and mse of $(mse)"

using Printf
str = @sprintf("Archimedes approximated pi to 22/7, which is %.4f...", 22/7)


## For Loops
x = 0
for k in 1:100000
    x = x + (1/k)^2
end

for i in 1:3
    for j in 1:3
        print("i=", i, " j=", j, "\n")
    end
end

for i in 1:3, j in 1:3
    print("i=", i, " j=", j, "\n")
end

for i ∈ 1:3, j ∈ 1:3
    print("i=", i, " j=", j, "\n")
end

x=0
for k in 1:100000
    term = (1/k)^2
    x = x + term
    if (abs(term) < 1e-10) break end
end

# continue: exit the present iteration of a for-loop, 
# then continue with next iteration
numbers = randn(100)
sum = 0
for k in numbers
    if (k==0) continue end
    sum = sum + 1/k
end

## Functions
function sum_zeta(s,nterms)
    x = 0
    for n in 1:nterms
        x = x + (1/n)^s
    end
    return x
end

sum_zeta(2,100000)      # returns 1.6449240668982423

sum_zeta(s,nterms) = sum(1/n^s for n=1:nterms)
sum_zeta(s, nterms=10000) = sum(1/n^s for n=1:nterms)   # optional arguments
sum_zeta(s; nterms=10000) = sum(1/n^s for n=1:nterms)   # keyword arguments

function circle(r)
    area = π * r^2
    circumference = 2π * r
    return area, circumference
end

a, c = circle(1.5)      # multiple outputs
shape = circle(1.5)

function add_one!(x)    # modifies mutable inputs
    x .= x .+ 1
end

x = [1,2,3]
add_one!(x);    # x is now [2,3,4]

function secant(f,a,b,rtol,maxIters)
    iter = 0
    while abs(b-a) > rtol*abs(b) && iter < maxIters
        c,a = a,b
        b = b + (b-c)/(f(c)/f(b)-1)
        iter = iter + 1
    end
    return b
end

# Anonymous function
φ = secant( x-> x^2 - x - 1, 1, 2, 1e-15, 10 )

include("myFunctions.jl")
x = sum_series(100000)

## Arrays
A = [1 2 3; 1 2 4; 2 2 2]     # 3×3 Matrix{Float64}
A = [1 2 3; 
     1 2 4; 
     2 2 2] 

b1 = [4.0, 5, 6]                # 3-element Vector{Float64}
b2 = [4.0; 5; 6]                # 3-element Vector{Float64}
m1 = [4.0 5 6]                  # 1×3 Matrix{Float64}

A = ["Hello", 1, 2, 3]

# Array comprehension
v = [1/n^2 for n=1:100000]
x = sum(v)

gen = (1/n^2 for n=1:100000)    # generator
x = sum(gen)

# Initializing without values for performance
n = 5
A1 = Array{Float64}(undef,n,n)          # 5×5 Matrix{Float64}
A2 = Matrix{Float64}(undef,n,n)         # 5×5 Matrix{Float64}

V1 = Array{Float64}(undef,n)            # 5-element Vector{Float64}
V2 = Vector{Float64}(undef,n)           # 5-element Vector{Float64}

A = Array{String}(undef,n)
A = Array{Any}(undef,n)

v = Array{Float64}(undef,0)             # Empty array
v = Float64[]

v = []    # Same as Any[], can't change this type easily later

# Special kind of arrays
A = zeros(8,9)
B = ones(8,9)
C = rand(6,6)

using LinearAlgebra
M = 5I + rand(2,2)
# 2×2 Matrix{Float64}:
# 5.50162   0.462804
# 0.498287  5.30439

# Using 'dot' to apply function elementwise to an array
f(x) = 3x^3/(1+x^2)
x = [2π/n for n=1:30]
y = f.(x)

y = sin.(x)
y = 2x.^2 + 3x.^5 - 2x.^8
y = @. 2x^2 + 3x^5 - 2x^8       # Broadcast dot operator

# Arrays indexing: 1-based indexed
A = rand(6)
A[begin]
A[end]

# Array slicing
A = rand(6,6)                   # 6×6 Matrix{Float64}
# extract odd indices
B = A[begin:2:end,begin:2:end]  # 3×3 Matrix{Float64}
C = A[1:2:5,1:2:5]              # Same as B

A = rand(6,6)
A[A .< 0.5] .= 0
# An array of booleans is created with A .< 0.5, which is subsquently 
# used to access those elements of A. Finally, the assignment = operator 
# is used to set the selected elements to 0. Note that both the comparison 
# and the assignment operator have to be broadcasted.

A = rand(6)
for i ∈ eachindex(A)
    println(string("i=$(i) A[i]=$(A[i])"))
end

A = rand(4,6)
for i ∈ 1:size(A,1), j ∈ 1:size(A,2)
    println(string("i=$(i) j=$(j) A[i,j]=$(A[i,j])"))
end

firstindex(A,dim)
lastindex(A,dim)
similar(Array{Float64}, axes(A))    # allocate an array with the same indices as A


A * B       # mat-mat multiplication
A * v       # mat-vec multiplication
A .* B      # element-wise multiplication

v = rand(1000)
w = rand(1000)
z = dot(v,w)    # dot product
z = v'w         # dot product

# 1xN matrices not same as N-element vectors
b1 = [4.0, 5, 6]                # 3-element Vector{Float64}
b2 = [4.0; 5; 6]                # 3-element Vector{Float64}
m1 = [4.0 5 6]                  # 1×3 Matrix{Float64}

x=A\b1                          # Solves A*x=b
x=A\b2                          # Solves A*x=b  
x=A\m1                          # Error!!

A = Float64[]       # Equivalent to A=Array{Float64}(undef,0)
push!(A, 4)         # Adds the number 4 at the end of the array
push!(A, 3)         # Adds the number 3 at the end of the array
v = pop!(A)         # Returns 3 and removes it from A

# Resizing, Concatenating Arrays
using StaticArrays
using SpareArrays

A = Float64[]       # Equivalent to A=Array{Float64}(undef,0)
push!(A, 4)         # Adds the number 4 at the end of the array
push!(A, 3)         # Adds the number 3 at the end of the array
v = pop!(A)         # Returns 3 and removes it from A

pushfirst!(A,4)
popfirst!(A)
splice!(A,i)
deleteat!(A,i)

A = [4 5 6] 
B = [6 7 8] 

M1 = vcat(A, B)
M1 = [A; B]
# 2×3 Matrix{Int64}:
#  4  5  6
#  6  7  8
M2 = hcat(A, B)
M2 = [A B]
# 1×6 Matrix{Int64}:
#  4  5  6  6  7  8
M2 = cat(A, B, dims=2)


# Tuples: values are non-modifiable
t = (3.14, 2.72)
t = 3.14, 2.72
t[1]
# Override with another tuple
t = t .* 2
t = (2*t[1], t[2])

# Convert Tuples to Array
a = (1, 2, 3)
t1 = collect(a);
t1 = [x for x in a];
t1 = [a...];           
pi_approx, e_approx = t

p = (x = 1.1, y = 2.4)
K = keys(p)                 # (:x, :y)
V = values(p)               # (1.1, 2.4)
p_new = (; zip(K,V)...)     # (x = 1.1, y = 2.4)

# Merging named tuples
TemporalParams = ( 
    Δt = 0.1, 
    T = 2
)
SpatialParams = ( 
    Δx = 0.05, 
    a = 0,
    b = 100
)
TotalParams = merge(TemporalParams, SpatialParams)

# Destructure tuples, only use a few new variables
(; a,b,Δt ) = TotalParams

## Dictionary
D = Dict("a" => 1, "b" => 2, 1 => "a")
D = Dict([("a", 1), ("b", 2), (1,"a")])

# Iterating
for e in D
    println(e)
end
for (k,v) in D
    println(k, " => ", v)
end

# Modifying
D["c"] = 3           # Adding a new key
D["c"] = "Hello"     # Updating existing key
D = delete!(D, "c")  # Deleting an existing key


## Structs
# non-modifiable after initializing
struct Location
    name::String
    lat::Float32
    lon::Float32
end

loc1 = Location("Los Angeles", 34.0522,-118.2437)
loc1.name   # "Los Angeles"
loc1.lat    # 34.0522
loc1.lon    # -118.2437

sites = Location[]
push!(sites, Location("Los Angeles", 34.0522,-118.2437))
push!(sites, Location("Las Vegas", 36.1699,-115.1398))

# Use default values in structs
@kwdef mutable struct Param
    Δt :: Float64 = 0.1
    n :: Int64
    m :: Int64
end
P = Param(m=50, n=35)

(; n,Δt ) = P       # Destructure


## Plotting
using Plots
gr()

x = 0:0.05:1;
y = sin.(2π*x);
plot(x,y)

## Multiple dispatch
f( x :: Int ) = "This is an Int: $(x)"
f( x :: Float64 ) = "This is a Float: $(x)"
f( x :: Any) = "This is a generic fallback"

using Meshes

barycenter( t :: Triangle ) = 
    Point([sum([ 1/3 *t.vertices[i].coords[j] for i in 1:3]) for j in 1:2])

using MeshViz
import GLMakie as Mke

t = Triangle((0.,0.), (1.,1.), (0.,2.))
bary = barycenter(t)

viz(t)
viz!(bary,color=:red)






