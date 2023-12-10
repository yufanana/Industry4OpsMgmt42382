using JuMP
using Gurobi

function solve_order_processing()
    # Parameters
    tau = 10
    n = 3
    m = 5
    C = 2

    O = [
        1 0 0 0 1 0 0 0 0
        0 0 1 1 1 0 0 0 0
        0 1 0 0 0 1 1 1 1
    ]

    k = size(O,2)

    R = [
        1 1 0 0 0 0 0 0 0
        0 0 1 1 0 0 1 0 0
        0 0 0 0 1 1 0 0 0
        0 1 1 0 0 0 0 1 0
        0 0 0 0 0 0 0 1 1
    ]

    # Model
    model = Model(Gurobi.Optimizer);

    # Variables
    @variable(model, x[1:m,1:tau] >= 0, Bin);
    @variable(model, z[1:k,1:n,1:tau] >= 0, Bin);
    @variable(model, y[1:n,1:tau] >= 0, Bin);
    @variable(model, a[2:tau] >= 0, Bin);

    # Objective
    @objective(model, Min, sum(a[t] for t = 2:tau))

    # Constraints
    @constraint(model,[t=1:tau],sum(x[j,t] for j=1:m) <= 1)
    @constraint(model,[t=1:tau],sum(y[i,t] for i=1:n) <= C)

    for t=1:tau
        for t_acc=t+1:tau
            for t_acc_acc=t+1:t_acc-1
                @constraint(model,[i=1:n], y[i,t] + y[i,t_acc] <= 1+y[i,t_acc_acc])
            end
        end
    end

    for i=1:n
        for s=1:k
            if O[i,s] == 1
                @constraint(model,sum(z[s,i,t] for t=1:tau) >= 1)
            end
        end
    end

    for i=1:n
        for s=1:k
            if O[i,s] == 1
                @constraint(model,[t=1:tau],2*z[s,i,t] <= y[i,t] + sum(R[j,s] * x[j,t] for j=1:m))
            end
        end
    end

    @constraint(model,[t=2:tau,j=1:m],a[t] >= x[j,t] - x[j,t-1])

    # Solve model 
    optimize!(model)

    # Results
    println(string("Number of switches: ", objective_value(model)))
end

solve_order_processing()