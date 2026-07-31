package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "project_access")
@Getter
@Setter
public class ProjectAccess {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pac_id")
    private Long pacId;

    @Column(name = "prj_id", nullable = false)
    private Long prjId;

    @Column(name = "emp_id", nullable = false)
    private Long empId;

    @Column(name = "access_type", nullable = false, length = 20)
    private String accessType; // 'VIEWER', 'EDITOR', 'MANAGER', 'ADMIN'

    @Column(name = "sts")
    private Boolean sts = true;

    @Column(name = "granted_at")
    private LocalDateTime grantedAt = LocalDateTime.now();

    @Column(name = "performed_by", length = 100)
    private String performedBy;

    @Column(name = "remarks", length = 255)
    private String remarks;
}
