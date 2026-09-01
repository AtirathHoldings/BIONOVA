package com.bionova;

import com.bionova.entity.TaskPriorityMaster;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class TaskPriorityTest {

    @Test
    public void testFourDaysTaskWithLowInitialPriority() {
        LocalDate stDt = LocalDate.of(2026, 7, 1);
        LocalDate endDt = LocalDate.of(2026, 7, 4); // 4 days
        Integer noOfDays = 4;
        TaskPriorityMaster initP = TaskPriorityMaster.LOW;

        // Day 1 (July 1): LOW
        LocalDate d1 = LocalDate.of(2026, 7, 1);
        assertEquals(TaskPriorityMaster.LOW, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, d1, initP));

        // Day 2 (July 2): NORMAL
        LocalDate d2 = LocalDate.of(2026, 7, 2);
        assertEquals(TaskPriorityMaster.NORMAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, d2, initP));

        // Day 3 (July 3): MEDIUM
        LocalDate d3 = LocalDate.of(2026, 7, 3);
        assertEquals(TaskPriorityMaster.MEDIUM, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, d3, initP));

        // Day 4 (July 4): HIGH
        LocalDate d4 = LocalDate.of(2026, 7, 4);
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, d4, initP));

        // Day 5 (July 5 - Overdue 1 day <= step 1.0): CRITICAL
        LocalDate d5 = LocalDate.of(2026, 7, 5);
        assertEquals(TaskPriorityMaster.CRITICAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, d5, initP));

        // Day 6 (July 6 - Overdue 2 days > step 1.0): ATMOST CRITICAL
        LocalDate d6 = LocalDate.of(2026, 7, 6);
        assertEquals(TaskPriorityMaster.ATMOST_CRITICAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, d6, initP));
    }

    @Test
    public void testSixDaysTaskWithNormalInitialPriority() {
        LocalDate stDt = LocalDate.of(2026, 7, 1);
        LocalDate endDt = LocalDate.of(2026, 7, 6); // 6 days
        Integer noOfDays = 6;
        TaskPriorityMaster initP = TaskPriorityMaster.NORMAL; // 3 levels (NORMAL, MEDIUM, HIGH) -> step = 6/3 = 2.0 days

        // Days 1 & 2 (July 1-2): NORMAL
        assertEquals(TaskPriorityMaster.NORMAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 1), initP));
        assertEquals(TaskPriorityMaster.NORMAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 2), initP));

        // Days 3 & 4 (July 3-4): MEDIUM
        assertEquals(TaskPriorityMaster.MEDIUM, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 3), initP));
        assertEquals(TaskPriorityMaster.MEDIUM, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 4), initP));

        // Days 5 & 6 (July 5-6): HIGH
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 5), initP));
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 6), initP));

        // Days 7 & 8 (July 7-8 - Overdue 1 & 2 days <= step 2.0): CRITICAL
        assertEquals(TaskPriorityMaster.CRITICAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 7), initP));
        assertEquals(TaskPriorityMaster.CRITICAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 8), initP));

        // Day 9 (July 9 - Overdue 3 days > step 2.0): ATMOST CRITICAL
        assertEquals(TaskPriorityMaster.ATMOST_CRITICAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 9), initP));
    }

    @Test
    public void testFourDaysTaskWithHighInitialPriority() {
        LocalDate stDt = LocalDate.of(2026, 7, 1);
        LocalDate endDt = LocalDate.of(2026, 7, 4); // 4 days
        Integer noOfDays = 4;
        TaskPriorityMaster initP = TaskPriorityMaster.HIGH;

        // Days 1-4: HIGH
        for (int i = 1; i <= 4; i++) {
            assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, i), initP));
        }

        // Day 5 (Overdue <= 4 days): CRITICAL
        assertEquals(TaskPriorityMaster.CRITICAL, TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, null, LocalDate.of(2026, 7, 5), initP));
    }
}

