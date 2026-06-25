package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "reviewer_master")
@Getter
@Setter
public class ReviewerMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "r_id")
    private Integer rId;

    /** Reviewer display name (can be an employee name or external reviewer) */
    @Column(name = "r_nm", nullable = false, length = 100)
    private String rNm;
}
