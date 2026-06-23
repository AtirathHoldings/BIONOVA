package com.bionova.service;

import com.bionova.dto.ProjectRequest;
import com.bionova.entity.Project;
import com.bionova.repository.ProjectRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

@Service
public class ProjectService {

    private final ProjectRepository repository;

    public ProjectService(ProjectRepository repository) {
        this.repository = repository;
    }

    public Project save(ProjectRequest request){

        Project p = new Project();

        p.setPrjNm(request.getProjectName());
        p.setPrjDesc(request.getProjectDescription());

        p.setPrjPrty(request.getPriority());

        p.setPrjSts("DRAFT");

        p.setStDt(
                LocalDate.parse(
                        request.getTentativeStartDate()
                )
        );

        p.setEndDt(
                LocalDate.parse(
                        request.getTentativeEndDate()
                )
        );

        p.setPrjObjtv(
                request.getProjectObjective()
        );

        p.setExpDlvbls(
                request.getExpectedDeliverables()
        );

        p.setCoyId(request.getCompanyId());
        p.setPltId(request.getPlantId());
        p.setDeptId(request.getDeptId());

        if (p.getStDt() != null && p.getEndDt() != null) {
            long days = java.time.temporal.ChronoUnit.DAYS.between(p.getStDt(), p.getEndDt());
            p.setNoOfDays((int) days);
        }

        return repository.save(p);
    }
}