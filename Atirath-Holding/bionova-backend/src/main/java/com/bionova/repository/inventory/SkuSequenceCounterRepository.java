package com.bionova.repository.inventory;

import com.bionova.entity.inventory.SkuSequenceCounter;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SkuSequenceCounterRepository extends JpaRepository<SkuSequenceCounter, Long> {

    Optional<SkuSequenceCounter> findByCategoryPrefix(String categoryPrefix);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM SkuSequenceCounter s WHERE s.categoryPrefix = :categoryPrefix")
    Optional<SkuSequenceCounter> findByPrefixWithLock(@Param("categoryPrefix") String categoryPrefix);
}
