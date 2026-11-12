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
        try {
            // Purge any dummy / mock seed records so database contains zero dummy data.
            // Tables will only store actual records created by the user through the application.
            inventoryItemRepo.deleteAll();
            civilBomRepo.deleteAll();
            fastenerRepo.deleteAll();
            pipingRepo.deleteAll();
            warrantyRepo.deleteAll();
            inventoryAlertRepo.deleteAll();
            weighbridgeRepo.deleteAll();
            vendorRepo.deleteAll();

            visitorRecordRepo.deleteAll();
            visitorRequestRepo.deleteAll();
            visitorAppointmentRepo.deleteAll();
            visitorVehicleRepo.deleteAll();
            materialInwardRepo.deleteAll();
            materialOutwardRepo.deleteAll();
            safetyClearanceRepo.deleteAll();

            pipelineRepo.deleteAll();
            budgetRepo.deleteAll();
            revenueRepo.deleteAll();
            complianceRepo.deleteAll();
            fundingRepo.deleteAll();
            escrowRepo.deleteAll();
            executiveAlertRepo.deleteAll();
            System.out.println("ModuleDataInitializer: Dummy/mock records successfully purged from database.");
        } catch (Exception e) {
            System.err.println("ModuleDataInitializer purge notice: " + e.getMessage());
        }
    }
}
