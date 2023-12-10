using JuMP
using Gurobi
import XLSX


function solve_order_picking()
    model = Model(Gurobi.Optimizer);

    # C:/Users/yufan/OneDrive - Danmarks Tekniske Universitet/Courses/- 42382 Industry 4.0/julia files
    filename = "C:/Users/yufan/OneDrive - Danmarks Tekniske Universitet/Courses/- 42382 Industry 4.0/julia files/08-picking.xlsx"
    xf = XLSX.readxlsx(filename)
    sheet= xf["C"]
    C = sheet["A1:Y25"]

    # Parameters
    R = [1 2 3 4 5 6 25]
    R_without = [1 2 3 4 5 6]   # without depot node
    R_complement = [7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]   # V \ R
    n = size(C,1)

    # Variables for each arc in the graph
    @variable(model, x[i=1:n,j=1:n;C[i,j] > 0] >= 0, Bin);
    @variable(model, y[i=1:n,j=1:n;C[i,j] > 0] >= 0, Int);

    # Objective
    @objective(model, Min, sum(C[i,j] * x[i,j] for i = 1:n, j=1:n if C[i,j] > 0));

    # Constraints
    @constraint(model, [i=1:n], sum(x[i,j] for j=1:n if C[i,j] > 0) == sum(x[j,i] for j=1:n if C[j,i] > 0));
    @constraint(model, [i in R], sum(x[i,j] for j=1:n if C[i,j] > 0) >= 1);
    @constraint(model, [i in R_without], sum(y[j,i] for j=1:n if C[j,i] > 0) - sum(y[i,j] for j=1:n if C[i,j] > 0) == 1);
    @constraint(model, [i in R_complement], sum(y[j,i] for j=1:n if C[j,i] > 0) - sum(y[i,j] for j=1:n if C[i,j] > 0) == 0);
    @constraint(model, [i=1:n,j=1:n; C[i,j] > 0], y[i,j] <= size(R_without,2)*x[i,j]);

    # Solve model
    optimize!(model)

    # Results
    println("RESULTS:")
    println(string("Distance of optimal route: ", objective_value(model)))
    println("Used arcs: ")
    JuMP.value.(x)
end

solve_order_picking()

# RESULTS:
# Distance of optimal route: 184.5
# Used arcs:
# JuMP.Containers.SparseAxisArray{Float64, 2, Tuple{Int64, Int64}} with 68 entries:
#   [1, 10 ]  =  0.0
#   [10, 3 ]  =  1.0
#   [11, 1 ]  =  0.0
#   [11, 12]  =  0.0
#   [11, 17]  =  1.0
#   [12, 18]  =  -0.0
#   [13, 12]  =  -0.0
#   [13, 19]  =  -0.0
#   [14, 15]  =  0.0
#   [14, 2 ]  =  1.0
#   [15, 14]  =  1.0
#   [15, 16]  =  0.0
#   [15, 5 ]  =  1.0
#   [17, 18]  =  -0.0
#   [19, 13]  =  -0.0
#             ⋮
#   [19, 25]  =  -0.0
#   [2, 14 ]  =  0.0
#   [20, 14]  =  -0.0
#   [20, 21]  =  -0.0
#   [22, 23]  =  0.0
#   [23, 22]  =  0.0
#   [23, 24]  =  1.0
#   [24, 23]  =  1.0
#   [3, 10 ]  =  1.0
#   [5, 21 ]  =  -0.0
#   [7, 18 ]  =  -0.0
#   [7, 24 ]  =  0.0
#   [8, 2  ]  =  0.0
#   [8, 9  ]  =  1.0


# YF: weird that [10, 3 ]  =  1.0 exists even though the edge is not possible