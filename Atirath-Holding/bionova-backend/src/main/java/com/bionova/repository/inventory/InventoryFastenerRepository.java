package com.bionova.repository.inventory;

import com.bionova.entity.inventory.InventoryFastener;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryFastenerRepository extends JpaRepository<InventoryFastener, Long> {
}

