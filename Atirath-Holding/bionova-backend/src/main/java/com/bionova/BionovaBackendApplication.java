package com.bionova;

import com.bionova.entity.TaskPriorityMaster;
import com.bionova.repository.TaskPriorityMasterRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.List;

@SpringBootApplication
@EnableScheduling
public class BionovaBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BionovaBackendApplication.class, args);
	}

	@Bean
	public CommandLineRunner initTaskPriorities(TaskPriorityMasterRepository priorityRepository, org.springframework.jdbc.core.JdbcTemplate jdbcTemplate) {
		return args -> {
			List<TaskPriorityMaster> defaultPriorities = List.of(
				TaskPriorityMaster.LOW,
				TaskPriorityMaster.NORMAL,
				TaskPriorityMaster.MEDIUM,
				TaskPriorityMaster.HIGH,
				TaskPriorityMaster.CRITICAL,
				TaskPriorityMaster.ATMOST_CRITICAL
			);
			for (TaskPriorityMaster p : defaultPriorities) {
				if (!priorityRepository.existsById(p.getPriorityId())) {
					priorityRepository.save(p);
				}
			}

			try {
				java.nio.file.Path path = java.nio.file.Paths.get("sql_check.sql");
				if (java.nio.file.Files.exists(path)) {
					String sql = java.nio.file.Files.readString(path);
					jdbcTemplate.execute(sql);
					System.out.println("Successfully initialized get_user_dashboard stored procedure in database.");
				}
			} catch (Exception e) {
				System.err.println("Stored procedure auto-init warning: " + e.getMessage());
			}
		};
	}

}
