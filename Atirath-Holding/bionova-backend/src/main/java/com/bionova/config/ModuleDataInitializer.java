package com.bionova.config;

import com.bionova.repository.inventory.*;
import com.bionova.repository.visitor.*;
import com.bionova.repository.executive.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class ModuleDataInitializer implements CommandLineRunner {

    @Autowired private InventoryItemRepository inventoryItemRepo;
    @Autowired private InventoryCivilBomRepository civilBomRepo;
    @Autowired private InventoryFastenerRepository fastenerRepo;
    @Autowired private InventoryPipingRepository pipingRepo;
    @Autowired private InventoryWarrantyRepository warrantyRepo;
    @Autowired private InventoryAlertRepository inventoryAlertRepo;
    @Autowired private InventoryWeighbridgeRepository weighbridgeRepo;
    @Autowired private InventoryVendorRepository vendorRepo;

    @Autowired private VisitorRecordRepository visitorRecordRepo;
    @Autowired private VisitorRequestRepository visitorRequestRepo;
    @Autowired private VisitorAppointmentRepository visitorAppointmentRepo;
    @Autowired private VisitorVehicleRepository visitorVehicleRepo;
    @Autowired private VisitorMaterialInwardRepository materialInwardRepo;
    @Autowired private VisitorMaterialOutwardRepository materialOutwardRepo;
    @Autowired private VisitorSafetyClearanceRepository safetyClearanceRepo;
    @Autowired private VisitorConfigRepository visitorConfigRepo;

    @Autowired private ExecutiveProjectPipelineRepository pipelineRepo;
    @Autowired private ExecutiveBudgetItemRepository budgetRepo;
    @Autowired private ExecutiveRevenueRecordRepository revenueRepo;
    @Autowired private ExecutiveComplianceRecordRepository complianceRepo;
    @Autowired private ExecutiveFundingSourceRepository fundingRepo;
    @Autowired private ExecutiveEscrowAccountRepository escrowRepo;
    @Autowired private ExecutiveAlertRepository executiveAlertRepo;

    @Override
    public void run(String... args) {
        // ModuleDataInitializer ready. Preserving all user records in database.
    }
}
