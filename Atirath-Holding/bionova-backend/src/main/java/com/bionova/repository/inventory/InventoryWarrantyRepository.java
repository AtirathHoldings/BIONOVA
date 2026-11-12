package com.bionova.repository.inventory;

import com.bionova.entity.inventory.InventoryWarranty;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryWarrantyRepository extends JpaRepository<InventoryWarranty, Long> {
}

