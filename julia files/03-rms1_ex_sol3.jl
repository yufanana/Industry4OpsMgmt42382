using JuMP
using Gurobi

function solve_seq()

    #------
    # MODEL
    #------

	n = 20; # number of operations
	m = 12; # number of workstations

	t = [11	15	10	15	13	17	13	16	17	16	13	13	17	18	20	17	10	20	11	19]; # time to complete operation

	r = 3; # reconfiguration time

	T = 0.06; # target line throughput

	C = 3; # max number of operations per workstation

	max_machines = [5 5 5 6 1 1 1 3 4 1 3 5] #

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

	@constraint(model, [k=1:m], y[k] <= max_machines[k]);

    #-------
    # SOLVE
    #-------

    optimize!(model)

	println();

	EPS = 0.000001; # to deal with rounding errors by the solver

	capacities = [Inf for i=1:m]
	proc_time = zeros(m)
	n_machines = zeros(m)
	for k = 1:m
		n_machines[k] = round(value(y[k]));
		print("workstation ",k,": machines: ",n_machines[k]," operations: ");
		for i =1:n
			if (value(x[i,k]) < 1 + EPS && value(x[i,k]) > 1 - EPS)
				print(i," ")
			end
		end
		print("capacity: ")
		for i =1:n
			if (value(x[i,k]) < 1 + EPS && value(x[i,k]) > 1 - EPS)
				proc_time[k] += t[i] + r
			end
			if (value(o[i,k]) < 1 + EPS && value(o[i,k]) > 1 - EPS)
				proc_time[k] -= r
			end
		end
		println(n_machines[k]/proc_time[k]);
		if n_machines[k] != 0
			capacities[k] = n_machines[k]/proc_time[k]
		end
	end

	TH = minimum(capacities)
	CT = 1/TH # cycle time
	println("\nthroughput = ",TH)
	println("cycle time = ",CT)

	println("\nutilizations:")
	for k = 1:m
		idle_time = CT*n_machines[k]-proc_time[k]
		println("\tworkstation ",k,": ",proc_time[k]/(proc_time[k]+idle_time))
	end

end

solve_seq();
