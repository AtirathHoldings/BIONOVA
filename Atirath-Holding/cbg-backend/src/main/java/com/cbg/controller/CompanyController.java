package com.cbg.controller;

import com.cbg.entity.CompanyMaster;
import com.cbg.entity.StateMaster;
import com.cbg.repository.CompanyRepository;
import com.cbg.repository.StateRepository;
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

    @PostMapping("/companies")
    public ResponseEntity<CompanyMaster> saveCompany(@RequestBody CompanyMaster company) {
        CompanyMaster saved = companyRepository.save(company);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/companies/{id}")
    public ResponseEntity<CompanyMaster> updateCompany(@PathVariable Long id, @RequestBody CompanyMaster details) {
        CompanyMaster company = companyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Company not found"));
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
        company.setZnNm(details.getZnNm());
        company.setPin(details.getPin());
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