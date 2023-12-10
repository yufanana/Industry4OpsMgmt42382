import numpy as np

n = 10 # number of jobs
m = 11 # number of operations

# operation times rows-jobs, cols-operations
O = [	[1,	0,	0,	0,	1,	1,	1,	0,	0,	0,	0],
        [0,	1,	0,	0,	1,	0,	0,	0,	1,	1,	1],
        [1,	1,	0,	0,	0,	1,	1,	0,	0,	1,	0],
        [0,	0,	0,	1,	0,	1,	1,	0,	0,	1,	1],
        [0,	0,	1,	1,	1,	0,	0,	0,	0,	1,	0],
        [0,	0,	1,	0,	1,	0,	0,	1,	0,	0,	1],
        [0,	0,	0,	1,	1,	0,	0,	1,	0,	1,	0],
        [0,	0,	0,	1,	1,	1,	0,	0,	1,	1,	1],
        [0,	1,	1,	0,	0,	1,	1,	0,	0,	0,	0],
        [0,	0,	1,	1,	0,	0,	1,	0,	0,	0,	1]
	]
O = np.array(O)

# production volumes
d = [690, 480, 690, 500, 640, 650, 800, 730, 370, 250]

# Using set up 1
T_b = 1     # bypass time

print("T_excess for FMS")
T_excess = 0
for job in range(n):
    job_time = 0
    # excess = reconfig + bypass
    for op in range(m):
        if O[job,op] == 0:
            job_time += T_b
    print(f"T_excess for job {job+1}: {d[job]*job_time}")
    T_excess += d[job]*job_time
print(f"Total T_excess: {T_excess}")
