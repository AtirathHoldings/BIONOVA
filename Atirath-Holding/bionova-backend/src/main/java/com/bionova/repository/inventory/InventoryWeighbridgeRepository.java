package com.bionova.repository.inventory;

import com.bionova.entity.inventory.InventoryWeighbridge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryWeighbridgeRepository extends JpaRepository<InventoryWeighbridge, Long> {
}

