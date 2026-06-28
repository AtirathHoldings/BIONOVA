package com.bionova;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
class BionovaBackendApplicationTests {

	@Autowired
	private MockMvc mockMvc;

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Autowired
	private ObjectMapper objectMapper;

	@Test
	void testPrintDbInfo() throws Exception {
		System.out.println("--- LISTING ALL PUBLIC TABLES ---");
		jdbcTemplate.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public'", rs -> {
			System.out.println("Table: " + rs.getString(1));
		});

		System.out.println("--- LISTING ROWS IN dept_company_plt_map ---");
		jdbcTemplate.query("SELECT * FROM dept_company_plt_map", rs -> {
			int cols = rs.getMetaData().getColumnCount();
			for (int i = 1; i <= cols; i++) {
				System.out.print(rs.getMetaData().getColumnName(i) + ": " + rs.getObject(i) + " | ");
			}
			System.out.println();
		});
	}

	@Test
	void testProjectMilestoneTaskFlow() throws Exception {
		// Insert master records if not present
		jdbcTemplate.update("INSERT INTO company_master (coy_id, coy_cd, coy_nm, zn_nm) VALUES (1, 'C1', 'Company 1', 'SOUTH') ON CONFLICT (coy_id) DO NOTHING");
		jdbcTemplate.update("INSERT INTO plant_master (plt_id, plt_cd, plt_nm, zn_nm, coy_id) VALUES (1, 'P1', 'Plant 1', 'SOUTH', 1) ON CONFLICT (plt_id) DO NOTHING");
		jdbcTemplate.update("INSERT INTO department_master (dept_id, dept_code, dept_nm, sts) VALUES (1, 'D1', 'Department 1', true) ON CONFLICT (dept_id) DO NOTHING");

		String rand = String.valueOf((int)(Math.random() * 9000 + 1000));
		
		// 1. Create a ProjectDraft (e.g. 9 days total: July 1 to July 10)
		String projectJson = "{\n" +
				"  \"prjCd\": \"PRJ" + rand + "\",\n" +
				"  \"prjNm\": \"Test Project\",\n" +
				"  \"prjDesc\": \"Description\",\n" +
				"  \"deptId\": 1,\n" +
				"  \"prjPrty\": \"HIGH\",\n" +
				"  \"tentStDt\": \"2026-07-01\",\n" +
				"  \"tentEndDt\": \"2026-07-10\",\n" +
				"  \"coyId\": 1,\n" +
				"  \"pltId\": 1,\n" +
				"  \"prjObjtv\": \"Objective\"\n" +
				"}";

		MvcResult prjResult = mockMvc.perform(post("/api/project-drafts")
				.contentType(MediaType.APPLICATION_JSON)
				.content(projectJson))
				.andReturn();

		String prjRespStr = prjResult.getResponse().getContentAsString();
		JsonNode prjNode = objectMapper.readTree(prjRespStr);
		long drftPrjId = prjNode.get("drftPrjId").asLong();
		System.out.println("CREATED PROJECT WITH ID: " + drftPrjId);

		// 2. Create a MilestoneDraft within the project limit (e.g. 5 days: July 1 to July 6)
		String milestoneJson = "{\n" +
				"  \"drftPrjId\": " + drftPrjId + ",\n" +
				"  \"mlstnCd\": \"MS" + rand + "\",\n" +
				"  \"mlstnTtl\": \"Milestone 1\",\n" +
				"  \"mlstnDays\": 5,\n" +
				"  \"tentStDt\": \"2026-07-01\",\n" +
				"  \"tentEndDt\": \"2026-07-06\"\n" +
				"}";

		MvcResult msResult = mockMvc.perform(post("/api/milestone-drafts")
				.contentType(MediaType.APPLICATION_JSON)
				.content(milestoneJson))
				.andReturn();

		String msRespStr = msResult.getResponse().getContentAsString();
		JsonNode msNode = objectMapper.readTree(msRespStr);
		long drftMId = msNode.get("data").get("drftMId").asLong();
		System.out.println("CREATED MILESTONE WITH ID: " + drftMId);

		// 3. Create a TaskDraft exceeding the milestone limit (e.g. 8 days: July 1 to July 9) -> should warn
		String taskExceedingJson = "{\n" +
				"  \"drftMId\": " + drftMId + ",\n" +
				"  \"taskCd\": \"TSK" + rand + "\",\n" +
				"  \"taskNm\": \"Task 1\",\n" +
				"  \"noOfDays\": 8,\n" +
				"  \"tentStDt\": \"2026-07-01\",\n" +
				"  \"tentEndDt\": \"2026-07-09\"\n" +
				"}";

		MvcResult taskResult = mockMvc.perform(post("/api/task-drafts")
				.contentType(MediaType.APPLICATION_JSON)
				.content(taskExceedingJson))
				.andReturn();

		String taskRespStr = taskResult.getResponse().getContentAsString();
		JsonNode taskNode = objectMapper.readTree(taskRespStr);
		System.out.println("TASK RESPONSE JSON: " + taskRespStr);
		
		assertTrue(taskNode.has("warning"));
		String warning = taskNode.get("warning").asText();
		System.out.println("GOT EXPECTED WARNING: " + warning);
		assertTrue(warning.contains("exceed milestone limits"));
	}
}
