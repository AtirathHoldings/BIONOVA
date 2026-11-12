package com.bionova.repository.inventory;

import com.bionova.entity.inventory.InventoryVendor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryVendorRepository extends JpaRepository<InventoryVendor, Long> {
}

