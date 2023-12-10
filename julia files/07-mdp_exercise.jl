using JuMP
using Gurobi

function solve_mdp()

    #------
    # MODEL
    #------

    model = Model(Gurobi.Optimizer);

    @variable(model, C[1:2] >= 0);
	@variable(model, z[1:2] >= 0, Bin);

    @objective(model, Max, C[2]);

    # the z[1]*100000 kind of removes the constraint if z[1]=1
    @constraint(model, C[1] <=  5 + 0.5*0.9*C[1] + 0.5*0.9*C[2] + z[1]*100000);
	@constraint(model, C[1] <= 10 + 0.2*0.9*C[1] + 0.8*0.9*C[2] + (1-z[1])*100000);
	@constraint(model, C[2] <=  2 + 0.3*0.9*C[1] + 0.7*0.9*C[2] + z[2]*100000);
	@constraint(model, C[2] <= -7 + 0.9*0.9*C[1] + 0.1*0.9*C[2] + (1-z[2])*100000);

    #-------
    # SOLVE
    #-------

    optimize!(model)

	println("");

	println(value(C[1]));
	println(value(C[2]));
end

solve_mdp();

# 47.15596330275231
# 39.81651376146791
