package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorAppointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorAppointmentRepository extends JpaRepository<VisitorAppointment, Long> {
}

