using JuMP
using Gurobi

function solve_project()

    #------
    # DATA
    #------

	n = 4; # non failure states

    P = [ # non failure transition probabilities
			0.89	0.09	0.02	0	;
			0		0.64	0.28	0.08;
			0		0		0.56	0.32;
			0		0		0		0.14;
		]

	f = [0 0 0.12 0.86] # failure probabilities

	p = 3000; # preventive maintenance cost
	c = 8500; # corrective maintenance cost

	r = 0.99; # discount rate

    #------
    # MODEL
    #------

    model = Model(Gurobi.Optimizer);

    @variable(model, C[1:n] >= 0); # expected discounted cost
	@variable(model, z[1:n] >= 0, Bin);

    @objective(model, Min, C[1]);

	# C = min(M,N)
	# M: cost of doing maintenance now
    @constraint(model,[i = 1:n], C[i] >= p + r*C[1] - z[i]*100000);
	# N: cost of not doing maintenance now
	@constraint(model,[i = 1:n], C[i] >= r*(sum(P[i,j]*C[j] for j = 1:n) + f[i]*(c + r*C[1])) - (1-z[i])*100000);

    #-------
    # SOLVE
    #-------

    optimize!(model)

	println("")

	for i = 1:n
		println(value(C[i]),"\t",p + r*value(C[1]),"\t",r*(sum(P[i,j]*value(C[j]) for j = 1:n) + f[i]*(c + r*value(C[1]))));
	end

end

solve_project();

# Infinite horizon
# C[i]					 M[i]					 N[i]
# 23665.828692307834     26429.170405384757      23665.828692307834
# 25707.85025239937      26429.170405384757      25707.850252399374
# 26429.170405384757     26429.170405384757      26818.27870133091
# 26429.170405384757     26429.170405384757      30847.57870133091

