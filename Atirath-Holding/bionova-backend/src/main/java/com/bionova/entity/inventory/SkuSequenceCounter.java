package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "sku_sequence_counter")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class SkuSequenceCounter {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Category Prefix: AGR, PCB, FST, PIP, INS
     */
    @Column(name = "category_prefix", nullable = false, unique = true, length = 20)
    private String categoryPrefix;

    /**
     * Current sequential number
     */
    @Column(name = "current_sequence", nullable = false)
    @Builder.Default
    private Long currentSequence = 0L;

    /**
     * Last allocated full SKU code
     */
    @Column(name = "last_assigned_sku", length = 100)
    private String lastAssignedSku;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
