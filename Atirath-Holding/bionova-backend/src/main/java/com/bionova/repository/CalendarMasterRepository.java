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

    List<CalendarMaster> findByCoyId(Integer coyId);
    List<CalendarMaster> findByCoyIdAndPltId(Integer coyId, Integer pltId);
    List<CalendarMaster> findByCalYr(Integer calYr);
    List<CalendarMaster> findByCoyIdAndCalYr(Integer coyId, Integer calYr);
    List<CalendarMaster> findByPltIdAndCalYr(Integer pltId, Integer calYr);
    List<CalendarMaster> findByHolTypAndCalYr(String holTyp, Integer calYr);

    // ── By calType ─────────────────────────────────────────────────────────
    List<CalendarMaster> findByCalType(String calType);
    List<CalendarMaster> findByCalTypeAndCoyId(String calType, Integer coyId);
    List<CalendarMaster> findByCalTypeAndPltId(String calType, Integer pltId);

    /**
     * Public/National holidays (MANDATORY, no coy/plt scope) — applies to everyone.
     */
    @Query("SELECT c FROM CalendarMaster c WHERE c.holTyp = 'MANDATORY' " +
           "AND c.calDt BETWEEN :startDate AND :endDate AND c.sts = true")
    List<CalendarMaster> findMandatoryHolidaysBetween(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * Company-specific holidays within a date range (COMPANY scope).
     */
    @Query("SELECT c FROM CalendarMaster c WHERE c.coyId = :coyId " +
           "AND (c.calType = 'COMPANY' OR c.calType IS NULL) " +
           "AND c.calDt BETWEEN :startDate AND :endDate AND c.sts = true")
    List<CalendarMaster> findCompanyHolidaysBetween(
            @Param("coyId") Integer coyId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * Plant-specific holidays within a date range (PLANT scope).
     */
    @Query("SELECT c FROM CalendarMaster c WHERE c.pltId = :pltId " +
           "AND c.calType = 'PLANT' " +
           "AND c.calDt BETWEEN :startDate AND :endDate AND c.sts = true")
    List<CalendarMaster> findPlantHolidaysBetween(
            @Param("pltId") Integer pltId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * External calendar holidays (EXTERNAL scope) — used when task is assigned externally.
     * Falls back to company calendar if no external calendar exists.
     */
    @Query("SELECT c FROM CalendarMaster c WHERE c.calType = 'EXTERNAL' " +
           "AND c.coyId = :coyId " +
           "AND c.calDt BETWEEN :startDate AND :endDate AND c.sts = true")
    List<CalendarMaster> findExternalHolidaysBetween(
            @Param("coyId") Integer coyId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    /**
     * All applicable holidays — MANDATORY + company + plant (within date range).
     * Used during promotion when all 3 flags are enabled.
     */
    @Query("SELECT c FROM CalendarMaster c WHERE " +
           "(c.holTyp = 'MANDATORY' OR c.coyId = :coyId OR c.pltId = :pltId) " +
           "AND c.calDt BETWEEN :startDate AND :endDate AND c.sts = true")
    List<CalendarMaster> findAllApplicableHolidaysBetween(
            @Param("coyId") Integer coyId,
            @Param("pltId") Integer pltId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
