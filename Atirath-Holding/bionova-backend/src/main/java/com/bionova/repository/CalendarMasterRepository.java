package com.bionova.repository;

import com.bionova.entity.CalendarMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CalendarMasterRepository extends JpaRepository<CalendarMaster, Long> {

    List<CalendarMaster> findByCoyId(Integer coyId);

    List<CalendarMaster> findByCoyIdAndPltId(Integer coyId, Integer pltId);

    List<CalendarMaster> findByCalYr(Integer calYr);

    List<CalendarMaster> findByCoyIdAndCalYr(Integer coyId, Integer calYr);
}
