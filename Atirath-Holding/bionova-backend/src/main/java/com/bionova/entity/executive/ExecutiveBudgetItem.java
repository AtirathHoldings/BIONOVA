package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_budget_items")
@Getter
@Setter
public class ExecutiveBudgetItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cost_center_code", length = 50)
    private String costCenterCode;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "nature", length = 50)
    private String nature;

    @Column(name = "plant", length = 150)
    private String plant;

    @Column(name = "baseline_budget")
    private Double baselineBudget;

    @Column(name = "actual_incurred")
    private Double actualIncurred;

    @Column(name = "committed_po")
    private Double committedPO;

    @Column(name = "lead_dept", length = 150)
    private String leadDept;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}

