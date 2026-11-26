package com.bionova.repository.inventory;

import com.bionova.entity.inventory.SkuMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SkuMasterRepository extends JpaRepository<SkuMaster, Long> {

    List<SkuMaster> findByIsActiveTrueOrderByCategoryAscOptionTypeAscSortOrderAsc();

    List<SkuMaster> findByCategoryAndIsActiveTrueOrderByOptionTypeAscSortOrderAsc(String category);

    List<SkuMaster> findByCategoryAndOptionTypeAndIsActiveTrueOrderBySortOrderAsc(String category, String optionType);

    Optional<SkuMaster> findByCategoryAndOptionTypeAndCode(String category, String optionType, String code);
}
