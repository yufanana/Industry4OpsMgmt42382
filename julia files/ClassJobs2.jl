#************************************************************************
# Incredible Chairs 2 assignment, LP
using JuMP
using HiGHS
#************************************************************************

#************************************************************************
# Parameters
Children=[1 2 3 4 5]
C=length(Children)
Jobs=[1 2 3 4 5]
J=length(Jobs)
Wish=[
    1 3 2 5 5;
    5 2 1 1 2;
    1 5 1 1 1;
    4 5 4 4 4;
    3 5 3 5 3]

TimeReq=[
    1 2 1 4 4;
    6 2 4 2 2;
    3 3 2 4 4;
    1 1 4 4 2;
    7 2 2 3 1
]
TimeLimit=3
#************************************************************************

#************************************************************************
# Model
CJ = Model(HiGHS.Optimizer)

#@variable(CJ,x[j=1:J,c=1:C] >= 0)
@variable(CJ,x[j=1:J,c=1:C], Bin)

# Maximize aggregated Wish
@objective(CJ, Max, sum( Wish[j,c]*x[j,c] for j=1:J,c=1:C ) )

# One job pr. child
@constraint(CJ, [c=1:C],
            sum( x[j,c] for j=1:J) == 1
            )

# One child pr. job
@constraint(CJ, [j=1:J],
            sum( x[j,c] for c=1:C) == 1
            )

# timelimit pr. job pr. child
@constraint(CJ, [j=1:J],
            sum( TimeReq[j,c]*x[j,c] for c=1:J) <= TimeLimit
            )

#************************************************************************

#************************************************************************
# Solve
solution = optimize!(CJ)
println("Termination status: $(termination_status(CJ))")
#************************************************************************

#************************************************************************
if termination_status(CJ) == MOI.OPTIMAL
    println("Optimal objective value: $(objective_value(CJ))")
    println("x: ",value.(x))
else
    println("No optimal solution available")
end
#************************************************************************
