#!/usr/bin/env python
"""
Program to implement operation room planning based on C1-heuristic taught in 
course Industry 4.0 in Industry Operations.

**Note:
Patients and operation rooms should be numbered from 1 to n.
Timings used are in the 24-hr format.
Tiebreakers are resolved by picking the patient with the smaller id.
"""
import numpy as np


class OpRoom:
    def __init__(self, id_: int, open: float, close: float) -> None:
        self.id = id_
        self.open = open
        self.close = close
        self.patients: list[Patient] = []

        # for C1-heuristic
        self.f_scheduled: list[Patient] = []
        self.b_scheduled: list[Patient] = []
        self.next_start = open
        self.next_end = close
        # for C2-heuristic
        self.scheduled: list[Patient] = []


class Patient:
    def __init__(self, id_: int, duration: float, op_room: OpRoom) -> None:
        self.id = id_
        self.duration = duration
        self.op_room = op_room
        self.start_time = 0
        self.complete_time = 0


class OpRoomPlanning:
    """
    Class to implement C1 or C2-heuristic for operation room planning.
    """
    def __init__(self, op_ids: list[int], open_times: list[float],
                 close_times: list[float], p_ids: list[int],
                 p_durations: list[float], p_op_rooms: list[int]) -> None:

        self.patients: list[Patient] = []
        self.scheduled: list[Patient] = []
        self.op_rooms: list[OpRoom] = []
        self.L = None       # lambda

        self.generate_op_rooms(op_ids, open_times, close_times)
        self.generate_patients(p_ids, p_durations, p_op_rooms)

    def generate_op_rooms(self, op_ids, open_times, close_times) -> None:
        """
        Generate a list of OpRoom objects to store in self.op_rooms.
        """
        # Check array sizes
        if len(op_ids) != len(open_times) or len(op_ids) != len(close_times):
            print("Check sizes of op_room arrays are the same.")
            exit()

        op_rooms = []
        for i, id_ in enumerate(op_ids):
            op_room = OpRoom(id_, open_times[i], close_times[i])
            op_rooms.append(op_room)
        self.op_rooms = op_rooms

    def generate_patients(self, p_ids, p_durations, p_op_rooms) -> None:
        """
        Generate a list of Patients objects to store in self.patients.
        """
        # Check array sizes
        if len(p_ids) != len(p_durations) or len(p_ids) != len(p_op_rooms):
            print("Check sizes of patient arrays are the same.")
            exit()

        patients = []
        for i, id_ in enumerate(p_ids):
            p_op_room = p_op_rooms[i]
            p = Patient(id_, p_durations[i], self.op_rooms[p_op_room-1])
            patients.append(p)
            self.op_rooms[p_op_rooms[i]-1].patients.append(p)
        self.patients = patients

    def calculate_lambda(self) -> float:
        """
        Calculates lambda using (E-S)/(1 + sum of M_j-1).
        """
        e = 24
        s = 0
        temp = 0
        for or_ in self.op_rooms:
            if or_.close < e:
                e = or_.close
            if or_.open > s:
                s = or_.open
            temp += len(or_.patients)-1
        self.L = (e-s)/(1+temp)
        print(f"Lambda: {self.L}")

    def latest_complete_time(self) -> float:
        """
        Returns latest possible completion time among all ORs.
        """
        latest_c = 0
        for or_ in self.op_rooms:
            if or_.next_start > latest_c:
                latest_c = or_.next_start
        return latest_c

    def earliest_start_time(self) -> float:
        """
        Returns earliest possible start time among all ORs.
        """
        earliest_s = 24
        for or_ in self.op_rooms:
            if or_.next_end < earliest_s:
                earliest_s = or_.next_end
        return earliest_s

    def forward_schedule(self, latest_c) -> None:
        """
        Forward schedule a patient in its OR for C1-heuristic.
        """
        # Calculate deviations
        f_dels = []
        for p in self.patients:
            possible_complete = p.op_room.next_start + p.duration
            f_del = abs(latest_c + self.L - possible_complete)
            print(
                f"\t patient: {p.id:<3} end: {possible_complete:<7} f_del: {f_del:.5f}")
            f_dels.append(f_del)
        min_f_del = np.argmin(f_dels)

        # Patient to be scheduled
        p = self.patients[min_f_del]
        p.op_room.f_scheduled.append(p)

        # Update timings
        p.start_time = p.op_room.next_start
        p.complete_time = p.start_time + p.duration
        p.op_room.next_start = p.complete_time
        print(f"Forward scheduled patient {p.id}")
        self.patients.pop(min_f_del)

    def backward_schedule(self, earliest_s) -> None:
        """
        Backward schedule a patient in its OR for C1-heuristic.
        """
        # Calculate deviations
        b_dels = []
        for p in self.patients:
            possible_start = p.op_room.next_end - p.duration
            b_del = abs(earliest_s - self.L - possible_start)
            print(
                f"\t patient: {p.id:<3} start: {possible_start:<5} b_del: {b_del:.5f}")
            b_dels.append(b_del)
        min_b_del = np.argmin(b_dels)

        # Patient to be scheduled
        p = self.patients[min_b_del]
        p.op_room.b_scheduled.append(p)

        # Update timings
        p.complete_time = p.op_room.next_end
        p.start_time = p.complete_time - p.duration
        p.op_room.next_end = p.start_time
        print(f"Backward scheduled patient {p.id}")
        self.patients.pop(min_b_del)

    def print_c1_results(self) -> None:
        """
        Print start and end times for each patient in each OR for C1-heuristic.
        """
        print("\n\nFinal Planning Sequence:")
        for or_ in self.op_rooms:
            print(f"OR: {or_.id}\tid [start  end ]")
            for p in or_.f_scheduled:
                print(f"\t {p.id} [{p.start_time:5} {p.complete_time:5}]")
                or_.scheduled.append(p)
            for p in reversed(or_.b_scheduled):
                print(f"\t {p.id} [{p.start_time:5} {p.complete_time:5}]")
                or_.scheduled.append(p)

    def print_c2_results(self) -> None:
        """
        Print start and end times for each patient in each OR for C2-heuristic.
        """
        print("\nPlanning Sequence:")
        for or_ in self.op_rooms:
            print(f"OR: {or_.id}\tid [start  end ]")
            for p in or_.scheduled:
                print(f"\t {p.id} [{p.start_time:5} {p.complete_time:5}]")

    def print_bim_bii(self) -> None:
        """
        Calculate the break-in moments and break-in intervals from the schedule.
        """
        print("\nBreak-in Moments:")
        bim = []
        for or_ in self.op_rooms:
            for p in or_.scheduled:
                bim.append(p.start_time)
                bim.append(p.complete_time)
        bim = sorted(np.unique(bim))    # sort ascending
        print(f"\t{bim}")

        bii = []
        for i in range(len(bim)-1):
            bii.append(bim[i+1] - bim[i])
        bii_avg = sum(bii)/len(bii)
        print(f"\nBreak-in Interval: {bii_avg:.3f}\n")

    def c1_heuristic(self) -> None:
        """
        Main implementation loop for C1-heuristic.
        """
        iteration = 0
        self.calculate_lambda()

        # While there are still unscheduled patients
        while len(self.patients) > 0:
            iteration += 1
            print(f"\n--------Iteration {iteration}--------")
            latest_c = self.latest_complete_time()
            earliest_s = self.earliest_start_time()
            print(f"latest completion time: {latest_c}")
            print(f"earliest start time: {earliest_s}")

            # Try forward and backward scheduling
            self.forward_schedule(latest_c)
            if len(self.patients) > 0:
                self.backward_schedule(earliest_s)

        self.print_c1_results()
        self.print_bim_bii()

    def find_largest_or(self) -> OpRoom:
        """
        Find the Op Room with the most number of patients left unscheduled 
        for C2-heuristic.
        """
        max_n = 0
        max_or = None
        for or_ in self.op_rooms:
            if len(or_.patients) > max_n:
                max_or = or_
                max_n = len(or_.patients)
        return max_or

    def c2_step_1(self) -> None:
        """
        Schedule all patients in the largest OR using the shortest processing 
        time rule (SPT) for C2-heuristic.
        """
        max_or = self.find_largest_or()

        # Schedule all patients using SPT rule
        max_or.scheduled = sorted(max_or.patients, key=lambda p: p.duration)
        max_or.patients = []
        for p in max_or.scheduled:
            p.start_time = p.op_room.next_start
            p.complete_time = p.start_time + p.duration
            p.op_room.next_start = p.complete_time
            self.pop_patient(self.patients, p)
            self.scheduled.append(p)

    def pop_patient(self, list_: list[Patient], patient: Patient) -> None:
        """
        Remove the patient from list_ based on matching IDs.
        """        
        for i, p in enumerate(list_):
            if p.id == patient.id:
                list_.pop(i)
                return
        print(f"Unable to pop patient {patient.id}")
        exit()

    def calculate_invalid_intervals(self):
        """
        Return the intervals of +- lambda/2 from each of the already scheduled
        patients in C2-heuristic.
        """
        intervals = []
        for p in self.scheduled:
            interval = (round(p.complete_time-self.L/2, 2),
                        round(p.complete_time+self.L/2))
            intervals.append(interval)
        return intervals

    def check_valid_end(self, end) -> bool:
        """
        Check if the end time lies within +- lambda/2 range of any of the already
        scheduled patients in C2-heuristic.
        """
        valid = True
        for p in self.scheduled:
            # Check if end lies in the valid interval
            if p.complete_time - self.L/2 < end and \
                    p.complete_time + self.L/2 > end:
                valid = False
                return valid
        return valid

    def calculate_min_abs_diff(self, p: Patient) -> float:
        """
        Return the minimum absolute difference between the end time of 
        unscheduled patient and all the scheduled patients in C2-heuristic. 
        """
        differences = []
        end = p.op_room.next_start + p.duration
        for p_scheduled in self.scheduled:
            diff = abs(p_scheduled.complete_time - end)
            differences.append(diff)
        print(f"\tpatient {p.id} end: {end:<5} d: {differences}")
        min = differences[np.argmin(differences)]
        return min

    def c2_schedule_patient(self, p: Patient) -> None:
        p.op_room.scheduled.append(p)
        self.scheduled.append(p)
        print(f"\tScheduled patient {p.id} in OR {p.op_room.id}")
        self.pop_patient(p.op_room.patients, p)
        self.pop_patient(self.patients, p)
        p.start_time = p.op_room.next_start
        p.complete_time = p.start_time + p.duration
        p.op_room.next_start = p.complete_time

    def c2_iterate(self) -> None:
        max_or = self.find_largest_or()
        sorted_p = sorted(max_or.patients, key=lambda p: p.duration)
        print(f"\tPatients left in OR {max_or.id}: {[p.id for p in sorted_p]}")

        found_valid = False
        for p in sorted_p:
            end = p.op_room.next_start + p.duration

            valid = self.check_valid_end(end)
            if valid:
                self.c2_schedule_patient(p)
                found_valid = True

        if found_valid is False:
            print("Using ABS difference...")
            differences = []
            for p in sorted_p:
                min_abs_diff = self.calculate_min_abs_diff(p)
                differences.append(min_abs_diff)
            print(f"\tdifferences: {differences}")
            max_diff = np.argmax(differences)

            # Schedule patient
            p = sorted_p[max_diff]
            self.c2_schedule_patient(p)

    def c2_heuristic(self) -> None:
        """
        Main implementation loop for C2-heuristic.
        """
        iteration = 0
        self.calculate_lambda()

        self.c2_step_1()

        while len(self.patients) > 0:
            iteration += 1
            print(f"\n--------Iteration {iteration}--------")
            print(f"\tScheduled end times: {[p.complete_time for p in self.scheduled]}")

            intervals = self.calculate_invalid_intervals()
            print(f"\tInvalid intervals: {intervals}")
            self.c2_iterate()
        self.print_c2_results()
        self.print_bim_bii()


def main():
    # ############ Class eg, slide 45 (C1) and 51 (C2) ############ 
    # Input patients' assigned ORs and surgery durations
    n_patients = 6
    p_ids = list(range(1, n_patients+1))
    p_op_rooms = [1,1,1,2,2,2]
    p_durations = [1.5,3.5,1,1.5,2,2.5]

    # Input opening and closing timings for each OR
    n_rooms = 2
    op_ids = list(range(1, n_rooms+1))
    open_times = [8,8]        # 24h format
    close_times = [15,15]    # 24h format

    # ############## Week 11 Exercise 5 ##############
    # # Input patients' assigned ORs and surgery durations
    # n_patients = 9
    # p_ids = list(range(1, n_patients+1))
    # p_op_rooms = [1, 1, 1, 2, 2, 2, 2, 3, 3]
    # p_durations = [3, 1, 3.5, 0.5, 1.5, 2.5, 4.5, 2.5, 1]

    # # Input opening and closing timings for each OR
    # n_rooms = 3
    # op_ids = list(range(1, n_rooms+1))
    # open_times = [6, 8, 10]
    # close_times = [14, 18, 15]

    # ############## Week 11 Exercise 6 ##############
    # Input patients' assigned ORs and surgery durations
    # n_patients = 8
    # p_ids = list(range(1, n_patients+1))
    # p_op_rooms = [1, 1, 1, 1, 2, 2, 2, 2]
    # p_durations = [1, 2.5, 1, 3, 2, 1.5, 3, 1.5]

    # # Input opening and closing timings for each OR
    # n_rooms = 2
    # op_ids = list(range(1, n_rooms+1))
    # open_times = [7, 7]
    # close_times = [15.5, 15.5]


    # Run planning based on selected heuristic
    opr = OpRoomPlanning(op_ids, open_times, close_times,
                         p_ids, p_durations, p_op_rooms)
    # Choose one method
    opr.c1_heuristic()
    # opr.c2_heuristic()


if __name__ == "__main__":
    main()
