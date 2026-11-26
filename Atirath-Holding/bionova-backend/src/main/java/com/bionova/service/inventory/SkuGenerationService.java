package com.bionova.service.inventory;

import com.bionova.dto.inventory.SkuAllocateRequest;
import com.bionova.dto.inventory.SkuPreviewRequest;
import com.bionova.dto.inventory.SkuPreviewResponse;
import com.bionova.entity.inventory.*;
import com.bionova.repository.inventory.*;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@Slf4j
public class SkuGenerationService {

    @Autowired
    private SkuMasterRepository masterRepository;

    @Autowired
    private SkuSequenceCounterRepository counterRepository;

    @Autowired
    private InventoryItemRepository itemRepository;

    @Autowired
    private InventoryCivilBomRepository civilBomRepository;

    @Autowired
    private InventoryFastenerRepository fastenerRepository;

    @Autowired
    private InventoryPipingRepository pipingRepository;

    private static final Pattern SERIAL_PATTERN = Pattern.compile("(\\d{4,})$");

    @PostConstruct
    public void init() {
        try {
            seedMasterDataIfEmpty();
            syncCountersFromExistingRecords();
        } catch (Exception e) {
            log.warn("Could not complete automatic SKU master data/counter initialization: {}", e.getMessage());
        }
    }

    /**
     * Retrieve all active master data grouped by category and option type.
     */
    public Map<String, Map<String, List<SkuMaster>>> getMasterData() {
        List<SkuMaster> all = masterRepository.findByIsActiveTrueOrderByCategoryAscOptionTypeAscSortOrderAsc();
        if (all.isEmpty()) {
            seedMasterDataIfEmpty();
            all = masterRepository.findByIsActiveTrueOrderByCategoryAscOptionTypeAscSortOrderAsc();
        }

        return all.stream()
                .collect(Collectors.groupingBy(
                        SkuMaster::getCategory,
                        Collectors.groupingBy(SkuMaster::getOptionType)
                ));
    }

    /**
     * Generate dynamic live preview of the SKU without incrementing the database sequence.
     */
    @Transactional(readOnly = true)
    public SkuPreviewResponse generatePreview(SkuPreviewRequest req) {
        String category = req.getCategory() != null ? req.getCategory().toUpperCase() : "AGRI";
        String prefix = getPrefixForCategory(category, req);
        long currentSeq = getEstimatedNextSequence(prefix);
        String serialStr = String.format("%04d", currentSeq);

        List<String> missing = new ArrayList<>();
        Map<String, String> specs = new LinkedHashMap<>();
        String sku;
        String format;

        switch (category) {
            case "AGRI":
            case "AGRI_FEEDSTOCK": {
                format = "AGR-[ITEM]-[GRADE]-[PACK_SIZE]-[SERIAL]";
                String item = sanitizeCode(req.getItemType(), "MZE");
                String grade = sanitizeCode(req.getGrade(), "A1");
                String pack = sanitizeCode(req.getPackSize(), "050");

                if (req.getItemType() == null || req.getItemType().isBlank()) missing.add("Item Type");
                if (req.getGrade() == null || req.getGrade().isBlank()) missing.add("Grade");
                if (req.getPackSize() == null || req.getPackSize().isBlank()) missing.add("Pack Size");

                specs.put("Category", "Agri & Feedstock Stock");
                specs.put("Item Code", item);
                specs.put("Grade", grade);
                specs.put("Pack Size", pack);

                sku = String.format("AGR-%s-%s-%s-%s", item, grade, pack, serialStr);
                break;
            }
            case "CIVIL_BOM":
            case "PLANT_CONSTRUCTION": {
                format = "PCB-[DISCIPLINE]-[ITEM]-[SPECIFICATION]-[SERIAL]";
                String disc = sanitizeCode(req.getDiscipline(), "CIV");
                String item = sanitizeCode(req.getItem(), "CON");
                String spec = sanitizeCode(req.getSpecification(), "001");

                if (req.getDiscipline() == null || req.getDiscipline().isBlank()) missing.add("Discipline");
                if (req.getItem() == null || req.getItem().isBlank()) missing.add("Item");
                if (req.getSpecification() == null || req.getSpecification().isBlank()) missing.add("Specification");

                specs.put("Category", "Plant Construction BOM");
                specs.put("Discipline", disc);
                specs.put("Item Code", item);
                specs.put("Specification", spec);

                sku = String.format("PCB-%s-%s-%s-%s", disc, item, spec, serialStr);
                break;
            }
            case "FASTENERS":
            case "HARDWARE": {
                format = "FST-[TYPE]-[MATERIAL]-[DIAMETER]-[LENGTH]-[GRADE]-[SERIAL]";
                String type = sanitizeCode(req.getFastenerType(), "BLT");
                String mat = sanitizeCode(req.getMaterial(), "SS304");
                String dia = sanitizeCode(req.getDiameter(), "M12");
                String len = sanitizeCode(req.getLength(), "050");
                String grd = sanitizeCode(req.getFastenerGrade(), "G8");

                if (req.getFastenerType() == null || req.getFastenerType().isBlank()) missing.add("Fastener Type");
                if (req.getMaterial() == null || req.getMaterial().isBlank()) missing.add("Material");
                if (req.getDiameter() == null || req.getDiameter().isBlank()) missing.add("Diameter");
                if (req.getLength() == null || req.getLength().isBlank()) missing.add("Length");
                if (req.getFastenerGrade() == null || req.getFastenerGrade().isBlank()) missing.add("Grade");

                specs.put("Category", "Fasteners & Hardware");
                specs.put("Type", type);
                specs.put("Material", mat);
                specs.put("Diameter", dia);
                specs.put("Length", len);
                specs.put("Grade", grd);

                sku = String.format("FST-%s-%s-%s-%s-%s-%s", type, mat, dia, len, grd, serialStr);
                break;
            }
            case "INSTRUMENTATION": {
                format = "INS-[TYPE]-[RANGE]-[CONNECTION]-[SERIAL]";
                String type = sanitizeCode(req.getInstrumentType(), "PRS");
                String range = sanitizeCode(req.getRange(), "010BAR");
                String conn = sanitizeCode(req.getConnection(), "THD");

                if (req.getInstrumentType() == null || req.getInstrumentType().isBlank()) missing.add("Instrument Type");
                if (req.getRange() == null || req.getRange().isBlank()) missing.add("Range");
                if (req.getConnection() == null || req.getConnection().isBlank()) missing.add("Connection");

                specs.put("Category", "Instrumentation");
                specs.put("Type", type);
                specs.put("Range", range);
                specs.put("Connection", conn);

                sku = String.format("INS-%s-%s-%s-%s", type, range, conn, serialStr);
                break;
            }
            case "PIPING":
            default: {
                // If it's an instrument inside Piping module
                if ("INSTRUMENTATION".equalsIgnoreCase(req.getPipingType()) ||
                    (req.getInstrumentType() != null && !req.getInstrumentType().isBlank())) {
                    format = "INS-[TYPE]-[RANGE]-[CONNECTION]-[SERIAL]";
                    String type = sanitizeCode(req.getInstrumentType(), "PRS");
                    String range = sanitizeCode(req.getRange(), "010BAR");
                    String conn = sanitizeCode(req.getConnection(), "THD");

                    specs.put("Category", "Instrumentation");
                    specs.put("Type", type);
                    specs.put("Range", range);
                    specs.put("Connection", conn);

                    sku = String.format("INS-%s-%s-%s-%s", type, range, conn, serialStr);
                } else {
                    format = "PIP-[TYPE]-[MATERIAL]-[SIZE]-[PRESSURE_CLASS]-[SERIAL]";
                    String type = sanitizeCode(req.getPipingType(), "ELB");
                    String mat = sanitizeCode(req.getPipingMaterial(), "CS");
                    String size = sanitizeCode(req.getPipingSize(), "050");
                    String pclass = sanitizeCode(req.getPressureClass(), "150");

                    if (req.getPipingType() == null || req.getPipingType().isBlank()) missing.add("Piping Type");
                    if (req.getPipingMaterial() == null || req.getPipingMaterial().isBlank()) missing.add("Material");
                    if (req.getPipingSize() == null || req.getPipingSize().isBlank()) missing.add("Size");
                    if (req.getPressureClass() == null || req.getPressureClass().isBlank()) missing.add("Pressure Class");

                    specs.put("Category", "Piping & Valves");
                    specs.put("Type", type);
                    specs.put("Material", mat);
                    specs.put("Size", size);
                    specs.put("Pressure Class", pclass);

                    sku = String.format("PIP-%s-%s-%s-%s-%s", type, mat, size, pclass, serialStr);
                }
                break;
            }
        }

        specs.put("Serial #", serialStr);

        return SkuPreviewResponse.builder()
                .sku(sku)
                .format(format)
                .prefix(prefix)
                .nextSerial(serialStr)
                .valid(missing.isEmpty())
                .missingFields(missing)
                .specifications(specs)
                .build();
    }

    /**
     * Atomically allocate the next unique SKU using database row locking.
     * Guarantees unique sequential SKU code without race conditions or re-use.
     */
    @Transactional
    public String allocateNextSku(SkuAllocateRequest req) {
        String category = req.getCategory() != null ? req.getCategory().toUpperCase() : "AGRI";
        String prefix = getPrefixForCategory(category, req);

        // Fetch counter with pessimistic write lock
        SkuSequenceCounter counter = counterRepository.findByPrefixWithLock(prefix)
                .orElseGet(() -> {
                    long initial = syncSingleCounterFromExisting(prefix);
                    return counterRepository.save(SkuSequenceCounter.builder()
                            .categoryPrefix(prefix)
                            .currentSequence(initial)
                            .build());
                });

        long newSeq = counter.getCurrentSequence() + 1;
        counter.setCurrentSequence(newSeq);

        String serialStr = String.format("%04d", newSeq);
        String finalSku;

        switch (category) {
            case "AGRI":
            case "AGRI_FEEDSTOCK": {
                String item = sanitizeCode(req.getItemType(), "MZE");
                String grade = sanitizeCode(req.getGrade(), "A1");
                String pack = sanitizeCode(req.getPackSize(), "050");
                finalSku = String.format("AGR-%s-%s-%s-%s", item, grade, pack, serialStr);
                break;
            }
            case "CIVIL_BOM":
            case "PLANT_CONSTRUCTION": {
                String disc = sanitizeCode(req.getDiscipline(), "CIV");
                String item = sanitizeCode(req.getItem(), "CON");
                String spec = sanitizeCode(req.getSpecification(), "001");
                finalSku = String.format("PCB-%s-%s-%s-%s", disc, item, spec, serialStr);
                break;
            }
            case "FASTENERS":
            case "HARDWARE": {
                String type = sanitizeCode(req.getFastenerType(), "BLT");
                String mat = sanitizeCode(req.getMaterial(), "SS304");
                String dia = sanitizeCode(req.getDiameter(), "M12");
                String len = sanitizeCode(req.getLength(), "050");
                String grd = sanitizeCode(req.getFastenerGrade(), "G8");
                finalSku = String.format("FST-%s-%s-%s-%s-%s-%s", type, mat, dia, len, grd, serialStr);
                break;
            }
            case "INSTRUMENTATION": {
                String type = sanitizeCode(req.getInstrumentType(), "PRS");
                String range = sanitizeCode(req.getRange(), "010BAR");
                String conn = sanitizeCode(req.getConnection(), "THD");
                finalSku = String.format("INS-%s-%s-%s-%s", type, range, conn, serialStr);
                break;
            }
            case "PIPING":
            default: {
                if ("INSTRUMENTATION".equalsIgnoreCase(req.getPipingType()) ||
                    (req.getInstrumentType() != null && !req.getInstrumentType().isBlank())) {
                    String type = sanitizeCode(req.getInstrumentType(), "PRS");
                    String range = sanitizeCode(req.getRange(), "010BAR");
                    String conn = sanitizeCode(req.getConnection(), "THD");
                    finalSku = String.format("INS-%s-%s-%s-%s", type, range, conn, serialStr);
                } else {
                    String type = sanitizeCode(req.getPipingType(), "ELB");
                    String mat = sanitizeCode(req.getPipingMaterial(), "CS");
                    String size = sanitizeCode(req.getPipingSize(), "050");
                    String pclass = sanitizeCode(req.getPressureClass(), "150");
                    finalSku = String.format("PIP-%s-%s-%s-%s-%s", type, mat, size, pclass, serialStr);
                }
                break;
            }
        }

        counter.setLastAssignedSku(finalSku);
        counterRepository.save(counter);

        log.info("Allocated unique SKU: {} (Category: {}, Prefix: {}, Sequence: {})", finalSku, category, prefix, newSeq);
        return finalSku;
    }

    private String getPrefixForCategory(String category, Object reqObj) {
        if ("AGRI".equalsIgnoreCase(category) || "AGRI_FEEDSTOCK".equalsIgnoreCase(category)) return "AGR";
        if ("CIVIL_BOM".equalsIgnoreCase(category) || "PLANT_CONSTRUCTION".equalsIgnoreCase(category)) return "PCB";
        if ("FASTENERS".equalsIgnoreCase(category) || "HARDWARE".equalsIgnoreCase(category)) return "FST";
        if ("INSTRUMENTATION".equalsIgnoreCase(category)) return "INS";

        if (reqObj instanceof SkuPreviewRequest) {
            SkuPreviewRequest r = (SkuPreviewRequest) reqObj;
            if ("INSTRUMENTATION".equalsIgnoreCase(r.getPipingType()) ||
                (r.getInstrumentType() != null && !r.getInstrumentType().isBlank())) {
                return "INS";
            }
        } else if (reqObj instanceof SkuAllocateRequest) {
            SkuAllocateRequest r = (SkuAllocateRequest) reqObj;
            if ("INSTRUMENTATION".equalsIgnoreCase(r.getPipingType()) ||
                (r.getInstrumentType() != null && !r.getInstrumentType().isBlank())) {
                return "INS";
            }
        }

        return "PIP";
    }

    private String sanitizeCode(String input, String fallback) {
        if (input == null || input.trim().isEmpty()) return fallback;
        String cleaned = input.trim().toUpperCase().replaceAll("[^A-Z0-9]", "");
        return cleaned.isEmpty() ? fallback : cleaned;
    }

    private long getEstimatedNextSequence(String prefix) {
        return counterRepository.findByCategoryPrefix(prefix)
                .map(c -> c.getCurrentSequence() + 1)
                .orElse(1L);
    }

    /**
     * Scan existing records in the DB to find maximum assigned sequence numbers.
     */
    private void syncCountersFromExistingRecords() {
        for (String prefix : Arrays.asList("AGR", "PCB", "FST", "PIP", "INS")) {
            long maxExisting = syncSingleCounterFromExisting(prefix);
            SkuSequenceCounter counter = counterRepository.findByCategoryPrefix(prefix)
                    .orElseGet(() -> SkuSequenceCounter.builder()
                            .categoryPrefix(prefix)
                            .currentSequence(0L)
                            .build());

            if (maxExisting > counter.getCurrentSequence()) {
                counter.setCurrentSequence(maxExisting);
                counterRepository.save(counter);
                log.info("Synchronized SKU sequence counter for {} to {}", prefix, maxExisting);
            }
        }
    }

    private long syncSingleCounterFromExisting(String prefix) {
        long max = 0;
        switch (prefix) {
            case "AGR": {
                for (InventoryItem it : itemRepository.findAll()) {
                    max = Math.max(max, extractSeq(it.getSku()));
                }
                break;
            }
            case "PCB": {
                for (InventoryCivilBom b : civilBomRepository.findAll()) {
                    max = Math.max(max, extractSeq(b.getSpecCode()));
                }
                break;
            }
            case "FST": {
                for (InventoryFastener f : fastenerRepository.findAll()) {
                    max = Math.max(max, extractSeq(f.getItemCode()));
                }
                break;
            }
            case "PIP": {
                for (InventoryPiping p : pipingRepository.findAll()) {
                    String tag = p.getTagNo();
                    if (tag != null && tag.startsWith("PIP")) {
                        max = Math.max(max, extractSeq(tag));
                    }
                }
                break;
            }
            case "INS": {
                for (InventoryPiping p : pipingRepository.findAll()) {
                    String tag = p.getTagNo();
                    if (tag != null && tag.startsWith("INS")) {
                        max = Math.max(max, extractSeq(tag));
                    }
                }
                break;
            }
        }
        return max;
    }

    private long extractSeq(String code) {
        if (code == null) return 0;
        Matcher m = SERIAL_PATTERN.matcher(code);
        if (m.find()) {
            try {
                return Long.parseLong(m.group(1));
            } catch (Exception ignored) {}
        }
        return 0;
    }

    /**
     * Seeds initial master data choices for all 4 categories.
     */
    private void seedMasterDataIfEmpty() {
        if (masterRepository.count() > 0) return;

        List<SkuMaster> seeds = new ArrayList<>();
        int order = 1;

        // ─────────────────────────────────────────────────────────────
        // 1. AGRI & FEEDSTOCK STOCK
        // ─────────────────────────────────────────────────────────────
        // Item Types
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "MZE", "Maize Grain & Silage (MZE)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "SOY", "Soybean Straw & Meal (SOY)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "RIC", "Rice Straw & Paddy Husk (RIC)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "NPR", "Super Napier Hybrid Grass (NPR)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "SRG", "Sweet Sorghum Bicolor (SRG)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "COT", "Cotton Stalk Biomass (COT)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "BAG", "Sugarcane Bagasse (BAG)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "WHT", "Wheat Straw Bales (WHT)", "Feedstock", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "ITEM_TYPE", "BIO", "Methanogenic Bacteria Inoculant (BIO)", "Additive", order++, true));

        // Grades
        seeds.add(new SkuMaster(null, "AGRI", "GRADE", "A1", "Grade A1 - Premium (Moisture < 12%)", "Premium", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "GRADE", "A2", "Grade A2 - Standard (Moisture 12-15%)", "Standard", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "GRADE", "B1", "Grade B1 - Field Baled (Moisture 15-20%)", "Field", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "GRADE", "B2", "Grade B2 - High Moisture Fermented Silage", "Silage", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "GRADE", "C1", "Grade C1 - Raw Field Biomass Residue", "Raw", order++, true));

        // Packaging Units
        seeds.add(new SkuMaster(null, "AGRI", "PACK_SIZE", "025", "25 Kg Woven Polypropylene Sack", "25Kg", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "PACK_SIZE", "050", "50 Kg Commercial Standard Bag", "50Kg", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "PACK_SIZE", "100", "100 Kg Compressed High-Density Bale", "100Kg", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "PACK_SIZE", "500", "500 Kg FIBC Bulk Jumbo Bag", "500Kg", order++, true));
        seeds.add(new SkuMaster(null, "AGRI", "PACK_SIZE", "001", "1 MT Loose Bulk Truckload", "1MT", order++, true));

        // ─────────────────────────────────────────────────────────────
        // 2. PLANT CONSTRUCTION BOM
        // ─────────────────────────────────────────────────────────────
        // Disciplines
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "DISCIPLINE", "CIV", "Civil & Structural Works (CIV)", "Civil", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "DISCIPLINE", "MEC", "Mechanical & Process Machinery (MEC)", "Mechanical", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "DISCIPLINE", "ELE", "Electrical & Power Distribution (ELE)", "Electrical", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "DISCIPLINE", "INS", "Instrumentation & SCADA Automation (INS)", "Instrumentation", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "DISCIPLINE", "PIP", "Process Piping & Fluid Systems (PIP)", "Piping", order++, true));

        // BOM Items
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "CON", "Ready-Mix Concrete / Grout (CON)", "CIV", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "REB", "TMT Fe550D Reinforcement Rebars (REB)", "CIV", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "STL", "Structural Heavy Steel Sections (STL)", "CIV", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "CEM", "Portland Pozzolana Cement (CEM)", "CIV", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "AGG", "Coarse & Fine River Aggregates (AGG)", "CIV", order++, true));

        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "PMP", "Slurry & Progressive Cavity Pumps (PMP)", "MEC", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "AGT", "Digester Submersible Agitators (AGT)", "MEC", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "BLR", "Biogas Industrial Water Boilers (BLR)", "MEC", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "CMP", "High-Pressure Gas Compressors (CMP)", "MEC", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "SEP", "Screw Press Dewatering Separator (SEP)", "MEC", order++, true));

        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "MTR", "Flameproof Electric Motors (MTR)", "ELE", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "TRF", "11kV/415V Power Transformers (TRF)", "ELE", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "VFD", "Variable Frequency Drive Panels (VFD)", "ELE", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "ITEM", "CAB", "Armored Multi-Core Power Cables (CAB)", "ELE", order++, true));

        // Specifications
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "SPECIFICATION", "001", "Standard Engineering Spec Rev 1 (001)", "Standard", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "SPECIFICATION", "002", "Heavy-Duty Industrial Spec Rev 2 (002)", "HeavyDuty", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "SPECIFICATION", "003", "Corrosion & H2S Resistant Spec (003)", "Special", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "SPECIFICATION", "M35", "M35 High-Strength Mix Design (M35)", "CivilSpec", order++, true));
        seeds.add(new SkuMaster(null, "CIVIL_BOM", "SPECIFICATION", "F55", "Fe550D High Ductility Rebar (F55)", "CivilSpec", order++, true));

        // ─────────────────────────────────────────────────────────────
        // 3. FASTENERS & HARDWARE
        // ─────────────────────────────────────────────────────────────
        // Fastener Types
        seeds.add(new SkuMaster(null, "FASTENERS", "TYPE", "BLT", "Hex Head / Flange Bolts (BLT)", "Bolts", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "TYPE", "NUT", "Heavy Hex / Nyloc Nuts (NUT)", "Nuts", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "TYPE", "WSH", "Flat & Spring Washers (WSH)", "Washers", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "TYPE", "STD", "Continuous Thread Stud Bolts (STD)", "Studs", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "TYPE", "ANC", "Heavy-Duty Expansion Anchor Bolts (ANC)", "Anchors", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "TYPE", "SCR", "Self-Tapping Tek Screws (SCR)", "Screws", order++, true));

        // Materials
        seeds.add(new SkuMaster(null, "FASTENERS", "MATERIAL", "SS304", "Stainless Steel AISI 304 (SS304)", "SS", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "MATERIAL", "SS316", "Stainless Steel AISI 316 Acid-Resistant (SS316)", "SS", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "MATERIAL", "MS", "Mild Structural Steel (MS)", "Steel", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "MATERIAL", "CS", "High-Carbon Steel (CS)", "Steel", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "MATERIAL", "B7", "Alloy Steel ASTM A193 B7 (B7)", "Alloy", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "MATERIAL", "BRS", "Corrosion-Proof Brass Alloy (BRS)", "Brass", order++, true));

        // Diameters
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M06", "M6 Metric Thread (M06)", "6mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M08", "M8 Metric Thread (M08)", "8mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M10", "M10 Metric Thread (M10)", "10mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M12", "M12 Metric Thread (M12)", "12mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M16", "M16 Metric Thread (M16)", "16mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M20", "M20 Metric Thread (M20)", "20mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M24", "M24 Metric Thread (M24)", "24mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "DIAMETER", "M30", "M30 Metric Thread (M30)", "30mm", order++, true));

        // Lengths
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "000", "000 mm (Applicable for Nuts & Washers)", "0mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "025", "25 mm Length (025)", "25mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "035", "35 mm Length (035)", "35mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "050", "50 mm Length (050)", "50mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "075", "75 mm Length (075)", "75mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "090", "90 mm Length (090)", "90mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "100", "100 mm Length (100)", "100mm", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "LENGTH", "150", "150 mm Length (150)", "150mm", order++, true));

        // Grades
        seeds.add(new SkuMaster(null, "FASTENERS", "GRADE", "G4", "Grade 4.8 Commercial Quality (G4)", "4.8", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "GRADE", "G8", "Grade 8.8 High-Tensile Structural (G8)", "8.8", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "GRADE", "G10", "Grade 10.9 Heavy-Duty Industrial (G10)", "10.9", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "GRADE", "G12", "Grade 12.9 Super Alloy High-Tensile (G12)", "12.9", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "GRADE", "A2", "Grade A2-70 Stainless Steel (A2)", "A2-70", order++, true));
        seeds.add(new SkuMaster(null, "FASTENERS", "GRADE", "A4", "Grade A4-80 Marine Stainless Steel (A4)", "A4-80", order++, true));

        // ─────────────────────────────────────────────────────────────
        // 4. PIPING & INSTRUMENTATION
        // ─────────────────────────────────────────────────────────────
        // Piping Types
        seeds.add(new SkuMaster(null, "PIPING", "TYPE", "ELB", "90° / 45° Long Radius Pipe Elbow (ELB)", "Elbow", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "TYPE", "TEE", "Equal / Reducing Pipe Tee (TEE)", "Tee", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "TYPE", "VAL", "Industrial Isolation Ball / Gate Valve (VAL)", "Valve", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "TYPE", "PIP", "Straight Seamless Process Pipe Spool (PIP)", "Pipe", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "TYPE", "RED", "Concentric / Eccentric Reducer (RED)", "Reducer", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "TYPE", "FLG", "Weld-Neck Raised Face Flange (FLG)", "Flange", order++, true));

        // Piping Materials
        seeds.add(new SkuMaster(null, "PIPING", "MATERIAL", "CS", "Carbon Steel ASTM A106 Gr. B (CS)", "CS", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "MATERIAL", "SS304", "Stainless Steel ASTM A312 TP304 (SS304)", "SS304", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "MATERIAL", "SS316", "Stainless Steel ASTM A312 TP316L (SS316)", "SS316", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "MATERIAL", "HDPE", "High-Density Polyethylene PE100 (HDPE)", "HDPE", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "MATERIAL", "GI", "Hot-Dip Galvanized Iron Heavy Class (GI)", "GI", order++, true));

        // Piping Sizes
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "015", "1/2\" NB (DN15 / 15mm)", "DN15", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "025", "1\" NB (DN25 / 25mm)", "DN25", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "050", "2\" NB (DN50 / 50mm)", "DN50", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "080", "3\" NB (DN80 / 80mm)", "DN80", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "100", "4\" NB (DN100 / 100mm)", "DN100", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "150", "6\" NB (DN150 / 150mm)", "DN150", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "SIZE", "200", "8\" NB (DN200 / 200mm)", "DN200", order++, true));

        // Pressure Classes
        seeds.add(new SkuMaster(null, "PIPING", "PRESSURE_CLASS", "150", "ANSI Class 150# Raised Face (150)", "150#", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "PRESSURE_CLASS", "300", "ANSI Class 300# Raised Face (300)", "300#", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "PRESSURE_CLASS", "600", "ANSI Class 600# High Pressure (600)", "600#", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "PRESSURE_CLASS", "800", "Class 800# Forged Steel Valve Rating (800)", "800#", order++, true));
        seeds.add(new SkuMaster(null, "PIPING", "PRESSURE_CLASS", "PN16", "DIN PN16 Bar Rating (PN16)", "PN16", order++, true));

        // ─────────────────────────────────────────────────────────────
        // 5. INSTRUMENTATION
        // ─────────────────────────────────────────────────────────────
        // Instrument Types
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "TYPE", "PRS", "Pressure Transmitter / Smart Gauge (PRS)", "Pressure", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "TYPE", "TMP", "Temperature Sensor RTD Pt100 / Thermowell (TMP)", "Temperature", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "TYPE", "FLW", "Coriolis / Vortex Mass Flow Meter (FLW)", "Flow", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "TYPE", "LVL", "Guided Wave Radar Level Transmitter (LVL)", "Level", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "TYPE", "GAS", "NDIR Biogas Analyzer CH4 / H2S (GAS)", "Gas", order++, true));

        // Ranges
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "010BAR", "0 to 10 Bar (010BAR)", "10Bar", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "025BAR", "0 to 25 Bar (025BAR)", "25Bar", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "100BAR", "0 to 100 Bar High Pressure (100BAR)", "100Bar", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "200C", "-50°C to +200°C (200C)", "200C", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "500C", "0°C to +500°C High Temp (500C)", "500C", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "100M3H", "0 to 100 Nm³/hr Gas Flow (100M3H)", "100M3H", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "500M3H", "0 to 500 Nm³/hr Gas Flow (500M3H)", "500M3H", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "RANGE", "100PCT", "0 to 100% Volumetric Gas Level (100PCT)", "100%", order++, true));

        // Connections
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "CONNECTION", "THD", "Threaded 1/2\" NPT Male / Female (THD)", "Threaded", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "CONNECTION", "FLG", "ASME B16.5 Flanged Raised Face (FLG)", "Flanged", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "CONNECTION", "TC", "Tri-Clamp Sanitary Hygienic Fit (TC)", "TriClamp", order++, true));
        seeds.add(new SkuMaster(null, "INSTRUMENTATION", "CONNECTION", "WLD", "Socket Weld Direct Pipe End (WLD)", "Weld", order++, true));

        masterRepository.saveAll(seeds);
        log.info("Initialized {} default inventory SKU master data entries.", seeds.size());
    }
}
