using JuMP
using Gurobi
#Implememnting the model
model = Model(Gurobi.Optimizer)

# Parameters
n = 9 #number of patients
p = [2, 3, 4, 6, 4, 1, 2, 1, 3]  # Treatment duration


# Decision Variables
@variable(model, s[1:n] >= 0, Int) #starting time of slot j
@variable(model, f[1:n] >= 0, Int) #finish time of slot j
@variable(model, x[1:n,1:n] >= 0, Bin); #assignment of patient i to slot j

# Objective function: minimize the starting time for each patient
@objective(model, Min, (1/n) * sum(s[j] for j=1:n))

# Constraints for Aux Variables
# ---------------------------------
# Only one patient should be assigned to each slot
@constraint(model, [j=1:n], sum(x[i, j] for i=1:n) == 1)

# Patient i is assigned to only one slot
@constraint(model, [i=1:n], sum(x[i, j] for j=1:n) == 1)

# Linking slot x with time p
@constraint(model, [ j=1:n, i=1:n], s[j]*x[i, j] + p[i] * x[i, j] <= f[j] )

# Non-overlapping treatments
@constraint(model, [j=2:n], s[j] >= f[j-1]);

optimize!(model)


if termination_status(model) == MOI.OPTIMAL
    println(string("Optimal average waiting time: ", objective_value(model)))

    println("Optimal starting times and assigned slots:")
    for i = 1:n
        println("Patient $i starts at: ", value(s[i]))

    end
else
    println("No optimal solution found.")
end
