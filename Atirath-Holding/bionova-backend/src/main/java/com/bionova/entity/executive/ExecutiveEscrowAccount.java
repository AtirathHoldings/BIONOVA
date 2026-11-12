package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_escrow_accounts")
@Getter
@Setter
public class ExecutiveEscrowAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "escrow_code", length = 50)
    private String escrowCode;

    @Column(name = "account_no", length = 100)
    private String accountNo;

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "custodian", length = 200)
    private String custodian;

    @Column(name = "plant", length = 150)
    private String plant;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "inflow")
    private Double inflow;

    @Column(name = "outflow")
    private Double outflow;

    @Column(name = "balance")
    private Double balance;

    @Column(name = "dsra_requirement")
    private Double dsraRequirement;

    @Column(name = "covenant_status", length = 50)
    private String covenantStatus;

    @Column(name = "last_audit_date", length = 50)
    private String lastAuditDate;

    @Column(name = "signatory", length = 200)
    private String signatory;
}

