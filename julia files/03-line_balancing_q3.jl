using JuMP
using Gurobi

function solve_seq()

    #------
    # MODEL
    #------

	n = 20; # number of operations

	t = [11	15	10	15	13	17	13	16	17	16  13	13	17	18	20	17	10	20	11	19]; # time to complete operation

	r = 3; # reconfiguration time

	T = 0.06; # target line throughput
	# T = 36/(10*60);

	m = 12; # number of workstations

	C = 3; # max number of operations per workstation
	
	max_machines = [5 5 5 6 1 1 1 3 4 1 3 5] #
	# C = [5	5	5	6	1	1	1	3	4	1	3	5];


    model = Model(Gurobi.Optimizer);

	# Main decision variables
    @variable(model, x[1:n,1:m] >= 0, Bin);
	@variable(model, y[1:m] >= 0, Int);

	# Aux variables
	@variable(model, l[1:n,1:m] >= 0, Bin);
	@variable(model, o[1:n,1:m] >= 0, Bin);

	# Objective
    @objective(model, Min, sum(y[k] for k = 1:m));

	# Scheduling constraints
	@constraint(model, [i=1:n], sum(x[i,k] for k=1:m) == 1);
	@constraint(model, [k=1:m], sum(x[i,k] for i=1:n) <= C);

	# Desired throughput
	@constraint(model, [k=1:m], sum((t[i]+r)*x[i,k] - r*o[i,k] for i=1:n) <= y[k]/T);

	# Sequence constraints
	@constraint(model, [i=1:n-1,k=1:m], x[i,k] <= x[i+1,k] + l[i,k]);
	@constraint(model, [k=1:m], sum(l[i,k] for i=1:n) == 1);

	# Logical constraints
	@constraint(model, [k=1:m], x[n,k] == l[n,k]);
	@constraint(model, [i=1:n-1,j=i+1:n,k=1:m-1,h=k:m], l[i,h] + l[j,k] <= 1)
	@constraint(model, [i=1,k=1:m], o[i,k] == l[i,k])
	@constraint(model, [i=2:n,k=1:m], 2o[i,k] <= l[i,k] + (1 - x[i-1,k]))

	# New machine constraint
	@constraint(model, [k=1:m], y[k] <= max_machines[k]);

    #-------
    # SOLVE
    #-------

    optimize!(model)

	println();

	EPS = 0.000001; # to deal with rounding errors by the solver

	capacities = [Inf for i=1:m]
	idle = [Inf for i=1:m]
	proc_time = zeros(m)
	n_machines = zeros(m)
	
	for k = 1:m 	# for each work station
		n_machines[k] = round(value(y[k]));
		print("workstation ",k,": machines: ",n_machines[k]," operations: ");
		for i =1:n
			if (value(x[i,k]) < 1 + EPS && value(x[i,k]) > 1 - EPS)
				print(i," ")
			end
		end
		print("capacity: ")

		for i =1:n	# for each operation
			# if x is approx 1, i.e. if op i is assigned to workstation k
			if (value(x[i,k]) < 1 + EPS && value(x[i,k]) > 1 - EPS)
				proc_time[k] += t[i] + r
			end
			# if o is approx 1, i.e. if op i is the only op assigned to workstation k
			if (value(o[i,k]) < 1 + EPS && value(o[i,k]) > 1 - EPS)
				proc_time[k] -= r
			end
		end
		println(n_machines[k]/proc_time[k])
		
		# Save proc_time for each workstation
		if n_machines[k] != 0
			capacities[k] = n_machines[k]/proc_time[k]
		end

		
	end

	TH = minimum(capacities)
	CT = 1/TH # cycle time
	println("\nthroughput = ",TH)
	println("\ncycle time = ",CT)

	println("\nutilizations:")
	for k = 1:m
		idle_time = CT*n_machines[k]-proc_time[k]
		println("\tworkstation ",k,": ",proc_time[k]/(proc_time[k]+idle_time))
	end

end

solve_seq()

#=
workstation 1: machines: 3.0 operations: 1 2 3 capacity: 0.06666666666666667
workstation 2: machines: 0.0 operations: capacity: NaN
workstation 3: machines: 4.0 operations: 4 5 6 capacity: 0.07407407407407407
workstation 4: machines: 4.0 operations: 7 8 9 capacity: 0.07272727272727272
workstation 5: machines: 0.0 operations: capacity: NaN
workstation 6: machines: 0.0 operations: capacity: NaN
workstation 7: machines: 1.0 operations: 10 capacity: 0.0625
workstation 8: machines: 2.0 operations: 11 12 capacity: 0.0625
workstation 9: machines: 4.0 operations: 13 14 15 capacity: 0.0625
workstation 10: machines: 0.0 operations: capacity: -0.0
workstation 11: machines: 2.0 operations: 16 17 capacity: 0.06060606060606061
workstation 12: machines: 4.0 operations: 18 19 20 capacity: 0.06779661016949153

throughput = 0.06060606060606061

cycle time = 16.5

utilizations:
        workstation 1: 0.9090909090909091
        workstation 2: NaN
        workstation 3: 0.8181818181818182
        workstation 4: 0.8333333333333334
        workstation 5: NaN
        workstation 6: NaN
        workstation 7: 0.9696969696969697
        workstation 8: 0.9696969696969697
        workstation 9: 0.9696969696969697
        workstation 10: -Inf
        workstation 11: 1.0
        workstation 12: 0.8939393939393939
=#

