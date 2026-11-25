package com.bionova.controller;

import com.bionova.entity.procurement.*;
import com.bionova.repository.procurement.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/procurement")
public class ProcurementController {

    @Autowired
    private ProcurementSupplierRepository supplierRepository;

    @Autowired
    private PurchaseRequisitionRepository requisitionRepository;

    @Autowired
    private PurchaseOrderRepository purchaseOrderRepository;

    @Autowired
    private DeliveryNoteRepository deliveryNoteRepository;

    // --- Suppliers ---
    @GetMapping("/suppliers")
    public List<ProcurementSupplier> getSuppliers() {
        return supplierRepository.findAll();
    }

    @PostMapping("/suppliers")
    public ResponseEntity<ProcurementSupplier> createSupplier(@RequestBody ProcurementSupplier supplier) {
        supplier.setId(null);
        return ResponseEntity.ok(supplierRepository.save(supplier));
    }

    @PutMapping("/suppliers/{id}")
    public ResponseEntity<ProcurementSupplier> updateSupplier(@PathVariable Long id, @RequestBody ProcurementSupplier updated) {
        return supplierRepository.findById(id).map(existing -> {
            existing.setSupplierCode(updated.getSupplierCode());
            existing.setName(updated.getName());
            existing.setTier(updated.getTier());
            existing.setCategory(updated.getCategory());
            existing.setContactPerson(updated.getContactPerson());
            existing.setPhone(updated.getPhone());
            existing.setEmail(updated.getEmail());
            existing.setPlantFacility(updated.getPlantFacility());
            existing.setGstin(updated.getGstin());
            existing.setPanNo(updated.getPanNo());
            existing.setMsmeType(updated.getMsmeType());
            existing.setRating(updated.getRating());
            existing.setActivePosCount(updated.getActivePosCount());
            existing.setStatus(updated.getStatus());
            return ResponseEntity.ok(supplierRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/suppliers/{id}")
    public ResponseEntity<Void> deleteSupplier(@PathVariable Long id) {
        if (!supplierRepository.existsById(id)) return ResponseEntity.notFound().build();
        supplierRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Requisitions ---
    @GetMapping("/requisitions")
    public List<PurchaseRequisition> getRequisitions() {
        return requisitionRepository.findAll();
    }

    @PostMapping("/requisitions")
    public ResponseEntity<PurchaseRequisition> createRequisition(@RequestBody PurchaseRequisition pr) {
        pr.setId(null);
        return ResponseEntity.ok(requisitionRepository.save(pr));
    }

    @PutMapping("/requisitions/{id}")
    public ResponseEntity<PurchaseRequisition> updateRequisition(@PathVariable Long id, @RequestBody PurchaseRequisition updated) {
        return requisitionRepository.findById(id).map(existing -> {
            existing.setPrNumber(updated.getPrNumber());
            existing.setDepartment(updated.getDepartment());
            existing.setPlantFacility(updated.getPlantFacility());
            existing.setPriority(updated.getPriority());
            existing.setRequiredDate(updated.getRequiredDate());
            existing.setJustification(updated.getJustification());
            existing.setStatus(updated.getStatus());
            existing.setEstTotalCost(updated.getEstTotalCost());
            existing.setRequestedBy(updated.getRequestedBy());
            existing.setApprovedBy(updated.getApprovedBy());
            if (updated.getItems() != null) {
                existing.setItems(updated.getItems());
            }
            return ResponseEntity.ok(requisitionRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/requisitions/{id}")
    public ResponseEntity<Void> deleteRequisition(@PathVariable Long id) {
        if (!requisitionRepository.existsById(id)) return ResponseEntity.notFound().build();
        requisitionRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Purchase Orders ---
    @GetMapping("/purchase-orders")
    public List<PurchaseOrder> getPurchaseOrders() {
        return purchaseOrderRepository.findAll();
    }

    @GetMapping("/next-po-number")
    public ResponseEntity<Map<String, String>> getNextPoNumber() {
        String nextPoNumber = generateNextPoNumber();
        int currentYear = java.time.LocalDate.now().getYear();
        return ResponseEntity.ok(Map.of(
            "nextPoNumber", nextPoNumber,
            "year", String.valueOf(currentYear)
        ));
    }

    private synchronized String generateNextPoNumber() {
        int currentYear = java.time.LocalDate.now().getYear();
        String prefix = "PO-" + currentYear + "-";
        List<PurchaseOrder> allOrders = purchaseOrderRepository.findAll();
        int maxSeq = 0;
        for (PurchaseOrder po : allOrders) {
            if (po.getPoNumber() != null && po.getPoNumber().startsWith(prefix)) {
                try {
                    String digitsOnly = po.getPoNumber().substring(prefix.length()).replaceAll("[^0-9]", "").trim();
                    if (!digitsOnly.isEmpty()) {
                        int seq = Integer.parseInt(digitsOnly);
                        if (seq > maxSeq) {
                            maxSeq = seq;
                        }
                    }
                } catch (Exception ignored) {}
            }
        }
        return String.format("PO-%d-%04d", currentYear, maxSeq + 1);
    }

    @PostMapping("/purchase-orders")
    public ResponseEntity<PurchaseOrder> createPurchaseOrder(@RequestBody PurchaseOrder po) {
        po.setId(null);
        if (po.getPoNumber() == null || po.getPoNumber().trim().isEmpty()) {
            po.setPoNumber(generateNextPoNumber());
        }
        return ResponseEntity.ok(purchaseOrderRepository.save(po));
    }

    @PutMapping("/purchase-orders/{id}")
    public ResponseEntity<PurchaseOrder> updatePurchaseOrder(@PathVariable Long id, @RequestBody PurchaseOrder updated) {
        return purchaseOrderRepository.findById(id).map(existing -> {
            existing.setPoNumber(updated.getPoNumber());
            existing.setSupplierName(updated.getSupplierName());
            existing.setSupplierId(updated.getSupplierId());
            existing.setPlantFacility(updated.getPlantFacility());
            existing.setOrderDate(updated.getOrderDate());
            existing.setDeliveryDate(updated.getDeliveryDate());
            existing.setPaymentTerms(updated.getPaymentTerms());
            existing.setDeliveryTerms(updated.getDeliveryTerms());
            existing.setShippingAddress(updated.getShippingAddress());
            existing.setSubtotal(updated.getSubtotal());
            existing.setTaxAmount(updated.getTaxAmount());
            existing.setTotalAmount(updated.getTotalAmount());
            existing.setStatus(updated.getStatus());
            if (updated.getItems() != null) {
                existing.setItems(updated.getItems());
            }
            return ResponseEntity.ok(purchaseOrderRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/purchase-orders/{id}")
    public ResponseEntity<Void> deletePurchaseOrder(@PathVariable Long id) {
        if (!purchaseOrderRepository.existsById(id)) return ResponseEntity.notFound().build();
        purchaseOrderRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Delivery Notes ---
    @GetMapping("/delivery-notes")
    public List<DeliveryNote> getDeliveryNotes() {
        return deliveryNoteRepository.findAll();
    }

    @PostMapping("/delivery-notes")
    public ResponseEntity<DeliveryNote> createDeliveryNote(@RequestBody DeliveryNote note) {
        note.setId(null);
        return ResponseEntity.ok(deliveryNoteRepository.save(note));
    }

    @PutMapping("/delivery-notes/{id}")
    public ResponseEntity<DeliveryNote> updateDeliveryNote(@PathVariable Long id, @RequestBody DeliveryNote updated) {
        return deliveryNoteRepository.findById(id).map(existing -> {
            existing.setGrnNumber(updated.getGrnNumber());
            existing.setPoNumber(updated.getPoNumber());
            existing.setSupplierName(updated.getSupplierName());
            existing.setTransporter(updated.getTransporter());
            existing.setVehicleNo(updated.getVehicleNo());
            existing.setEWayBill(updated.getEWayBill());
            existing.setReceivedDate(updated.getReceivedDate());
            existing.setReceivingZone(updated.getReceivingZone());
            existing.setOrderedQty(updated.getOrderedQty());
            existing.setDispatchedQty(updated.getDispatchedQty());
            existing.setReceivedQty(updated.getReceivedQty());
            existing.setAcceptedQty(updated.getAcceptedQty());
            existing.setRejectedQty(updated.getRejectedQty());
            existing.setInspectionStatus(updated.getInspectionStatus());
            existing.setRemarks(updated.getRemarks());
            return ResponseEntity.ok(deliveryNoteRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/delivery-notes/{id}")
    public ResponseEntity<Void> deleteDeliveryNote(@PathVariable Long id) {
        if (!deliveryNoteRepository.existsById(id)) return ResponseEntity.notFound().build();
        deliveryNoteRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
