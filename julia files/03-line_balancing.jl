using JuMP
using Gurobi

function solve_seq()

    #------
    # MODEL
    #------

	n = 12; # number of operations

	t = [5 2 8 10 3 8 1 7 9 10 3 4]; # time to complete operation

	r = 0.1; # reconfiguration time

	T = 0.1; # target line throughput

	m = 12; # number of workstations
	# C = 3; # max number of operations per workstation
	C = 12; # fully flexible machines

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:n,1:m] >= 0, Bin);
	@variable(model, y[1:m] >= 0, Int);
	@variable(model, l[1:n,1:m] >= 0, Bin);
	@variable(model, o[1:n,1:m] >= 0, Bin);

    @objective(model, Min, sum(y[k] for k = 1:m));

	@constraint(model, [i=1:n], sum(x[i,k] for k=1:m) == 1);
	@constraint(model, [k=1:m], sum(x[i,k] for i=1:n) <= C);

	@constraint(model, [k=1:m], sum((t[i]+r)*x[i,k] - r*o[i,k] for i=1:n) <= y[k]/T);

	@constraint(model, [i=1:n-1,k=1:m], x[i,k] <= x[i+1,k] + l[i,k]);
	@constraint(model, [k=1:m], sum(l[i,k] for i=1:n) == 1);

	@constraint(model, [k=1:m], x[n,k] == l[n,k]);
	@constraint(model, [i=1:n-1,j=i+1:n,k=1:m-1,h=k:m], l[i,h] + l[j,k] <= 1)

	@constraint(model, [i=1,k=1:m], o[i,k] == l[i,k])
	@constraint(model, [i=2:n,k=1:m], 2o[i,k] <= l[i,k] + (1 - x[i-1,k]))

    #-------
    # SOLVE
    #-------

    optimize!(model)

	println();

	EPS = 0.000001; # to deal with rounding errors by the solver

	capacities = [Inf for i=1:m]
	for k = 1:m
		n_machines = round(value(y[k]));
		print("workstation ",k,": machines: ",n_machines," operations: ");
		for i =1:n
			if (value(x[i,k]) < 1 + EPS && value(x[i,k]) > 1 - EPS)
				print(i," ")
			end
		end
		print("capacity: ")
		proc_time = 0;
		for i =1:n
			if (value(x[i,k]) < 1 + EPS && value(x[i,k]) > 1 - EPS)
				proc_time += t[i] + r
			end
			if (value(o[i,k]) < 1 + EPS && value(o[i,k]) > 1 - EPS)
				proc_time -= r
			end
		end
		println(n_machines/proc_time)
		if proc_time != 0
			capacities[k] = n_machines/proc_time
		end
	end

	println("\nthroughput = ",minimum(capacities))

end

solve_seq();
