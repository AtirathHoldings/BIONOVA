package com.bionova.service;

import com.bionova.config.CacheConfig;
import com.bionova.entity.*;
import com.bionova.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class MasterDataService {

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private PlantRepository plantRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private DesignationRepository designationRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private ExternalEmployeeRepository externalEmployeeRepository;

    @Cacheable(CacheConfig.CACHE_COMPANIES)
    public List<CompanyMaster> getAllCompanies() {
        return companyRepository.findAll();
    }

    @Cacheable(value = CacheConfig.CACHE_COMPANIES, key = "#id")
    public Optional<CompanyMaster> getCompanyById(Long id) {
        return companyRepository.findById(id);
    }

    @CacheEvict(value = CacheConfig.CACHE_COMPANIES, allEntries = true)
    public void evictCompanyCache() {
    }

    @Cacheable(CacheConfig.CACHE_PLANTS)
    public List<PlantMaster> getAllPlants() {
        return plantRepository.findAll();
    }

    @Cacheable(value = CacheConfig.CACHE_PLANTS, key = "#id")
    public Optional<PlantMaster> getPlantById(Long id) {
        return plantRepository.findById(id);
    }

    @CacheEvict(value = CacheConfig.CACHE_PLANTS, allEntries = true)
    public void evictPlantCache() {
    }

    @Cacheable(CacheConfig.CACHE_DEPARTMENTS)
    public List<DepartmentMaster> getAllDepartments() {
        return departmentRepository.findAll();
    }

    @CacheEvict(value = CacheConfig.CACHE_DEPARTMENTS, allEntries = true)
    public void evictDepartmentCache() {
    }

    @Cacheable(CacheConfig.CACHE_DESIGNATIONS)
    public List<DesignationMaster> getAllDesignations() {
        return designationRepository.findAll();
    }

    @CacheEvict(value = CacheConfig.CACHE_DESIGNATIONS, allEntries = true)
    public void evictDesignationCache() {
    }

    @Cacheable(CacheConfig.CACHE_EMPLOYEES)
    public List<Employee> getAllEmployees() {
        return employeeRepository.findAll();
    }

    @CacheEvict(value = {CacheConfig.CACHE_EMPLOYEES, CacheConfig.CACHE_ADMIN_DASHBOARD}, allEntries = true)
    public void evictEmployeeCache() {
    }

    @Cacheable(CacheConfig.CACHE_EXTERNAL_EMPLOYEES)
    public List<ExternalEmployee> getAllExternalEmployees() {
        return externalEmployeeRepository.findAll();
    }

    @CacheEvict(value = CacheConfig.CACHE_EXTERNAL_EMPLOYEES, allEntries = true)
    public void evictExternalEmployeeCache() {
    }
}

