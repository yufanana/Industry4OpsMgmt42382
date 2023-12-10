using JuMP
using Gurobi

function solve_seq()

    #------
    # MODEL
    #------

	n = 10; # number of jobs
	m = 11; # number of operations

	d = [690 480 690 500 640 650 800 730 370 250]; # production volumes

	 # operations needed by each job
	O = [
		1	0	0	0	1	1	1	0	0	0	0;
        0	1	0	0	1	0	0	0	1	1	1;
        1	1	0	0	0	1	1	0	0	1	0;
        0	0	0	1	0	1	1	0	0	1	1;
        0	0	1	1	1	0	0	0	0	1	0;
        0	0	1	0	1	0	0	1	0	0	1;
        0	0	0	1	1	0	0	1	0	1	0;
        0	0	0	1	1	1	0	0	1	1	1;
        0	1	1	0	0	1	1	0	0	0	0;
        0	0	1	1	0	0	1	0	0	0	1
	]

	X = -O.+1; # operations not needed by each job

	# time in seconds to add/remove operations
	t_add = [300 200 180 230 250 450 420 600 180 540 300];
	t_rem = [180 100 130 110 90	210	230	320	110	260	200];

    # setup 1
	# t_pass = 1;
	# t_stop = 30*60;

    # # setup 2
	# t_pass = 1.5;
	# t_stop = 20*60;

    # setup 3
	# t_pass = 1.5;
	# t_stop = 15*60;
	
    # # setup 4
	t_pass = 1.75;
	t_stop = 11*60;

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:n,1:n] >= 0, Bin);		
	@variable(model, y[1:m,1:n] >= 0, Bin);		
	@variable(model, z_add[1:m,1:n] >= 0, Bin);	
	@variable(model, z_rem[1:m,1:n] >= 0, Bin);		
	@variable(model, z_pass[1:m,1:n] >= 0, Bin);
	@variable(model, s[1:n], Bin);		

	# Minimize total excess time
    @objective(model, Min, sum(sum(t_add[o]*z_add[o,i] + t_rem[o]*z_rem[o,i] + t_pass*z_pass[o,i]*d[i] for o = 1:m) + s[i]*t_stop for i = 1:n))

	# Linear assignment for jobs and positions
    @constraint(model, [i=1:n], sum(x[j,i] for j=1:n) == 1);
	@constraint(model, [j=1:n], sum(x[j,i] for i=1:n) == 1);

	# Configuration contraints
	@constraint(model, [o=1:m,i=1:n], 	sum(x[j,i]*O[j,o] for j=1:n) <= y[o,i])
	@constraint(model, [o=1:m,i=2:n], 	y[o,i] == y[o,i-1] + z_add[o,i] - z_rem[o,i])
	@constraint(model, [i=1:n], 		sum(z_add[o,i] + z_rem[o,i] for o=1:m) <= s[i]*m)

	# No operations are on line at the start
	@constraint(model, [o=1:m], 		y[o,1] == z_add[o,1])

	# Bypassing constraint
	@constraint(model, [o=1:m,i=1:n], 	sum(x[j,i]*X[j,o] for j=1:n) + y[o,i] <= z_pass[o,i] + 1)
    
	# Dependency constraint
	# predecessor: 1, successor: 3 
	@constraint(model, [i=1:n], sum(x[1,j] for j=1:i) >= sum(x[3,j] for j=1:i))
	# predecessor: 3, successor: 8
	@constraint(model, [i=1:n], sum(x[3,j] for j=1:i) >= sum(x[8,j] for j=1:i))
	# predecessor: 7, successor: 3
	@constraint(model, [i=1:n], sum(x[7,j] for j=1:i) >= sum(x[3,j] for j=1:i))

	#-------
    # SOLVE
    #-------

    optimize!(model)

	println();

	total_bypass = 0
	for i = 1:n		# for each position i
		job = 0;
		for j = 1:n		# for each job j
			if (value(x[j,i]) == 1)
				job = j;
				print("job ",j,"\t");
			end
		end
		print("config:\t\t");

		for o = 1:m		# for each operation o
			if (value(y[o,i]) == 1)
				if (O[job,o] == 1)
					print(o," \t")
				else
					total_bypass += t_pass*d[job]
					print(o,"_\t")
				end
			end
		end
		println();
	end

	print("Total bypass time: ", total_bypass)
	print("\n")

	total_reconf = 0
	for i = 1:n		# for each position
		total_reconf += t_stop*value(s[i])
		for o = 1:m		# for each operation
			total_reconf += value(t_add[o]*z_add[o,i]) + value(t_rem[o]*z_rem[o,i])
		end
	end
	print("Total reconf time: ", total_reconf)
	
end

solve_seq();
