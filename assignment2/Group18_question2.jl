using JuMP
using Gurobi
import XLSX

function solve_nurse_rostering()
    model = Model(Gurobi.Optimizer);

    # Load excel sheet
    foldername = "C:/Users/yufan/OneDrive - Danmarks Tekniske Universitet/Courses/- 42382 Industry 4.0/assignment2/";
    filename = "ShiftAssignment-Fall-2023.xlsx";
    xf = XLSX.readxlsx(foldername*filename);
    sheet= xf["Tabelle1"];
    V = sheet["C4:P33"];        # vacation array
    D = sheet["C35:P37"];       # demand array
    
    # Parameters
    w = [0.286 0.143 0.571];     # relative weights for objective function
    n = 30;          # number of nurses
    m = 14;          # number of days in planning horizon
    l = 3;           # number of shifts per day
    d_bar = 5;       # max work stretch
    t_bar = 7;       # target number of shifts
    n_bar = 1;      # target number of night shifts

    # Check loaded values
    # println("Vacation array")
    # for i = 1:n
    #     for d = 1:m
    #         print(value(V[i,d]));
    #     end
    #     println();
    # end

    # println("Demand array")
    # for j = 1:l
    #     for d = 1:m
    #         print(value(D[j,d]), " ");
    #     end
    #     println();
    # end

    # Decision Variables
    @variable(model, x[1:n, 1:l, 1:m] >= 0, Bin);
    @variable(model, y[1:n, 1:m] >= 0, Bin);

    # Auxiliary Variables
    @variable(model, P[1:n] >= 0, Int);
    @variable(model, M[1:n] >= 0, Int);
    @variable(model, N[1:n] >= 0, Int);

    # Objective function
    @objective(model, Min, sum(w[1]*P[i] + w[2]*M[i] + w[3]*N[i] for i=1:n));

    # Constraints for Aux Variables
    # ---------------------------------
    # Total shifts assigned deviates from target shifts
    @constraint(model, [i=1:n], sum(x[i,j,d] for j=1:l, d=1:m) <= t_bar+P[i]-M[i]);
    # Assigned more than target night shift
    @constraint(model, [i=1:n], sum(x[i,3,d] for d=1:m) <= n_bar+N[i]);

    # Constraints for rostering
    # ------------------------------
    # At most one shift per day
    @constraint(model, [i=1:n, d=1:m], sum(x[i,j,d] for j=1:l) == 1 - y[i,d]);
    # At most 5 consecutive work days
    @constraint(model, [i=1:n, d=1:m-d_bar], sum(1-y[i,tau] for tau=d:d+d_bar) <= d_bar);
    # Day off given after a night shift
    @constraint(model, [i=1:n, d=1:m-1], x[i,3,d] <= y[i,d+1]);
    # Only assigned when not on vacation
    @constraint(model, [i=1:n, d=1:m], sum(x[i,j,d] for j=1:l) <= V[i,d]);
    # Total nurses assigned meets demand of shift
    @constraint(model, [j=1:l, d=1:m], sum(x[i,j,d] for i=1:n) >= D[j,d]);

    #-------
    # Solve
    #-------
    optimize!(model);

    #----------------
    # Process results
    #----------------
	println();
	EPS = 0.000001; # to deal with rounding errors by the solver
    for i = 1:n
        # Print working days for each nurse
        println("nurse: ", i);
        print("    days: ");
        for d = 1:m
            for j = 1:l
                # if x[i,j,d] == 1
                if (value(x[i,j,d])) < 1+EPS && (value(x[i,j,d])) > 1-EPS
                    print(d, ".", j, " ");
                end
            end
        end

        println();
        
        # Print total number of workdays in planning period
        print("    total work days: ");
        work_days = 0;
        for d = 1:m
            for j = 1:l
                # if x[i,j,d] == 1
                if (value(x[i,j,d])) < 1+EPS && (value(x[i,j,d])) > 1-EPS
                    work_days += 1;
                end
            end
        end
        println(work_days);
    end
    
    #---------------------
    # Write to excel file
    #---------------------
    XLSX.openxlsx(foldername*filename, mode="rw") do xf
        sheet = xf["Tabelle1"];
        for i = 1:n
            for d = 1:m
                # morning shift
                if (value(x[i,1,d])) == 1
                    sheet[45+i,2+d] = 1;
                # day shift
                elseif (value(x[i,2,d])) == 1
                    sheet[45+i,2+d] = 1;
                # night shift
                elseif (value(x[i,3,d])) == 1
                    sheet[45+i,2+d] = 1;
                # no shift
                else
                    sheet[45+i,2+d] = 0;
                end
            end
        end
    end

            

end

solve_nurse_rostering();
