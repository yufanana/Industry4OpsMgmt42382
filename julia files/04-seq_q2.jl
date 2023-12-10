using JuMP
using Gurobi

function solve_seq()

    #------
    # MODEL
    #------

	n = 8; # number of jobs
	m = 7; # number of operations

	d = [1050 320 650 540 380 820 150 1080]; # production volumes

	 # operations needed by each job
	O = [
		1	1	0	0	0	1	0;
		0	0	1	1	0	1	1;
		1	0	1	0	0	0	0;
		0	0	0	1	1	0	1;
		0	0	1	0	1	1	1;
		1	0	0	0	1	1	1;
		0	0	0	1	1	0	0;
		0	1	1	0	0	1	0
	]

	X = -O.+1; # operations not needed by each job

	# time in seconds to add/remove operations
	t_add = [900 300 600 900 1000 900 450];
	t_rem = [450 200 450 300 400 450 300];
	t_pass = 3;
	# t_stop = 20*60;		# 20min
	t_stop = 5*60;		# 5min

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:n,1:n] >= 0, Bin);			# 8jobs x 7ops
	@variable(model, y[1:m,1:n] >= 0, Bin);			# 7ops x 8jobs
	@variable(model, z_add[1:m,1:n] >= 0, Bin);		# 7ops x 8jobs
	@variable(model, z_rem[1:m,1:n] >= 0, Bin);		# 7ops x 8jobs
	@variable(model, z_pass[1:m,1:n] >= 0, Bin);	# 7ops x 8jobs
	@variable(model, s[1:n], Bin);					# 8jobs

	# Minimize total excess time
    @objective(model, Min, sum(sum(t_add[o]*z_add[o,i] + t_rem[o]*z_rem[o,i] + t_pass*z_pass[o,i]*d[i] for o = 1:m) + s[i]*t_stop for i = 1:n))

	# Linear assignment for jobs and positions
    @constraint(model, [i=1:n], 		sum(x[j,i] for j=1:n) == 1);
	@constraint(model, [j=1:n], 		sum(x[j,i] for i=1:n) == 1);

	# Configuration contraints
	@constraint(model, [o=1:m,i=1:n], 	sum(x[j,i]*O[j,o] for j=1:n) 				<= y[o,i])
	@constraint(model, [o=1:m,i=2:n], 	y[o,i] == y[o,i-1] + z_add[o,i] - z_rem[o,i]		 )
	@constraint(model, [i=1:n], 		sum(z_add[o,i] + z_rem[o,i] for o=1:m) 		<= s[i]*m)

	# no operations are on line at the start
	@constraint(model, [o=1:m], 		y[o,1] == z_add[o,1])

	# Bypassing constraints
	@constraint(model, [o=1:m,i=1:n], 	sum(x[j,i]*X[j,o] for j=1:n) + y[o,i] 		<= z_pass[o,i] + 1)
    
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
