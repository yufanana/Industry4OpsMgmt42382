#************************************************************************
# Incredible Chairs, Simple LP
using JuMP
using HiGHS
#************************************************************************

#************************************************************************
# PARAMETERS

# no parameters

#************************************************************************

#************************************************************************
# Model
IC = Model(HiGHS.Optimizer)

@variable(IC,xA >= 0)
@variable(IC,xB >= 0)

@objective(IC, Max, 4*xA+6*xB)

@constraint(IC, 2*xA <= 14)
@constraint(IC, 3*xB <= 15)
@constraint(IC, 4*xA + 3*xB <= 36)
#************************************************************************

#************************************************************************
# Solve
solution = optimize!(IC)
println("Termination status: $(termination_status(IC))")
#************************************************************************

#************************************************************************
# Solution
if termination_status(IC) == MOI.OPTIMAL
    println("Optimal objective value: $(objective_value(IC))")
    println("Production of chair A: ",value(xA))
    println("Production of chair B: ",value(xB))
else
    println("No optimal solution available")
end
#************************************************************************
