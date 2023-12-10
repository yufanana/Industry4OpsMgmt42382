using JuMP
using Gurobi

function solve_seq()

    #------
    # MODEL
    #------

	n = 8; # number of jobs
	m = 7; # number of operations

	d = [640 680 740 600 520 700 570 950]; # production volumes

	O = [ # operations needed by each job
		0	0	1	1	1	0	0;
		1	0	0	0	0	0	1;
		1	0	1	1	0	1	0;
		1	0	0	1	0	0	0;
		1	1	0	0	0	0	0;
		1	0	0	0	0	1	0;
		0	0	0	1	0	0	0;
		0	0	1	1	1	0	1
	]

	X = -O.+1; # operations not needed by each job

	t_add = [600 600 600 600 600 600 600];
	t_rem = [300 300 300 300 300 300 300];
	t_pass = 0.7;
	t_stop = 180;

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:n,1:n] >= 0, Bin);
	@variable(model, y[1:m,1:n] >= 0, Bin);
	@variable(model, z_add[1:m,1:n] >= 0, Bin);
	@variable(model, z_rem[1:m,1:n] >= 0, Bin);
	@variable(model, z_pass[1:m,1:n] >= 0, Bin);
	@variable(model, s[1:n], Bin);

    @objective(model, Min, sum(sum(t_add[o]*z_add[o,i] + t_rem[o]*z_rem[o,i] + t_pass*z_pass[o,i]*d[i] for o = 1:m) + s[i]*t_stop for i = 1:n))

    @constraint(model, [i=1:n], sum(x[j,i] for j=1:n) == 1);
	@constraint(model, [j=1:n], sum(x[j,i] for i=1:n) == 1);

	@constraint(model, [o=1:m,i=1:n], sum(x[j,i]*O[j,o] for j=1:n) <= y[o,i])

	@constraint(model, [o=1:m], y[o,1] == z_add[o,1]) # no operations are on line at the start
	@constraint(model, [o=1:m,i=2:n], y[o,i] == y[o,i-1] + z_add[o,i] - z_rem[o,i])

	@constraint(model, [o=1:m,i=1:n], sum(x[j,i]*X[j,o] for j=1:n) + y[o,i] <= z_pass[o,i] + 1)

	@constraint(model, [i=1:n], sum(z_add[o,i] + z_rem[o,i] for o=1:m) <= s[i]*m)

    #-------
    # SOLVE
    #-------

    optimize!(model)

	println();

	for i = 1:n
		job = 0;
		for j = 1:n
			if (value(x[j,i]) == 1)
				job = j;
				print("job ",j,"\t");
			end
		end
		print("config:\t\t");
		for o = 1:m
			if (value(y[o,i]) == 1)
				if (O[job,o] == 1)
					print(o," \t")
				else
					print(o,"_\t")
				end
			end
		end
		println();
	end

end

solve_seq();
