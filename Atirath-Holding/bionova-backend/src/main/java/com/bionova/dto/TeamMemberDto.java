package com.bionova.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * DTO for creating / updating a team member assignment.
 * Used as request body for POST /api/team-members and PUT /api/team-members/{tmId}.
 */
@Getter
@Setter
public class TeamMemberDto {
    private Long taskId;
    private Long empId;
    private String asgnRmk;
}
