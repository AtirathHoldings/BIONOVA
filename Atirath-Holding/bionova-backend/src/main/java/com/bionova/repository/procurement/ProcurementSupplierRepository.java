package com.bionova.repository.procurement;

import com.bionova.entity.procurement.ProcurementSupplier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProcurementSupplierRepository extends JpaRepository<ProcurementSupplier, Long> {
}
