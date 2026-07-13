package com.bionova.repository;

import com.bionova.entity.CalendarMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CalendarMasterRepository extends JpaRepository<CalendarMaster, Long> {

    List<CalendarMaster> findByCalDt(LocalDate calDt);
    List<CalendarMaster> findByCalDtBetween(LocalDate startDate, LocalDate endDate);
}
