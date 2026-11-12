package com.bionova.repository.inventory;

import com.bionova.entity.inventory.InventoryCivilBom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InventoryCivilBomRepository extends JpaRepository<InventoryCivilBom, Long> {
}
