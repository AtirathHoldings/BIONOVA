import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import {
  Wheat,
  Calendar,
  Tractor,
  Layers,
  MapPin,
  Clock,
  CheckCircle2,
  AlertTriangle,
  TrendingUp,
  Download,
  Filter,
  Plus,
  Search,
  Droplets,
  Activity,
  FileText,
  UserCheck,
  BookOpen,
  X,
  ArrowRight,
  ShieldCheck,
  Edit3,
  Trash2,
  Building,
  Truck,
  Info,
  Save
} from 'lucide-react';
import { exportToCSV } from '../../../utils/exportUtils';
import {
  getHarvestBatches,
  saveHarvestBatch,
  deleteHarvestBatch
} from '../../../utils/harvestingApi';
import Sidebar from '../../Sidebar.jsx';
import Header from '../../Header.jsx';
import '../../../styles/harvesting.css';
import '../../../styles/SupplyChainOperations.css';

const TAB_KEY_MAP = {
  'harvest-cycles': 'harvest-cycles',
  'cycles': 'harvest-cycles',
  'active-harvesting-cycles': 'harvest-cycles',
  'plantation-parcels': 'plantation-parcels',
  'blocks': 'plantation-parcels',
  'plantation-blocks': 'plantation-parcels',
  'contracted-plantation-blocks': 'plantation-parcels',
  'machinery-fleet': 'machinery-fleet',
  'fleet': 'machinery-fleet',
  'forage-harvesters': 'machinery-fleet',
  'silage-bunkers': 'silage-bunkers',
  'bunkers': 'silage-bunkers',
  'silage-bunkers-reserve': 'silage-bunkers'
};

export default function HarvestingModule({ data, selectedPlant, userRole, onLogout, standalone }) {
  const { tab } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  const getResolvedTab = () => {
    if (tab && TAB_KEY_MAP[tab]) return TAB_KEY_MAP[tab];
    const path = (location.pathname || '').toLowerCase();
    if (path.includes('plantation') || path.includes('parcels') || path.includes('block')) return 'plantation-parcels';
    if (path.includes('machinery') || path.includes('fleet') || path.includes('harvester')) return 'machinery-fleet';
    if (path.includes('silage') || path.includes('bunker')) return 'silage-bunkers';
    return 'harvest-cycles';
  };

  const activeTab = getResolvedTab();

  const handleTabChange = (tabId) => {
    navigate(`/harvesting/${tabId}`);
  };

  const [searchTerm, setSearchTerm] = useState('');
  const [cropFilter, setCropFilter] = useState('ALL');
  const [isGuideOpen, setIsGuideOpen] = useState(false);

  // Plant scope
  const plantName = selectedPlant ? selectedPlant.name : 'Kurnool 20 TPD CBG Plant';

  // Initial Seed Batches
  const INITIAL_BATCHES = [
    {
      id: 'HARV-2026-088',
      parcelId: 'PLT-KRN-SEC-04',
      farmName: 'Atirath Energy Plantation Sector 4',
      crop: 'Super Napier (CO-5 High Sugar)',
      acreage: '45 Acres',
      cutNumber: 'Cut #4 of 7',
      plannedHarvestDate: '2026-11-12',
      estimatedYieldMT: 360,
      actualHarvestedMT: 352,
      moisturePercent: 68.4,
      targetMoisture: '65 - 70%',
      assignedFleet: 'Claas Jaguar 850 + 4 Tippers',
      silageBunker: 'Bunker #02 (Lactic Ensiling)',
      status: 'Harvest In-Progress',
      supervisor: 'K. Somanna (Agronomist)'
    },
    {
      id: 'HARV-2026-089',
      parcelId: 'PLT-KRN-SEC-02',
      farmName: 'Raju & Sons Contract Farm Block B',
      crop: 'Super Napier (Pakchong-1)',
      acreage: '30 Acres',
      cutNumber: 'Cut #3 of 7',
      plannedHarvestDate: '2026-11-15',
      estimatedYieldMT: 240,
      actualHarvestedMT: 0,
      moisturePercent: 66.8,
      targetMoisture: '65 - 70%',
      assignedFleet: 'New Holland FR650 Harvester',
      silageBunker: 'Bunker #01 (Direct Feed)',
      status: 'Scheduled',
      supervisor: 'M. Venkat (Field Officer)'
    },
    {
      id: 'HARV-2026-086',
      parcelId: 'PLT-KRN-SEC-01',
      farmName: 'Kurnool Agritech Cooperative Block A',
      crop: 'Energy Cane (High Fiber Biomass)',
      acreage: '60 Acres',
      cutNumber: 'Cut #2 of 3',
      plannedHarvestDate: '2026-11-06',
      estimatedYieldMT: 480,
      actualHarvestedMT: 494,
      moisturePercent: 64.2,
      targetMoisture: '62 - 68%',
      assignedFleet: 'John Deere Forage 8400',
      silageBunker: 'Bunker #03 (Silage Stack)',
      status: 'Completed',
      supervisor: 'K. Somanna (Agronomist)'
    },
    {
      id: 'HARV-2026-085',
      parcelId: 'PLT-KRN-SEC-06',
      farmName: 'Paddy Straw Baling Cluster Nandyal',
      crop: 'Paddy / Rice Straw (Dry Baled)',
      acreage: '120 Acres',
      cutNumber: 'Post-Harvest Baling',
      plannedHarvestDate: '2026-11-02',
      estimatedYieldMT: 280,
      actualHarvestedMT: 275,
      moisturePercent: 14.5,
      targetMoisture: '< 18% (Dry Storage)',
      assignedFleet: '3x Square Balers + 6 Tractors',
      silageBunker: 'Dry Straw Covered Shed #1',
      status: 'Completed',
      supervisor: 'S. Ramakrishna (Logistics Lead)'
    }
  ];

  // 1. Harvesting Cycles & Schedules Data with LocalStorage Persistence
  const [harvestBatches, setHarvestBatches] = useState(() => {
    try {
      const saved = localStorage.getItem('bioNovaHarvestBatches');
      if (saved) return JSON.parse(saved);
    } catch (e) {
      console.warn('Failed to parse harvest batches from localStorage', e);
    }
    return INITIAL_BATCHES;
  });

  useEffect(() => {
    getHarvestBatches().then(batches => {
      if (batches && Array.isArray(batches) && batches.length > 0) {
        setHarvestBatches(batches);
      }
    }).catch(() => {});
  }, []);

  // Modal and Form States
  const [isScheduleModalOpen, setIsScheduleModalOpen] = useState(false);
  const [editingCutId, setEditingCutId] = useState(null);
  const [feedbackMsg, setFeedbackMsg] = useState(null);

  const defaultCutFormData = {
    id: '',
    parcelId: 'PLT-KRN-SEC-04',
    farmName: 'Atirath Energy Plantation Sector 4',
    crop: 'Super Napier (CO-5 High Sugar)',
    acreage: '40',
    cutNumber: 'Cut #1 of 7',
    plannedHarvestDate: new Date().toISOString().split('T')[0],
    estimatedYieldMT: '320',
    actualHarvestedMT: '0',
    moisturePercent: '67.5',
    targetMoisture: '65 - 70%',
    assignedFleet: 'Claas Jaguar 850 + 4 Tippers',
    silageBunker: 'Bunker #01 (Direct Feed)',
    status: 'Scheduled',
    supervisor: 'K. Somanna (Agronomist)',
    notes: ''
  };

  const [formData, setFormData] = useState(defaultCutFormData);

  const generateBatchId = () => {
    const nums = harvestBatches
      .map(b => {
        const m = (b.id || '').match(/\d+$/);
        return m ? parseInt(m[0], 10) : 0;
      })
      .filter(n => !isNaN(n));
    const nextNum = nums.length > 0 ? Math.max(...nums) + 1 : 90;
    return `HARV-2026-${String(nextNum).padStart(3, '0')}`;
  };

  const handleOpenScheduleModal = (parcel = null) => {
    const newId = generateBatchId();
    setEditingCutId(null);
    if (parcel) {
      const acres = Math.min(parcel.areaAcres || 40, 50);
      setFormData({
        ...defaultCutFormData,
        id: newId,
        parcelId: parcel.id,
        farmName: parcel.name,
        crop: parcel.variety?.includes('Napier') ? 'Super Napier (CO-5 High Sugar)' : parcel.variety || 'Super Napier (CO-5 High Sugar)',
        acreage: String(acres),
        estimatedYieldMT: String(acres * 8)
      });
    } else {
      setFormData({
        ...defaultCutFormData,
        id: newId
      });
    }
    setIsScheduleModalOpen(true);
  };

  const handleOpenEditModal = (batch) => {
    setEditingCutId(batch.id);
    setFormData({
      id: batch.id,
      parcelId: batch.parcelId || '',
      farmName: batch.farmName,
      crop: batch.crop,
      acreage: String(batch.acreage || '').replace(/\D/g, '') || '40',
      cutNumber: batch.cutNumber,
      plannedHarvestDate: batch.plannedHarvestDate,
      estimatedYieldMT: String(batch.estimatedYieldMT || '0'),
      actualHarvestedMT: String(batch.actualHarvestedMT || '0'),
      moisturePercent: String(batch.moisturePercent || '67.5'),
      targetMoisture: batch.targetMoisture || '65 - 70%',
      assignedFleet: batch.assignedFleet,
      silageBunker: batch.silageBunker,
      status: batch.status,
      supervisor: batch.supervisor || 'K. Somanna (Agronomist)',
      notes: batch.notes || ''
    });
    setIsScheduleModalOpen(true);
  };

  const handleFormChange = (field, value) => {
    setFormData(prev => {
      const next = { ...prev, [field]: value };
      if (field === 'acreage') {
        const numAcres = parseFloat(value) || 0;
        const yieldFactor = next.crop.includes('Straw') ? 2.5 : 8;
        next.estimatedYieldMT = String(Math.round(numAcres * yieldFactor));
      }
      if (field === 'crop') {
        if (value.includes('Straw')) {
          next.targetMoisture = '< 18% (Dry Storage)';
          next.moisturePercent = '14.5';
          const numAcres = parseFloat(next.acreage) || 0;
          next.estimatedYieldMT = String(Math.round(numAcres * 2.5));
          next.cutNumber = 'Post-Harvest Baling';
          next.assignedFleet = '3x Square Balers + 6 Tractors';
          next.silageBunker = 'Dry Straw Covered Shed #1';
        } else {
          next.targetMoisture = '65 - 70%';
          next.moisturePercent = '67.5';
          const numAcres = parseFloat(next.acreage) || 0;
          next.estimatedYieldMT = String(Math.round(numAcres * 8));
          if (next.cutNumber === 'Post-Harvest Baling') next.cutNumber = 'Cut #1 of 7';
        }
      }
      return next;
    });
  };

  const handleSaveHarvestCut = (e) => {
    e.preventDefault();
    const cleanAcreage = formData.acreage ? `${formData.acreage} Acres` : '40 Acres';
    const cleanEstimatedMT = Number(formData.estimatedYieldMT) || 0;
    const cleanActualMT = Number(formData.actualHarvestedMT) || 0;
    const cleanMoisture = Number(formData.moisturePercent) || 67.5;

    let updatedList;
    let targetBatch = null;
    if (editingCutId) {
      targetBatch = {
        ...formData,
        id: editingCutId,
        acreage: cleanAcreage,
        estimatedYieldMT: cleanEstimatedMT,
        actualHarvestedMT: cleanActualMT,
        moisturePercent: cleanMoisture
      };
      updatedList = harvestBatches.map(b => (b.id === editingCutId ? { ...b, ...targetBatch } : b));
      setFeedbackMsg(`Harvest cut ${editingCutId} updated successfully.`);
    } else {
      const newCut = {
        ...formData,
        id: formData.id || generateBatchId(),
        acreage: cleanAcreage,
        estimatedYieldMT: cleanEstimatedMT,
        actualHarvestedMT: cleanActualMT,
        moisturePercent: cleanMoisture
      };
      targetBatch = newCut;
      updatedList = [newCut, ...harvestBatches];
      setFeedbackMsg(`New harvest cut ${newCut.id} scheduled for ${newCut.farmName}!`);
      handleTabChange('harvest-cycles');
    }

    setHarvestBatches(updatedList);
    if (targetBatch) {
      saveHarvestBatch(targetBatch).catch(() => {});
    }
    setIsScheduleModalOpen(false);

    setTimeout(() => {
      setFeedbackMsg(null);
    }, 4500);
  };

  const handleDeleteCut = (id) => {
    if (window.confirm(`Are you sure you want to remove harvest cut schedule "${id}"?`)) {
      const updated = harvestBatches.filter(b => b.id !== id);
      setHarvestBatches(updated);
      deleteHarvestBatch(id).catch(() => {});
      setFeedbackMsg(`Harvest cut ${id} removed.`);
      setTimeout(() => setFeedbackMsg(null), 3000);
    }
  };

  // 2. Plantation Parcels & Cultivation Acreage Data
  const plantationParcels = [
    {
      id: 'PARCEL-01',
      name: 'Kurnool Captive Napier Plantation',
      areaAcres: 450,
      variety: 'Super Napier CO-5',
      sowingDate: '2024-03-15',
      cuttingIntervalDays: 60,
      annualYieldMT: '36,000 MT/yr',
      fertigationSource: 'Plant LFOM (Liquid Digestate 100%)',
      soilHealthPH: 7.2,
      farmerContract: 'Captive Company Owned'
    },
    {
      id: 'PARCEL-02',
      name: 'Dhone Farmer Producer Org (FPO) Cluster',
      areaAcres: 380,
      variety: 'Super Napier Pakchong-1',
      sowingDate: '2024-06-10',
      cuttingIntervalDays: 65,
      annualYieldMT: '28,500 MT/yr',
      fertigationSource: 'LFOM Fertigation + Solar Drip',
      soilHealthPH: 7.4,
      farmerContract: '10-Year SATAT Supply Agreement'
    },
    {
      id: 'PARCEL-03',
      name: 'Nandyal Canal Agro Block',
      areaAcres: 370,
      variety: 'High-Sugar Napier + Forage Sorghum',
      sowingDate: '2024-08-01',
      cuttingIntervalDays: 70,
      annualYieldMT: '26,000 MT/yr',
      fertigationSource: 'Canal Water + LFOM',
      soilHealthPH: 7.1,
      farmerContract: 'Contract Farming FPO #04'
    }
  ];

  // 3. Harvesting & Machinery Fleet
  const machineryFleet = [
    {
      id: 'EQ-FLT-01',
      machine: 'Claas Jaguar 850 Forage Harvester',
      type: 'Self-Propelled Forage Harvester',
      capacity: '40 MT/Hour',
      cuttingLength: '8 - 12 mm (Optimum Hydrolysis)',
      fuelConsumption: '22 L/Hour High Speed Diesel',
      activeLocation: 'Sector 4 Plantation Block',
      operator: 'Ramesh Naidu (Certified)',
      maintenanceStatus: 'Operating Normal (Serviced 40 hrs ago)'
    },
    {
      id: 'EQ-FLT-02',
      machine: 'New Holland FR650 Biomass Harvester',
      type: 'Heavy Forage Harvester',
      capacity: '45 MT/Hour',
      cuttingLength: '6 - 10 mm Shred Size',
      fuelConsumption: '24 L/Hour',
      activeLocation: 'Plant Workshop Staging Yard',
      operator: 'V. Krishna',
      maintenanceStatus: 'Standby Ready'
    },
    {
      id: 'EQ-FLT-03',
      machine: 'Kuhn LSB 1290 High-Density Square Baler',
      type: 'Paddy Straw Baling Machine',
      capacity: '25 Bales/Hour (450 kg/bale)',
      cuttingLength: 'N/A (Bale density 180 kg/m³)',
      fuelConsumption: '14 L/Hour',
      activeLocation: 'Nandyal Paddy Cluster',
      operator: 'Anand Kumar',
      maintenanceStatus: 'Operating Normal'
    },
    {
      id: 'EQ-FLT-04',
      machine: 'Swaraj 963 FE 4WD Tractor + Silage Tipper',
      type: 'Biomass Transport Trailer (18 MT)',
      capacity: '18 MT Payload',
      cuttingLength: 'N/A',
      fuelConsumption: '8 L/Hour',
      activeLocation: 'Plant Weighbridge Transit',
      operator: 'B. Srinivas',
      maintenanceStatus: 'Active Hauling'
    }
  ];

  // 4. Silage Bunkers & Storage Reserve
  const silageBunkers = [
    {
      id: 'BNK-01',
      name: 'Primary Infeed Silage Bunker #01',
      capacityMT: 2500,
      currentStockMT: 2180,
      fillingPercent: 87,
      ensilingType: 'Lactic Acid Fermentation (pH 4.0)',
      temperatureC: 28.5,
      retentionDays: 'Fresh Feed (3 - 5 days)',
      feedstockType: 'Super Napier Chipped (<10mm)'
    },
    {
      id: 'BNK-02',
      name: 'Strategic Reserve Silage Bunker #02',
      capacityMT: 3500,
      currentStockMT: 3120,
      fillingPercent: 89,
      ensilingType: 'Vacuum Sealed EPDM Sheeting',
      temperatureC: 27.2,
      retentionDays: 'Monsoon Buffer Stock (30 - 60 days)',
      feedstockType: 'High-Density Fermented Silage'
    },
    {
      id: 'BNK-03',
      name: 'Dry Crop Residue Storage Shed #01',
      capacityMT: 1800,
      currentStockMT: 1420,
      fillingPercent: 78,
      ensilingType: 'Covered Fire-Protected Baled Stack',
      temperatureC: 31.0,
      retentionDays: 'Year-Round Carbon Buffer',
      feedstockType: 'Baled Paddy Straw (Moisture 14%)'
    }
  ];

  const handleExportCSV = () => {
    const columns = [
      { key: 'id', label: 'Harvest Batch ID' },
      { key: 'farmName', label: 'Plantation Parcel / Farm' },
      { key: 'crop', label: 'Biomass Crop' },
      { key: 'acreage', label: 'Acreage' },
      { key: 'cutNumber', label: 'Cut Number' },
      { key: 'plannedHarvestDate', label: 'Planned Date' },
      { key: 'estimatedYieldMT', label: 'Estimated Yield (MT)' },
      { key: 'actualHarvestedMT', label: 'Actual Yield (MT)' },
      { key: 'moisturePercent', label: 'Moisture (%)' },
      { key: 'assignedFleet', label: 'Machinery Fleet' },
      { key: 'status', label: 'Status' },
      { key: 'supervisor', label: 'Agronomist Lead' }
    ];
    exportToCSV('BioNova_Biomass_Harvesting_Ledger', harvestBatches, columns);
  };

  const filteredBatches = harvestBatches.filter((b) => {
    const matchesSearch =
      b.farmName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      b.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      b.crop.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCrop = cropFilter === 'ALL' || b.crop.includes(cropFilter);
    return matchesSearch && matchesCrop;
  });

  const content = (
    <div className="harvest-container">
      {/* Top Banner */}
      <div className="harvest-hero">
        <div className="harvest-hero-header">
          <div className="harvest-hero-title-group">
            <div className="harvest-pills-row">
              <span className="harvest-pill-green">
                <Wheat size={14} />
                <span>BIOMASS CULTIVATION &amp; HARVESTING OPERATIONS</span>
              </span>
              <span className="harvest-pill-teal">
                1,200 Contracted Acres
              </span>
              <span className="harvest-pill-amber">
                6 - 8 Cuts Per Year
              </span>
            </div>
            <h1>
              <span>Super Napier &amp; Agri-Residue Harvesting</span>
              <span className="harvest-plant-tag">
                {plantName}
              </span>
            </h1>
            <p>
              Precision mechanical forage harvesting, moisture-controlled ensiling, and guaranteed 180 TPD continuous
              green biomass supply to primary CSTR anaerobic digesters.
            </p>
          </div>

          <div className="harvest-hero-actions">
            <button
              onClick={() => setIsGuideOpen(!isGuideOpen)}
              className={`harvest-btn-guide ${isGuideOpen ? 'active' : ''}`}
              title="Toggle Systematic Operations Flowchart"
            >
              <BookOpen size={15} />
              <span>{isGuideOpen ? 'Close Flowchart' : '📘 Operations Flowchart'}</span>
            </button>

            <button
              onClick={handleExportCSV}
              className="harvest-btn-export"
            >
              <Download size={15} />
              <span>Export Harvest CSV</span>
            </button>

            <button
              type="button"
              onClick={() => handleOpenScheduleModal()}
              className="harvest-btn-add"
            >
              <Plus size={15} />
              <span>Schedule Harvest Cut</span>
            </button>
          </div>
        </div>

        {/* Expandable Systematic Operations Flowchart */}
        {isGuideOpen && (
          <div className="harvest-flowchart-card">
            <div className="harvest-flowchart-header">
              <div className="harvest-flowchart-title-wrap">
                <span className="harvest-flowchart-dot" />
                <h4 className="harvest-flowchart-title">
                  Field-to-Digester Biomass Lifecycle: How Harvesting Connects
                </h4>
              </div>
              <button
                onClick={() => setIsGuideOpen(false)}
                className="harvest-flowchart-close"
                aria-label="Close flowchart"
              >
                <X size={16} />
              </button>
            </div>

            <div className="harvest-flowchart-grid">
              <div className="harvest-flowchart-step">
                <span className="harvest-step-number">1. Land &amp; FPO Agronomy</span>
                <div className="harvest-step-title">1,200 Contracted Acres</div>
                <p className="harvest-step-desc">
                  Land Module registers survey parcels. Agronomists monitor ratoon cutting intervals (55–65 days).
                </p>
              </div>

              <div className="harvest-flowchart-step">
                <span className="harvest-step-number">2. Precision Harvesting</span>
                <div className="harvest-step-title">40 MT/hr Mechanical Chop</div>
                <p className="harvest-step-desc">
                  Claas &amp; New Holland harvesters shred forage to 6–10mm, accelerating enzyme digestion by 35%.
                </p>
              </div>

              <div className="harvest-flowchart-step">
                <span className="harvest-step-number">3. Gate &amp; Weighbridge</span>
                <div className="harvest-step-title">Moisture QC (65–70%)</div>
                <p className="harvest-step-desc">
                  Weighbridge logs Gross, Tare &amp; Net MT. Moisture core probes clear biomass for plant entry.
                </p>
              </div>

              <div className="harvest-flowchart-step">
                <span className="harvest-step-number">4. Silo Reserve &amp; Infeed</span>
                <div className="harvest-step-title">6,720 MT Ensiled Buffer</div>
                <p className="harvest-step-desc">
                  Daily stream goes to M-101 Macerator; buffer is packed into anaerobic lactic bunkers (pH 4.0).
                </p>
              </div>

              <div className="harvest-flowchart-step">
                <span className="harvest-step-number">5. SCADA &amp; Circular Loop</span>
                <div className="harvest-step-title">C:N Lab &amp; LFOM Return</div>
                <p className="harvest-step-desc">
                  Feeds SCADA Tab 3 &amp; 4. Digester centrate (LFOM) returns via solar drip to fertilize next crop!
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Toast Feedback Notification */}
      {feedbackMsg && (
        <div className="harvest-toast" style={{ marginBottom: "16px" }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <CheckCircle2 size={18} color="#059669" />
            <span>{feedbackMsg}</span>
          </div>
          <button
            type="button"
            onClick={() => setFeedbackMsg(null)}
            className="harvest-toast-close"
            aria-label="Dismiss message"
          >
            <X size={15} />
          </button>
        </div>
      )}

      {/* KPI Cards Row */}
      <div className="harvest-kpi-grid">
        <div className="harvest-kpi-card">
          <div className="harvest-kpi-title">
            <span>Daily Biomass Harvest</span>
            <Wheat size={16} className="harvest-icon-green" />
          </div>
          <div className="harvest-kpi-value">185 MT/Day</div>
          <span className="harvest-kpi-badge harvest-kpi-badge-green">100% meets 180 MT demand</span>
        </div>

        <div className="harvest-kpi-card">
          <div className="harvest-kpi-title">
            <span>Avg Moisture at Cut</span>
            <Droplets size={16} className="harvest-icon-blue" />
          </div>
          <div className="harvest-kpi-value">67.2%</div>
          <span className="harvest-kpi-badge harvest-kpi-badge-blue">Ideal for wet digestion</span>
        </div>

        <div className="harvest-kpi-card">
          <div className="harvest-kpi-title">
            <span>Ensiled Silage Buffer</span>
            <Layers size={16} className="harvest-icon-purple" />
          </div>
          <div className="harvest-kpi-value">6,720 MT</div>
          <span className="harvest-kpi-badge harvest-kpi-badge-purple">37 days continuous operation</span>
        </div>

        <div className="harvest-kpi-card">
          <div className="harvest-kpi-title">
            <span>Harvester Machinery Fleet</span>
            <Tractor size={16} className="harvest-icon-amber" />
          </div>
          <div className="harvest-kpi-value">4 Active Units</div>
          <span className="harvest-kpi-badge harvest-kpi-badge-amber">100% mechanical cutting</span>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: HARVESTING CYCLES                                                  */}
      {/* ========================================================================= */}
      {activeTab === 'harvest-cycles' && (
        <div className="harvest-table-wrapper">
          <div className="harvest-table-toolbar">
            <div className="harvest-toolbar-title-group">
              <Calendar size={16} className="harvest-icon-green" />
              <h3 className="harvest-toolbar-title">Harvest Batches &amp; Field Cutting Log</h3>
            </div>

            <div className="harvest-toolbar-controls">
              <div className="harvest-search-box">
                <Search size={14} className="harvest-search-icon" />
                <input
                  type="text"
                  placeholder="Search farm, crop, batch..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="harvest-search-input"
                />
              </div>

              <select
                value={cropFilter}
                onChange={(e) => setCropFilter(e.target.value)}
                className="harvest-select"
              >
                <option value="ALL">All Biomass Crops</option>
                <option value="Napier">Super Napier</option>
                <option value="Cane">Energy Cane</option>
                <option value="Straw">Paddy Straw</option>
              </select>
            </div>
          </div>

          <div className="harvest-table-container">
            <table className="harvest-table">
              <thead>
                <tr className="harvest-table-header">
                  <th>BATCH ID &amp; FARM</th>
                  <th>CROP &amp; CUT NUMBER</th>
                  <th>ACREAGE</th>
                  <th>HARVEST DATE</th>
                  <th>EST. YIELD / ACTUAL</th>
                  <th>MOISTURE (%)</th>
                  <th>STATUS</th>
                  <th>DESTINATION BUNKER</th>
                  <th style={{ textAlign: 'center', width: '90px' }}>ACTIONS</th>
                </tr>
              </thead>
              <tbody>
                {filteredBatches.map((b) => (
                  <tr key={b.id} className="harvest-table-row">
                    <td>
                      <div className="harvest-cell-primary">{b.farmName}</div>
                      <div className="harvest-cell-code-sub">{b.id} • {b.parcelId}</div>
                    </td>
                    <td>
                      <div className="harvest-cell-strong">{b.crop}</div>
                      <div className="harvest-cell-muted-sub">{b.cutNumber}</div>
                    </td>
                    <td className="harvest-cell-acreage">{b.acreage}</td>
                    <td className="harvest-cell-mono">{b.plannedHarvestDate}</td>
                    <td>
                      <div className="harvest-cell-yield">
                        {b.actualHarvestedMT > 0 ? `${b.actualHarvestedMT} MT` : `${b.estimatedYieldMT} MT (Est)`}
                      </div>
                      <div className="harvest-cell-muted-sub">Target: {b.estimatedYieldMT} MT</div>
                    </td>
                    <td className="harvest-cell-mono">
                      <span className="harvest-cell-moisture">{b.moisturePercent}%</span>
                      <div className="harvest-cell-muted-sub">{b.targetMoisture}</div>
                    </td>
                    <td>
                      <span className={`harvest-status-badge ${b.status === 'Completed'
                          ? 'harvest-status-completed'
                          : b.status === 'Harvest In-Progress'
                            ? 'harvest-status-progress'
                            : 'harvest-status-scheduled'
                        }`}>
                        {b.status}
                      </span>
                    </td>
                    <td className="harvest-cell-bunker">
                      {b.silageBunker}
                    </td>
                    <td className="harvest-actions-cell" data-label="Actions">
                      <button
                        type="button"
                        onClick={() => handleOpenEditModal(b)}
                        className="harvest-action-btn-edit"
                        title="Edit Harvest Cut"
                      >
                        <Edit3 size={13} />
                        <span>Edit</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDeleteCut(b.id)}
                        className="harvest-action-btn-delete"
                        title="Delete Harvest Cut"
                      >
                        <Trash2 size={13} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: PLANTATION BLOCKS                                                  */}
      {/* ========================================================================= */}
      {activeTab === 'plantation-parcels' && (
        <div className="harvest-parcels-grid">
          {plantationParcels.map((p) => (
            <div key={p.id} className="parcel-card">
              <div className="harvest-card-top-row">
                <span className="parcel-id-chip">
                  {p.id}
                </span>
                <span className="parcel-area-badge">{p.areaAcres} Acres</span>
              </div>

              <div>
                <h4 className="harvest-card-title">{p.name}</h4>
                <div className="harvest-card-subtitle">{p.variety}</div>
              </div>

              <div className="harvest-kv-list">
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Cutting Cycle:</span>
                  <span className="harvest-kv-val">Every {p.cuttingIntervalDays} Days</span>
                </div>
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Annual Biomass Yield:</span>
                  <span className="harvest-kv-val-green">{p.annualYieldMT}</span>
                </div>
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Soil pH:</span>
                  <span className="harvest-kv-val-mono">{p.soilHealthPH} (Optimal Neutral)</span>
                </div>
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Fertigation Closed-Loop:</span>
                  <span className="harvest-kv-val-blue">{p.fertigationSource}</span>
                </div>
              </div>

              <div className="parcel-contract-box">
                <strong>Contract:</strong> {p.farmerContract}
              </div>

              <button
                type="button"
                onClick={() => handleOpenScheduleModal(p)}
                style={{
                  marginTop: '12px',
                  width: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #bfdbfe',
                  background: '#eff6ff',
                  color: '#1d4ed8',
                  fontSize: '12px',
                  fontWeight: '600',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease'
                }}
              >
                <Plus size={14} />
                <span>Schedule Harvest for this Block</span>
              </button>
            </div>
          ))}
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 3: MACHINERY FLEET                                                    */}
      {/* ========================================================================= */}
      {activeTab === 'machinery-fleet' && (
        <div className="harvest-fleet-grid">
          {machineryFleet.map((m) => (
            <div key={m.id} className="fleet-card">
              <div className="harvest-card-top-row">
                <span className="fleet-id-text">{m.id}</span>
                <span className="fleet-status-pill">
                  {m.maintenanceStatus}
                </span>
              </div>

              <div>
                <h4 className="harvest-card-title-lg">{m.machine}</h4>
                <div className="harvest-card-subtitle">{m.type}</div>
              </div>

              <div className="fleet-telemetry-strip">
                <div className="fleet-telemetry-item">
                  <span className="fleet-telemetry-label">Harvesting Capacity</span>
                  <span className="fleet-telemetry-val">{m.capacity}</span>
                </div>
                <div className="fleet-telemetry-item">
                  <span className="fleet-telemetry-label">Chop Length</span>
                  <span className="fleet-telemetry-val-green">{m.cuttingLength}</span>
                </div>
                <div className="fleet-telemetry-item">
                  <span className="fleet-telemetry-label">Assigned Operator</span>
                  <span className="fleet-telemetry-val">{m.operator}</span>
                </div>
                <div className="fleet-telemetry-item">
                  <span className="fleet-telemetry-label">Current Location</span>
                  <span className="fleet-telemetry-val">{m.activeLocation}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 4: SILAGE BUNKERS & ENSILING                                          */}
      {/* ========================================================================= */}
      {activeTab === 'silage-bunkers' && (
        <div className="harvest-bunkers-grid">
          {silageBunkers.map((b) => (
            <div key={b.id} className="bunker-card">
              <div className="harvest-card-top-row">
                <span className="bunker-id-badge">
                  {b.id}
                </span>
                <span className="bunker-capacity-text">{b.fillingPercent}% Capacity</span>
              </div>

              <div>
                <h4 className="harvest-card-title">{b.name}</h4>
                <div className="harvest-card-subtitle">{b.feedstockType}</div>
              </div>

              {/* Capacity Progress Bar */}
              <div className="bunker-progress-track">
                <div
                  className={`bunker-progress-fill ${b.fillingPercent > 85 ? 'fill-high' : b.fillingPercent < 50 ? 'fill-warning' : 'fill-optimal'}`}
                  style={{ width: `${b.fillingPercent}%` }}
                ></div>
              </div>

              <div className="harvest-kv-list">
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Current Biomass Stock:</span>
                  <span className="harvest-kv-val-mono">{b.currentStockMT.toLocaleString()} MT / {b.capacityMT.toLocaleString()} MT</span>
                </div>
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Ensiling Preservation:</span>
                  <span className="harvest-kv-val-green">{b.ensilingType}</span>
                </div>
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Core Bunker Temp:</span>
                  <span className="harvest-kv-val-mono">{b.temperatureC}°C (Anaerobic Active)</span>
                </div>
                <div className="harvest-kv-row">
                  <span className="harvest-kv-label">Feedstock Security:</span>
                  <span className="harvest-kv-val-purple">{b.retentionDays}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL: SCHEDULE / EDIT HARVEST CUT                                        */}
      {/* ========================================================================= */}
      {isScheduleModalOpen && (
        <div className="harvest-modal-overlay" onClick={() => setIsScheduleModalOpen(false)}>
          <div
            className="harvest-modal"
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-modal="true"
          >
            <div className="harvest-modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Wheat size={20} color="#60a5fa" />
                <div>
                  <h3 style={{ margin: 0, fontSize: '17px', fontWeight: '700', color: '#ffffff' }}>
                    {editingCutId ? `Edit Harvest Cut — ${editingCutId}` : 'Schedule Biomass Harvest Cut'}
                  </h3>
                  <div style={{ fontSize: '11px', color: '#93c5fd', marginTop: '2px' }}>
                    Coordinate precision forage harvesting fleet, moisture targets, and silage bunkers
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsScheduleModalOpen(false)}
                className="harvest-flowchart-close"
                style={{ color: '#ffffff', background: 'rgba(255,255,255,0.1)' }}
                aria-label="Close modal"
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={handleSaveHarvestCut} style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0 }}>
              <div className="harvest-modal-body">
                {/* Section 1: Plantation & Crop Identification */}
                <div className="harvest-form-section">
                  <h4 className="harvest-form-section-title">
                    <MapPin size={15} color="#2563eb" />
                    <span>1. Plantation Parcel &amp; Crop Specification</span>
                  </h4>

                  <div className="harvest-form-grid harvest-form-grid-3">
                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Batch Identifier</label>
                      <input
                        type="text"
                        value={formData.id}
                        disabled
                        className="harvest-form-input"
                        style={{ background: '#f1f5f9', cursor: 'not-allowed', fontWeight: 600 }}
                      />
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Plantation Parcel <span style={{ color: '#ef4444' }}>*</span></label>
                      <select
                        value={formData.parcelId}
                        onChange={(e) => {
                          const parcel = plantationParcels.find(p => p.id === e.target.value);
                          if (parcel) {
                            handleFormChange('parcelId', parcel.id);
                            handleFormChange('farmName', parcel.name);
                          } else {
                            handleFormChange('parcelId', e.target.value);
                          }
                        }}
                        className="harvest-form-select"
                        required
                      >
                        {plantationParcels.map(p => (
                          <option key={p.id} value={p.id}>
                            {p.id} — {p.name} ({p.areaAcres} Ac)
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Biomass Crop Variety <span style={{ color: '#ef4444' }}>*</span></label>
                      <select
                        value={formData.crop}
                        onChange={(e) => handleFormChange('crop', e.target.value)}
                        className="harvest-form-select"
                        required
                      >
                        <option value="Super Napier (CO-5 High Sugar)">Super Napier (CO-5 High Sugar)</option>
                        <option value="Super Napier (Pakchong-1)">Super Napier (Pakchong-1)</option>
                        <option value="Energy Cane (High Fiber Biomass)">Energy Cane (High Fiber)</option>
                        <option value="Paddy / Rice Straw (Dry Baled)">Paddy / Rice Straw (Dry Baled)</option>
                      </select>
                    </div>
                  </div>

                  <div className="harvest-form-grid harvest-form-grid-3" style={{ marginTop: '12px' }}>
                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Acreage to Cut (Acres) <span style={{ color: '#ef4444' }}>*</span></label>
                      <input
                        type="number"
                        min="1"
                        max="500"
                        value={formData.acreage}
                        onChange={(e) => handleFormChange('acreage', e.target.value)}
                        className="harvest-form-input"
                        placeholder="e.g. 40"
                        required
                      />
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Cut / Ratoon Cycle</label>
                      <select
                        value={formData.cutNumber}
                        onChange={(e) => handleFormChange('cutNumber', e.target.value)}
                        className="harvest-form-select"
                      >
                        <option value="Cut #1 of 7">Cut #1 of 7 (Virgin Harvest)</option>
                        <option value="Cut #2 of 7">Cut #2 of 7 (Ratoon 1)</option>
                        <option value="Cut #3 of 7">Cut #3 of 7 (Ratoon 2)</option>
                        <option value="Cut #4 of 7">Cut #4 of 7 (Peak Yield)</option>
                        <option value="Cut #5 of 7">Cut #5 of 7 (Ratoon 4)</option>
                        <option value="Cut #6 of 7">Cut #6 of 7 (Ratoon 5)</option>
                        <option value="Cut #7 of 7">Cut #7 of 7 (Final Ratoon)</option>
                        <option value="Post-Harvest Baling">Post-Harvest Straw Baling</option>
                      </select>
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Scheduled Harvest Date <span style={{ color: '#ef4444' }}>*</span></label>
                      <input
                        type="date"
                        value={formData.plannedHarvestDate}
                        onChange={(e) => handleFormChange('plannedHarvestDate', e.target.value)}
                        className="harvest-form-input"
                        required
                      />
                    </div>
                  </div>
                </div>

                {/* Section 2: Yield Estimation & Moisture Parameters */}
                <div className="harvest-form-section">
                  <h4 className="harvest-form-section-title">
                    <TrendingUp size={15} color="#059669" />
                    <span>2. Yield Projections &amp; Ensiling Moisture Targets</span>
                  </h4>

                  <div className="harvest-form-grid harvest-form-grid-3">
                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Estimated Yield (MT)</label>
                      <input
                        type="number"
                        value={formData.estimatedYieldMT}
                        onChange={(e) => handleFormChange('estimatedYieldMT', e.target.value)}
                        className="harvest-form-input"
                        placeholder="Auto calculated"
                      />
                      <span className="harvest-form-hint">
                        ~8 MT/Ac for Green Napier, ~2.5 MT/Ac for Dry Straw
                      </span>
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Target Moisture Range</label>
                      <input
                        type="text"
                        value={formData.targetMoisture}
                        onChange={(e) => handleFormChange('targetMoisture', e.target.value)}
                        className="harvest-form-input"
                        placeholder="e.g. 65 - 70%"
                      />
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Cut Moisture (%)</label>
                      <input
                        type="number"
                        step="0.1"
                        value={formData.moisturePercent}
                        onChange={(e) => handleFormChange('moisturePercent', e.target.value)}
                        className="harvest-form-input"
                        placeholder="e.g. 67.5"
                      />
                    </div>
                  </div>

                  {editingCutId && (
                    <div className="harvest-form-grid harvest-form-grid-2" style={{ marginTop: '12px' }}>
                      <div className="harvest-form-group">
                        <label className="harvest-form-label">Actual Harvested Biomass (MT)</label>
                        <input
                          type="number"
                          value={formData.actualHarvestedMT}
                          onChange={(e) => handleFormChange('actualHarvestedMT', e.target.value)}
                          className="harvest-form-input"
                          placeholder="e.g. 352"
                        />
                      </div>
                      <div className="harvest-form-group">
                        <label className="harvest-form-label">Operational Status</label>
                        <select
                          value={formData.status}
                          onChange={(e) => handleFormChange('status', e.target.value)}
                          className="harvest-form-select"
                        >
                          <option value="Scheduled">Scheduled</option>
                          <option value="Harvest In-Progress">Harvest In-Progress</option>
                          <option value="Completed">Completed</option>
                        </select>
                      </div>
                    </div>
                  )}
                </div>

                {/* Section 3: Machinery Dispatch & Destination Bunker */}
                <div className="harvest-form-section">
                  <h4 className="harvest-form-section-title">
                    <Tractor size={15} color="#d97706" />
                    <span>3. Harvester Fleet Dispatch &amp; Silage Bunker Allocation</span>
                  </h4>

                  <div className="harvest-form-grid harvest-form-grid-3">
                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Assigned Machinery Fleet <span style={{ color: '#ef4444' }}>*</span></label>
                      <select
                        value={formData.assignedFleet}
                        onChange={(e) => handleFormChange('assignedFleet', e.target.value)}
                        className="harvest-form-select"
                        required
                      >
                        {machineryFleet.map(m => (
                          <option key={m.id} value={`${m.machine} (${m.type})`}>
                            {m.id} — {m.machine} ({m.capacity})
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Destination Silage Bunker <span style={{ color: '#ef4444' }}>*</span></label>
                      <select
                        value={formData.silageBunker}
                        onChange={(e) => handleFormChange('silageBunker', e.target.value)}
                        className="harvest-form-select"
                        required
                      >
                        {silageBunkers.map(b => (
                          <option key={b.id} value={`${b.name} (${b.ensilingType})`}>
                            {b.id} — {b.name} ({b.fillingPercent}% Full)
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="harvest-form-group">
                      <label className="harvest-form-label">Lead Agronomist / Supervisor</label>
                      <input
                        type="text"
                        value={formData.supervisor}
                        onChange={(e) => handleFormChange('supervisor', e.target.value)}
                        className="harvest-form-input"
                        placeholder="e.g. K. Somanna (Agronomist)"
                      />
                    </div>
                  </div>

                  <div className="harvest-form-group" style={{ marginTop: '12px' }}>
                    <label className="harvest-form-label">Field Execution &amp; Weather Notes</label>
                    <textarea
                      rows={2}
                      value={formData.notes}
                      onChange={(e) => handleFormChange('notes', e.target.value)}
                      className="harvest-form-textarea"
                      placeholder="e.g. Soil condition optimal, chop length set to 15-20mm for digester high surface area ensiling..."
                    />
                  </div>
                </div>
              </div>

              <div className="harvest-modal-footer">
                <button
                  type="button"
                  onClick={() => setIsScheduleModalOpen(false)}
                  className="harvest-btn-cancel"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="harvest-btn-submit"
                >
                  <Save size={15} />
                  <span>{editingCutId ? 'Update Harvest Schedule' : 'Confirm & Dispatch Harvest Cut'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );

  if (standalone === false) {
    return content;
  }

  return (
    <div className="sco-container" style={{ display: "flex", minHeight: "100vh", background: "#f8fafc" }}>
      <Sidebar userRole={userRole} onLogout={onLogout} />
      <div className="sco-main" style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, minHeight: "100vh" }}>
        <Header title="Biomass Harvesting Operations" onLogout={onLogout} />
        <div style={{ flex: 1, width: "100%", overflowY: "auto" }}>
          {content}
        </div>
      </div>
    </div>
  );
}

