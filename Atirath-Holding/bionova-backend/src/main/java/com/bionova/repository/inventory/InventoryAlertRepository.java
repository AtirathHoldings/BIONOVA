package com.bionova.repository.inventory;

import com.bionova.entity.inventory.InventoryAlert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryAlertRepository extends JpaRepository<InventoryAlert, Long> {
}

