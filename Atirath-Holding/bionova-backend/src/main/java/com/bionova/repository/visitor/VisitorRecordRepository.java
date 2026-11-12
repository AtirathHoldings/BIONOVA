package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface VisitorRecordRepository extends JpaRepository<VisitorRecord, Long> {
    Optional<VisitorRecord> findByPassNo(String passNo);
}

