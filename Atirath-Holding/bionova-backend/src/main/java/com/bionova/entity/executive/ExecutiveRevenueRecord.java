package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_revenue_records")
@Getter
@Setter
public class ExecutiveRevenueRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "invoice_code", length = 50)
    private String invoiceCode;

    @Column(name = "stream", nullable = false, length = 150)
    private String stream;

    @Column(name = "offtaker", length = 200)
    private String offtaker;

    @Column(name = "volume", length = 100)
    private String volume;

    @Column(name = "unit_rate", length = 100)
    private String unitRate;

    @Column(name = "amount")
    private Double amount;

    @Column(name = "invoice_date", length = 50)
    private String invoiceDate;

    @Column(name = "due_date", length = 50)
    private String dueDate;

    @Column(name = "payment_status", length = 50)
    private String paymentStatus;

    @Column(name = "utr", length = 100)
    private String utr;

    @Column(name = "plant", length = 150)
    private String plant;
}

