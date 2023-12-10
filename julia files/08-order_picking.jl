using JuMP
using Gurobi

function solve_order_picking()
    model = Model(Gurobi.Optimizer);

    # Parameters
    C = [
        0 1 0 0 0;
        0 0 1 0 1;
        0 1 1 0 1;
        1 1 0 0 0;
        1 0 0 1 1;
        ]; # 0 values indicate that an arc is not present

    R = [1 2 3]
    R_without = [2 3]
    R_complement = [4 5]
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