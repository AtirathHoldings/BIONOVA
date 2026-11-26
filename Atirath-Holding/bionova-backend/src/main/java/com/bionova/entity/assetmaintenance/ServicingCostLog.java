package com.bionova.entity.assetmaintenance;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "servicing_cost_logs")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class ServicingCostLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "log_number", length = 50)
    private String logNumber;

    @Column(name = "asset_name", length = 150)
    private String assetName;

    @Column(name = "facility", length = 100)
    private String facility;

    @Column(name = "service_date", length = 50)
    private String serviceDate;

    @Column(name = "service_nature", length = 100)
    private String serviceNature;

    @Column(name = "spares_consumed", columnDefinition = "TEXT")
    private String sparesConsumed;

    @Column(name = "spares_cost")
    private Double sparesCost;

    @Column(name = "labor_cost")
    private Double laborCost;

    @Column(name = "external_vendor_fee")
    private Double externalVendorFee;

    @Column(name = "servicing_vendor", length = 150)
    private String servicingVendor;

    @Column(name = "invoice_ref", length = 100)
    private String invoiceRef;

    @Column(name = "warranty_covered")
    private Boolean warrantyCovered;

    @Transient
    @JsonProperty("totalCost")
    public Double getTotalCost() {
        double spares = sparesCost != null ? sparesCost : 0.0;
        double labor = laborCost != null ? laborCost : 0.0;
        double vendor = externalVendorFee != null ? externalVendorFee : 0.0;
        return spares + labor + vendor;
    }
}
