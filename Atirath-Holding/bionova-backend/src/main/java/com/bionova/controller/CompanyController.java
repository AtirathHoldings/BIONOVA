package com.bionova.controller;

import com.bionova.entity.CompanyMaster;
import com.bionova.entity.StateMaster;
import com.bionova.repository.CompanyRepository;
import com.bionova.repository.StateRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class CompanyController {

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private StateRepository stateRepository;



    @GetMapping("/companies")
    public List<CompanyMaster> getCompanies() {
        return companyRepository.findAll();
    }

    @GetMapping("/companies/{id}")
    public ResponseEntity<?> getCompanyById(@PathVariable Long id) {
        return companyRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/companies")
    public ResponseEntity<?> saveCompany(@RequestBody CompanyMaster company) {
        if (company.getCoyCd() != null && companyRepository.existsByCoyCd(company.getCoyCd())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Company code already exists."));
        }
        if (company.getPanNum() != null && companyRepository.existsByPanNum(company.getPanNum())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "PAN number already exists."));
        }
        if (company.getTanNum() != null && companyRepository.existsByTanNum(company.getTanNum())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "TAN number already exists."));
        }
        if (company.getGstNum() != null && !company.getGstNum().trim().isEmpty() && companyRepository.existsByGstNum(company.getGstNum())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "GST number already exists."));
        }
        if (company.getCin() != null && companyRepository.existsByCin(company.getCin())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "CIN already exists."));
        }

        if (company.getStId() != null) {
            stateRepository.findById(company.getStId()).ifPresent(state -> {
                company.setZnNm(state.getZnNm());
            });
        }

        if (company.getZnNm() == null || company.getZnNm().trim().isEmpty()) {
            company.setZnNm("SOUTH");
        }

        CompanyMaster saved = companyRepository.save(company);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/companies/{id}")
    public ResponseEntity<?> updateCompany(@PathVariable Long id, @RequestBody CompanyMaster details) {
        CompanyMaster company = companyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Company not found"));

        if (details.getCoyCd() != null && companyRepository.existsByCoyCdAndCoyIdNot(details.getCoyCd(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Company code already exists."));
        }
        if (details.getPanNum() != null && companyRepository.existsByPanNumAndCoyIdNot(details.getPanNum(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "PAN number already exists."));
        }
        if (details.getTanNum() != null && companyRepository.existsByTanNumAndCoyIdNot(details.getTanNum(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "TAN number already exists."));
        }
        if (details.getGstNum() != null && !details.getGstNum().trim().isEmpty() && companyRepository.existsByGstNumAndCoyIdNot(details.getGstNum(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "GST number already exists."));
        }
        if (details.getCin() != null && companyRepository.existsByCinAndCoyIdNot(details.getCin(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "CIN already exists."));
        }

        company.setCoyCd(details.getCoyCd());
        company.setCoyNm(details.getCoyNm());
        company.setPrntCoyId(details.getPrntCoyId());
        company.setEmail(details.getEmail());
        company.setGstNum(details.getGstNum());
        company.setTanNum(details.getTanNum());
        company.setPanNum(details.getPanNum());
        company.setIncDt(details.getIncDt());
        company.setCin(details.getCin());
        company.setWebUrl(details.getWebUrl());
        company.setLogo(details.getLogo());
        company.setStr(details.getStr());
        company.setCtVlg(details.getCtVlg());
        company.setDist(details.getDist());
        company.setStId(details.getStId());

        if (details.getStId() != null) {
            stateRepository.findById(details.getStId()).ifPresent(state -> {
                company.setZnNm(state.getZnNm());
            });
        } else {
            company.setZnNm(details.getZnNm());
        }

        if (company.getZnNm() == null || company.getZnNm().trim().isEmpty()) {
            company.setZnNm("SOUTH");
        }

        company.setPin(details.getPin());
        company.setWrkDaysPerWk(details.getWrkDaysPerWk());
        company.setAddlRem(details.getAddlRem());
        company.setSts(details.getSts());
        CompanyMaster saved = companyRepository.save(company);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/companies/{id}")
    public ResponseEntity<?> deleteCompany(@PathVariable Long id) {
        companyRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/states")
    public List<StateMaster> getStates() {
        return stateRepository.findAll();
    }
}