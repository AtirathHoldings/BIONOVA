package com.bionova;

import com.bionova.entity.Assignment;
import com.bionova.entity.TaskPriorityMaster;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class AssignmentPriorityTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    public void testTaskPriorityMasterFromValue() {
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.fromValue("HIGH"));
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.fromValue("High"));
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.fromValue(4));
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.fromValue("4"));
        assertEquals(TaskPriorityMaster.MEDIUM, TaskPriorityMaster.fromValue("MEDIUM"));
        assertEquals(TaskPriorityMaster.NORMAL, TaskPriorityMaster.fromValue("NORMAL"));
        assertEquals(TaskPriorityMaster.LOW, TaskPriorityMaster.fromValue("LOW"));
        assertEquals(TaskPriorityMaster.HIGH, TaskPriorityMaster.fromValue(Map.of("priorityId", 4, "priorityNm", "HIGH")));
    }

    @Test
    public void testAssignmentPriorityDirectSetAndGet() {
        Assignment assignment = new Assignment();
        assignment.setPriority(TaskPriorityMaster.HIGH);
        assertEquals(TaskPriorityMaster.HIGH, assignment.getPriority());

        assignment.setPriority(TaskPriorityMaster.MEDIUM);
        assertEquals(TaskPriorityMaster.MEDIUM, assignment.getPriority());

        assignment.setPriority(TaskPriorityMaster.NORMAL);
        assertEquals(TaskPriorityMaster.NORMAL, assignment.getPriority());

        assignment.setPriority(TaskPriorityMaster.LOW);
        assertEquals(TaskPriorityMaster.LOW, assignment.getPriority());
    }

    @Test
    public void testAssignmentJsonDeserialization() throws Exception {
        String json = "{\"taskCd\":\"INDTSK-001\",\"taskNm\":\"Test Task\",\"priority\":\"HIGH\"}";
        Assignment assignment = objectMapper.readValue(json, Assignment.class);
        assertNotNull(assignment.getPriority());
        assertEquals(TaskPriorityMaster.HIGH, assignment.getPriority());

        String jsonObj = "{\"taskCd\":\"INDTSK-002\",\"taskNm\":\"Test 2\",\"priority\":{\"priorityId\":3,\"priorityNm\":\"MEDIUM\"}}";
        Assignment assignmentObj = objectMapper.readValue(jsonObj, Assignment.class);
        assertNotNull(assignmentObj.getPriority());
        assertEquals(TaskPriorityMaster.MEDIUM, assignmentObj.getPriority());
    }
}
