package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_funding_sources")
@Getter
@Setter
public class ExecutiveFundingSource {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "facility_code", length = 50)
    private String facilityCode;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "type", length = 100)
    private String type;

    @Column(name = "institution", length = 200)
    private String institution;

    @Column(name = "sanctioned")
    private Double sanctioned;

    @Column(name = "received")
    private Double received;

    @Column(name = "outstanding")
    private Double outstanding;

    @Column(name = "interest_rate", length = 50)
    private String interestRate;

    @Column(name = "tenor", length = 50)
    private String tenor;

    @Column(name = "target", length = 255)
    private String target;

    @Column(name = "status", length = 50)
    private String status;
}

