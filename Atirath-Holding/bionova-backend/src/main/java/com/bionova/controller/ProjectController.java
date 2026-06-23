package com.bionova.controller;

import com.bionova.dto.ProjectRequest;
import com.bionova.entity.Project;
import com.bionova.service.ProjectService;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/projects")
public class ProjectController {

    private final ProjectService service;

    public ProjectController(ProjectService service) {
        this.service = service;
    }

    @PostMapping
    public Project createProject(
            @RequestBody ProjectRequest request){

        return service.save(request);
    }
}