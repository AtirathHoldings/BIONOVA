package com.bionova.repository.assetmaintenance;

import com.bionova.entity.assetmaintenance.MachineryAsset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MachineryAssetRepository extends JpaRepository<MachineryAsset, Long> {
}
