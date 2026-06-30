import React, { useState } from 'react';
import Sidebar from '../Sidebar';
import Header from '../Header';
import { Search, Filter, Check, ShieldAlert, Folder, Shield, ArrowRight, Save, RotateCcw, Plus, X, Eye, Info, ChevronDown, ChevronRight, FileText, Minus, Users } from 'lucide-react';
import '../../styles/AssignAcess.css';

const AssignAccess = ({ userRole, onLogout }) => {
  const [currentStep, setCurrentStep] = useState(1);

  // --- Dummy Data ---
  const employees = [
    { id: 1, code: 'EMP1001', name: 'Sairam Vempati', role: 'Senior Project Manager', email: 'sairam.v@atirath.com', initials: 'SV' },
    { id: 2, code: 'EMP1002', name: 'Praneeth Reddy', role: 'Project Manager', email: 'praneeth.r@atirath.com', initials: 'PR' },
    { id: 3, code: 'EMP1003', name: 'Anusha Devi', role: 'Project Coordinator', email: 'anusha.d@atirath.com', initials: 'AD' },
    { id: 4, code: 'EMP1004', name: 'Rahul Kumar', role: 'Planning Engineer', email: 'rahul.k@atirath.com', initials: 'RK' },
    { id: 5, code: 'EMP1005', name: 'Kavya Reddy', role: 'QA Engineer', email: 'kavya.r@atirath.com', initials: 'KR' },
  ];

  const templates = [
    { id: 1, code: 'PMGR-001', name: 'Project Manager Template', desc: 'Provides project planning, execution and monitoring related access including reports.' },
    { id: 2, code: 'SITE-001', name: 'Site Engineer Template', desc: 'Provides site level data entry and issue tracking permissions.' },
  ];

  const [selectedEmployees, setSelectedEmployees] = useState([1, 2, 3, 4, 5]);
  const [selectedTemplate, setSelectedTemplate] = useState(1);
  const [expandedGroups, setExpandedGroups] = useState({ 1: true });

  const toggleGroup = (id) => {
    setExpandedGroups(prev => ({
      ...prev,
      [id]: !prev[id]
    }));
  };

  const initialGroups = [
    {
      id: 1, name: "Company Master", screens: [
        { name: "Admin Dashboard", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Company Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Plant Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Land Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Employee Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Department Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Department Mapping", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" }
      ], view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed"
    },
    {
      id: 2, name: "Project", screens: [
        { name: "Project Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Milestone Creation", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Project Dashboard", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Project List", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Individual Task", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" }
      ], view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed"
    },
    {
      id: 3, name: "User", screens: [
        { name: "User Dashboard", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "My Task", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Task Board", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Calendar", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "My Project", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" }
      ], view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed"
    },
    {
      id: 4, name: "Other Settings", screens: [
        { name: "Public Holidays", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Assign Access", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Profile", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" },
        { name: "Settings", view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed" }
      ], view: "empty", create: "empty", edit: "empty", delete: "empty", badge: "orange", badgeText: "Mixed"
    }
  ];

  const [accessGroups, setAccessGroups] = useState(initialGroups);

  const togglePermission = (groupId, screenIndex, permissionType, e) => {
    if (e) e.stopPropagation();
    setAccessGroups(prev => {
      const newGroups = [...prev];
      const groupIndex = newGroups.findIndex(g => g.id === groupId);
      if (groupIndex === -1) return prev;
      
      const updatedGroup = { ...newGroups[groupIndex] };
      const updatedScreens = [...updatedGroup.screens];
      const screen = { ...updatedScreens[screenIndex] };
      
      screen[permissionType] = screen[permissionType] === 'empty' ? 'green' : 'empty';
      
      const hasGreen = ['view', 'create', 'edit', 'delete'].some(p => screen[p] === 'green' || screen[p] === 'blue');
      screen.badge = hasGreen ? 'green' : 'orange';
      screen.badgeText = hasGreen ? 'Extra Added' : 'Mixed';
      
      updatedScreens[screenIndex] = screen;
      updatedGroup.screens = updatedScreens;
      newGroups[groupIndex] = updatedGroup;
      
      return newGroups;
    });
  };

  const toggleGroupPermission = (groupId, permissionType, e) => {
    if (e) e.stopPropagation();
    setAccessGroups(prev => {
      const newGroups = [...prev];
      const groupIndex = newGroups.findIndex(g => g.id === groupId);
      if (groupIndex === -1) return prev;
      
      const updatedGroup = { ...newGroups[groupIndex] };
      const targetState = updatedGroup[permissionType] === 'empty' ? 'green' : 'empty';
      updatedGroup[permissionType] = targetState;
      
      const updatedScreens = updatedGroup.screens.map(screen => ({
        ...screen,
        [permissionType]: targetState,
        badge: targetState === 'green' ? 'green' : 'orange',
        badgeText: targetState === 'green' ? 'Extra Added' : 'Mixed'
      }));
      
      updatedGroup.screens = updatedScreens;
      newGroups[groupIndex] = updatedGroup;
      
      return newGroups;
    });
  };

  const renderCheckbox = (type) => {
    switch(type) {
      case 'blue': return <div className="aa-chk aa-chk-blue"><Check size={12} strokeWidth={3}/></div>;
      case 'green': return <div className="aa-chk aa-chk-green"><Check size={12} strokeWidth={3}/></div>;
      case 'red': return <div className="aa-chk aa-chk-red"><Check size={12} strokeWidth={3}/></div>;
      case 'red-x': return <div className="aa-chk aa-chk-red"><X size={12} strokeWidth={3}/></div>;
      case 'red-minus': return <div className="aa-chk aa-chk-red"><Minus size={12} strokeWidth={3}/></div>;
      case 'mixed': return <div className="aa-chk aa-chk-mixed"><Minus size={12} strokeWidth={3}/></div>;
      case 'empty': return <div className="aa-chk aa-chk-empty"></div>;
      default: return <div className="aa-chk aa-chk-empty"></div>;
    }
  };

  const steps = [
    { num: 1, title: 'Select Employees', desc: 'Choose employees' },
    { num: 2, title: 'Assign from Templates', desc: 'Select template (Optional)' },
    { num: 3, title: 'Manage Access', desc: 'Add / Revoke access by group' },
    { num: 4, title: 'Preview Access', desc: 'Review final access' },
    { num: 5, title: 'Access Summary', desc: 'Summary of access' },
  ];

  const handleNext = () => {
    if (currentStep < 5) setCurrentStep(prev => prev + 1);
  };

  const handlePrev = () => {
    if (currentStep > 1) setCurrentStep(prev => prev - 1);
  };

  const toggleEmployee = (id) => {
    setSelectedEmployees(prev => 
      prev.includes(id) ? prev.filter(e => e !== id) : [...prev, id]
    );
  };

  const renderStepper = () => (
    <div className="aa-stepper">
      {steps.map((step, index) => {
        const isActive = currentStep === step.num;
        const isCompleted = currentStep > step.num;
        
        return (
          <div key={step.num} className={`aa-step-wrapper ${isCompleted ? 'completed' : ''}`}>
            <div className={`aa-step ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}`}>
              <div className="aa-step-circle">
                {isCompleted ? <Check size={16} /> : step.num}
              </div>
              <div className="aa-step-info">
                <h4>{step.title}</h4>
                <p>{step.desc}</p>
              </div>
            </div>
            {index < steps.length - 1 && <div className="aa-step-connector"></div>}
          </div>
        );
      })}
    </div>
  );

  const renderStep1 = () => (
    <div className="aa-step-content">
      <div className="aa-step-header">
        <h3>Step - 1 : Select Employees (Multiple)</h3>
      </div>
      
      <div className="aa-search-bar">
        <Search className="aa-search-icon" size={18} />
        <input type="text" placeholder="Search by name, code, email..." />
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
        <strong style={{ fontSize: '13px', color: '#1e293b' }}>Selected Employees ({selectedEmployees.length})</strong>
        <span style={{ fontSize: '13px', color: '#ef4444', cursor: 'pointer', fontWeight: 600 }} onClick={() => setSelectedEmployees([])}>Clear All</span>
      </div>

      <div className="aa-list">
        {employees.map(emp => (
          <div key={emp.id} className={`aa-list-item ${selectedEmployees.includes(emp.id) ? 'selected' : ''}`} onClick={() => toggleEmployee(emp.id)}>
            <input 
              type="checkbox" 
              className="aa-checkbox"
              checked={selectedEmployees.includes(emp.id)} 
              onChange={() => {}} 
            />
            <div className="aa-avatar">{emp.initials}</div>
            <div className="aa-info">
              <h5>{emp.code} - {emp.name}</h5>
              <p>{emp.role} | {emp.email}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderStep2 = () => {
    const activeTemplate = templates.find(t => t.id === selectedTemplate);
    return (
    <div className="aa-step-content">
      <div className="aa-step-header">
        <h3 style={{ color: '#2563eb' }}>Step - 2 : Assign from Templates (Single)</h3>
      </div>
      
      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px' }}>
        <div className="aa-search-bar" style={{ flex: 1, marginBottom: 0 }}>
          <Search className="aa-search-icon" size={18} />
          <input type="text" placeholder="Search template..." />
        </div>
        <button style={{ width: '42px', height: '42px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'white', border: '1px solid #cbd5e1', borderRadius: '6px', color: '#1e293b', cursor: 'pointer', flexShrink: 0 }}>
          <Filter size={18} />
        </button>
      </div>

      <div style={{ marginBottom: '12px' }}>
        <strong style={{ fontSize: '13px', color: '#1e293b' }}>Select Template <span style={{color: '#ef4444'}}>*</span></strong>
      </div>

      {activeTemplate ? (
        <>
          <div style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '8px', padding: '16px', position: 'relative', marginBottom: '16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <h5 style={{ margin: '0 0 4px 0', fontSize: '14px', color: '#1e293b', fontWeight: 700 }}>{activeTemplate.name}</h5>
                <p style={{ margin: '0 0 12px 0', fontSize: '12px', color: '#64748b', fontWeight: 600 }}>{activeTemplate.code}</p>
              </div>
              <X size={18} color="#475569" style={{ cursor: 'pointer' }} onClick={() => setSelectedTemplate(null)} />
            </div>
            <p style={{ margin: 0, fontSize: '13px', color: '#475569', lineHeight: '1.5' }}>
              {activeTemplate.desc}
            </p>
          </div>
          
          <button style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', background: 'white', border: '1px solid #e2e8f0', padding: '8px 16px', borderRadius: '6px', color: '#2563eb', fontWeight: 700, fontSize: '13px', cursor: 'pointer', marginBottom: '24px' }}>
            <Eye size={18} strokeWidth={2.5} /> View Template
          </button>

          <div style={{ padding: '16px', background: '#f4f7ff', borderRadius: '8px', border: '1px solid #e0e7ff', display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
            <Info size={18} color="#2563eb" style={{ marginTop: '2px', minWidth: '18px' }} />
            <p style={{ margin: 0, fontSize: '13px', color: '#1e3a8a', lineHeight: '1.5' }}>
              Permissions from this template will be applied to the selected employees. You can add extra access or revoke any access in the next step.
            </p>
          </div>
        </>
      ) : (
        <div className="aa-list">
          {templates.map(tpl => (
            <div key={tpl.id} className="aa-list-item" onClick={() => setSelectedTemplate(tpl.id)}>
              <div className="aa-info">
                <h5>{tpl.name}</h5>
                <p style={{ color: '#2563eb', fontWeight: 600, fontSize: '11px', marginBottom: '4px' }}>{tpl.code}</p>
                <p>{tpl.desc}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )};

  const renderStep3 = () => (
    <div className="aa-step-content">
      <div className="aa-step-header">
        <h3 style={{ color: '#2563eb' }}>Step - 3 : Manage Access by Group (Add / Revoke)</h3>
        <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#64748b' }}>Expand a group to manage access for individual screens. Group level permissions can be overridden.</p>
      </div>
      
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div style={{ display: 'flex', gap: '16px', fontSize: '13px', fontWeight: 700, border: '1px solid #e2e8f0', padding: '12px 16px', borderRadius: '8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#2563eb' }}>
            <div className="aa-chk aa-chk-blue"><Check size={12} strokeWidth={3} /></div> From Template
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#1e293b' }}>
            <div className="aa-chk aa-chk-green"><Check size={12} strokeWidth={3} /></div> Extra Added
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#1e293b' }}>
            <div className="aa-chk aa-chk-red"><X size={12} strokeWidth={3} /></div> Revoked
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#1e293b' }}>
            <div className="aa-chk" style={{ background: '#f59e0b', border: '1px solid #f59e0b', color: 'white' }}><X size={12} strokeWidth={3} /></div> Mixed
          </div>
        </div>
        <button className="aa-btn-outline" style={{ display: 'flex', alignItems: 'center', gap: '6px', height: 'fit-content' }}>
          <Filter size={16} /> Filter
        </button>
      </div>

      <div className="aa-table-container">
        <table className="aa-table aa-access-table">
          <thead>
            <tr>
              <th width="32%">Group / Screen</th>
              <th width="10%" style={{textAlign: 'center'}}>Screens</th>
              <th width="10%" style={{textAlign: 'center'}}>View</th>
              <th width="10%" style={{textAlign: 'center'}}>Create</th>
              <th width="10%" style={{textAlign: 'center'}}>Edit</th>
              <th width="10%" style={{textAlign: 'center'}}>Delete</th>
              <th width="18%" style={{textAlign: 'center'}}>Access Type</th>
            </tr>
          </thead>
          <tbody>
            {accessGroups.map((group) => {
              const isExpanded = expandedGroups[group.id];
              return (
                <React.Fragment key={group.id}>
                  {/* Group Row */}
                  <tr style={{ background: isExpanded ? '#f8fafc' : 'transparent', cursor: 'pointer' }} onClick={() => toggleGroup(group.id)}>
                    <td style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: '12px', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0' }}>
                      {isExpanded ? <ChevronDown size={18} color="#475569" /> : <ChevronRight size={18} color="#475569" />}
                      <div style={{ width: 16, height: 16, background: isExpanded ? '#f59e0b' : 'transparent', borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center', color: isExpanded ? 'white' : '#334155', fontSize: isExpanded ? 10 : 13, fontWeight: 'bold' }}>{isExpanded ? '1' : group.id}</div>
                      <Folder size={16} color="#f59e0b" fill="#f59e0b" /> {group.name}
                    </td>
                    <td style={{textAlign: 'center', fontWeight: 600, borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0'}}>{group.screens.length}</td>
                    <td style={{textAlign: 'center', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0', cursor: 'pointer'}} onClick={(e) => toggleGroupPermission(group.id, 'view', e)}>{renderCheckbox(group.view)}</td>
                    <td style={{textAlign: 'center', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0', cursor: 'pointer'}} onClick={(e) => toggleGroupPermission(group.id, 'create', e)}>{renderCheckbox(group.create)}</td>
                    <td style={{textAlign: 'center', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0', cursor: 'pointer'}} onClick={(e) => toggleGroupPermission(group.id, 'edit', e)}>{renderCheckbox(group.edit)}</td>
                    <td style={{textAlign: 'center', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0', cursor: 'pointer'}} onClick={(e) => toggleGroupPermission(group.id, 'delete', e)}>{renderCheckbox(group.delete)}</td>
                    <td style={{textAlign: 'center', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0'}}><span className={`aa-badge aa-badge-${group.badge}`}>{group.badgeText}</span></td>
                  </tr>

                  {/* Sub-items (Screens) */}
                  {isExpanded && group.screens.map((screen, idx) => {
                    const isLast = idx === group.screens.length - 1;
                    return (
                      <tr key={idx} style={{ background: '#f8fafc' }}>
                        <td style={{ paddingLeft: '54px', display: 'flex', alignItems: 'center', gap: '10px', color: '#334155', borderBottom: isLast ? '1px solid #e2e8f0' : 'none' }}>
                          <FileText size={16} color="#94a3b8" /> {screen.name}
                        </td>
                        <td style={{borderBottom: isLast ? '1px solid #e2e8f0' : 'none'}}></td>
                        <td style={{textAlign: 'center', borderBottom: isLast ? '1px solid #e2e8f0' : 'none', cursor: 'pointer'}} onClick={(e) => togglePermission(group.id, idx, 'view', e)}>{renderCheckbox(screen.view)}</td>
                        <td style={{textAlign: 'center', borderBottom: isLast ? '1px solid #e2e8f0' : 'none', cursor: 'pointer'}} onClick={(e) => togglePermission(group.id, idx, 'create', e)}>{renderCheckbox(screen.create)}</td>
                        <td style={{textAlign: 'center', borderBottom: isLast ? '1px solid #e2e8f0' : 'none', cursor: 'pointer'}} onClick={(e) => togglePermission(group.id, idx, 'edit', e)}>{renderCheckbox(screen.edit)}</td>
                        <td style={{textAlign: 'center', borderBottom: isLast ? '1px solid #e2e8f0' : 'none', cursor: 'pointer'}} onClick={(e) => togglePermission(group.id, idx, 'delete', e)}>{renderCheckbox(screen.delete)}</td>
                        <td style={{textAlign: 'center', borderBottom: isLast ? '1px solid #e2e8f0' : 'none'}}><span className={`aa-badge aa-badge-${screen.badge}`}>{screen.badgeText}</span></td>
                      </tr>
                    );
                  })}
                </React.Fragment>
              );
            })}
          </tbody>
        </table>
      </div>

      <div style={{ marginTop: '24px', background: '#eff6ff', borderRadius: '8px', padding: '16px', display: 'flex', flexWrap: 'wrap', gap: '24px', border: '1px solid #bfdbfe' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#475569' }}>
          <div className="aa-chk aa-chk-blue"><Check size={12} strokeWidth={3} /></div>
          <strong>From Template:</strong> Access inherited from selected template
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#475569' }}>
          <div className="aa-chk aa-chk-green"><Check size={12} strokeWidth={3} /></div>
          <strong>Extra Added:</strong> Additional access given
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#475569' }}>
          <div className="aa-chk aa-chk-red"><X size={12} strokeWidth={3} /></div>
          <strong>Revoked:</strong> Access removed from template
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#475569' }}>
          <div className="aa-chk" style={{ background: '#f59e0b', border: '1px solid #f59e0b', color: 'white' }}><X size={12} strokeWidth={3} /></div>
          <strong>Mixed:</strong> Some screens in this group are customized
        </div>
      </div>
    </div>
  );

  const renderPreviewIcon = (state) => {
    if (state === 'green' || state === 'blue') {
      return <div style={{ width: 16, height: 16, background: '#10b981', borderRadius: 3, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto', color: 'white' }}><Check size={12} strokeWidth={3}/></div>;
    } else {
      return <div style={{ width: 16, height: 16, background: '#ef4444', borderRadius: 3, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto', color: 'white' }}><X size={12} strokeWidth={3}/></div>;
    }
  };

  const getGroupSource = (group) => {
    const hasGreen = group.screens.some(s => ['view', 'create', 'edit', 'delete'].some(p => s[p] === 'green'));
    const hasBlue = group.screens.some(s => ['view', 'create', 'edit', 'delete'].some(p => s[p] === 'blue'));
    
    if (hasGreen && hasBlue) return { text: 'Mixed', color: 'orange' };
    if (hasGreen) return { text: 'Extra', color: 'green' };
    if (hasBlue) return { text: 'Template', color: 'blue' };
    return { text: 'Revoked', color: 'red' };
  };

  const renderStep4 = () => (
    <div className="aa-step-content">
      <div className="aa-step-header" style={{ display: 'flex', justifyContent: 'space-between' }}>
        <div>
          <h3 style={{ color: '#2563eb' }}>Step - 4 : Preview Access</h3>
          <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#64748b' }}>Preview effective permissions that will be available to the selected employees.</p>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '12px', marginTop: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', background: 'white', border: '1px solid #e2e8f0', borderRadius: '6px', padding: '0 12px', flex: 1 }}>
          <Search size={16} color="#94a3b8" />
          <input type="text" placeholder="Search group or screen..." style={{ border: 'none', padding: '10px', width: '100%', outline: 'none', fontSize: '13px' }} />
        </div>
        <button className="aa-btn aa-btn-secondary" style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '0 16px', borderRadius: '6px', border: '1px solid #e2e8f0', background: 'white', cursor: 'pointer', fontWeight: 600 }}>
          <Filter size={16} /> Filter
        </button>
      </div>

      <div className="aa-table-container" style={{ marginTop: '16px', border: '1px solid #e2e8f0', borderRadius: '8px', overflow: 'hidden' }}>
        <table className="aa-table" style={{ margin: 0 }}>
          <thead style={{ background: '#f8fafc' }}>
            <tr>
              <th width="35%" style={{ padding: '12px 16px' }}>Group / Screen</th>
              <th width="13%" style={{textAlign: 'center', padding: '12px 16px'}}>View</th>
              <th width="13%" style={{textAlign: 'center', padding: '12px 16px'}}>Create</th>
              <th width="13%" style={{textAlign: 'center', padding: '12px 16px'}}>Edit</th>
              <th width="13%" style={{textAlign: 'center', padding: '12px 16px'}}>Delete</th>
              <th width="13%" style={{textAlign: 'center', padding: '12px 16px'}}>Source</th>
            </tr>
          </thead>
          <tbody>
            {accessGroups.map((group, idx) => {
              const viewState = group.screens.some(s => s.view !== 'empty') ? 'green' : 'empty';
              const createState = group.screens.some(s => s.create !== 'empty') ? 'green' : 'empty';
              const editState = group.screens.some(s => s.edit !== 'empty') ? 'green' : 'empty';
              const deleteState = group.screens.some(s => s.delete !== 'empty') ? 'green' : 'empty';
              const source = getGroupSource(group);

              const isExpanded = expandedGroups[group.id];

              return (
                <React.Fragment key={group.id}>
                  <tr style={{ background: 'white', cursor: 'pointer' }} onClick={() => toggleGroup(group.id)}>
                    <td style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '12px', padding: '14px 16px', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0' }}>
                      {isExpanded ? <ChevronDown size={14} color="#475569" strokeWidth={3} /> : <ChevronRight size={14} color="#475569" strokeWidth={3} />}
                      <span style={{ fontSize: '13px', fontWeight: 600, color: '#334155' }}>{idx + 1}</span>
                      <Folder size={14} color="#475569" strokeWidth={2} /> {group.name} <span style={{ color: '#64748b', fontWeight: 500 }}>({group.screens.length} Screens)</span>
                    </td>
                    <td style={{ borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0' }}>{renderPreviewIcon(viewState)}</td>
                    <td style={{ borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0' }}>{renderPreviewIcon(createState)}</td>
                    <td style={{ borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0' }}>{renderPreviewIcon(editState)}</td>
                    <td style={{ borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0' }}>{renderPreviewIcon(deleteState)}</td>
                    <td style={{textAlign: 'center', borderBottom: isExpanded ? 'none' : '1px solid #e2e8f0'}}><span className={`aa-badge aa-badge-${source.color}`}>{source.text}</span></td>
                  </tr>

                  {isExpanded && group.screens.map((screen, sIdx) => {
                    const hasGreen = ['view', 'create', 'edit', 'delete'].some(p => screen[p] === 'green');
                    const hasBlue = ['view', 'create', 'edit', 'delete'].some(p => screen[p] === 'blue');
                    
                    let screenSource = { text: 'Revoked', color: 'red' };
                    if (hasGreen && hasBlue) screenSource = { text: 'Mixed', color: 'orange' };
                    else if (hasGreen) screenSource = { text: 'Extra', color: 'green' };
                    else if (hasBlue) screenSource = { text: 'Template', color: 'blue' };

                    return (
                      <tr key={sIdx} style={{ background: '#f8fafc' }}>
                        <td style={{ padding: '12px 16px 12px 60px', display: 'flex', alignItems: 'center', gap: '8px', color: '#475569', fontSize: '13px', borderBottom: '1px solid #e2e8f0', fontWeight: 500 }}>
                          <FileText size={14} color="#94a3b8" /> {screen.name}
                        </td>
                        <td style={{ borderBottom: '1px solid #e2e8f0' }}>{renderPreviewIcon(screen.view)}</td>
                        <td style={{ borderBottom: '1px solid #e2e8f0' }}>{renderPreviewIcon(screen.create)}</td>
                        <td style={{ borderBottom: '1px solid #e2e8f0' }}>{renderPreviewIcon(screen.edit)}</td>
                        <td style={{ borderBottom: '1px solid #e2e8f0' }}>{renderPreviewIcon(screen.delete)}</td>
                        <td style={{textAlign: 'center', borderBottom: '1px solid #e2e8f0'}}><span className={`aa-badge aa-badge-${screenSource.color}`}>{screenSource.text}</span></td>
                      </tr>
                    );
                  })}
                </React.Fragment>
              )
            })}
          </tbody>
        </table>
      </div>
      <div style={{ padding: '16px 4px', fontSize: '13px', color: '#475569', fontWeight: 600 }}>
        Showing 1 to {accessGroups.length} of {accessGroups.length} groups
      </div>
    </div>
  );

  const getSummaryStats = () => {
    let total = 0;
    let template = 0;
    let extra = 0;
    let revoked = 0;

    accessGroups.forEach(group => {
      group.screens.forEach(screen => {
        total++;
        
        let hasGreen = false;
        let hasBlue = false;

        ['view', 'create', 'edit', 'delete'].forEach(perm => {
          if (screen[perm] === 'green') hasGreen = true;
          if (screen[perm] === 'blue') hasBlue = true;
        });

        if (hasGreen) {
          extra++;
        } else if (hasBlue) {
          template++;
        } else {
          revoked++;
        }
      });
    });

    return { total, template, extra, revoked };
  };

  const renderStep5 = () => {
    const stats = getSummaryStats();
    
    return (
    <div className="aa-step-content">
      <div className="aa-step-header">
        <h3 style={{ color: '#2563eb' }}>Step - 5 : Access Summary</h3>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '32px' }}>
        
        {/* Total Screens */}
        <div style={{ background: '#f8fafc', padding: '24px 16px', borderRadius: '8px', border: '1px solid #f1f5f9', textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px', color: '#1e40af', marginBottom: '20px', fontWeight: 600, fontSize: '13px' }}>
            <Users size={22} color="#2563eb" /> Total Screens
          </div>
          <h2 style={{ fontSize: '32px', margin: 0, color: '#0f172a' }}>{stats.total}</h2>
        </div>

        {/* From Template */}
        <div style={{ background: '#f8fafc', padding: '24px 16px', borderRadius: '8px', border: '1px solid #f1f5f9', textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px', color: '#1e40af', marginBottom: '20px', fontWeight: 600, fontSize: '13px' }}>
            <Shield size={22} color="#2563eb" /> From Template
          </div>
          <h2 style={{ fontSize: '32px', margin: 0, color: '#1e3a8a' }}>{stats.template}</h2>
        </div>

        {/* Extra Added */}
        <div style={{ background: '#f0fdf4', padding: '24px 16px', borderRadius: '8px', border: '1px solid #e2e8f0', textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px', color: '#166534', marginBottom: '20px', fontWeight: 600, fontSize: '13px' }}>
            <div style={{ border: '1.5px solid #16a34a', borderRadius: '3px', display: 'flex', padding: '2px', color: '#16a34a' }}><Plus size={16} strokeWidth={3} /></div> Extra Added
          </div>
          <h2 style={{ fontSize: '32px', margin: 0, color: '#14532d' }}>{stats.extra}</h2>
        </div>

        {/* Revoked */}
        <div style={{ background: '#fef2f2', padding: '24px 16px', borderRadius: '8px', border: '1px solid #fee2e2', textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px', color: '#991b1b', marginBottom: '20px', fontWeight: 600, fontSize: '13px' }}>
            <div style={{ border: '1.5px solid #dc2626', borderRadius: '3px', display: 'flex', padding: '2px', color: '#dc2626' }}><Minus size={16} strokeWidth={3} /></div> Revoked
          </div>
          <h2 style={{ fontSize: '32px', margin: 0, color: '#7f1d1d' }}>{stats.revoked}</h2>
        </div>

      </div>

      <div style={{ borderTop: '1px solid #e2e8f0', paddingTop: '20px', paddingBottom: '10px', display: 'flex', justifyContent: 'space-between', fontSize: '14px', color: '#475569', fontWeight: 600 }}>
        <div>Last Updated : <span style={{ color: '#0f172a' }}>21 May 2025 03:45 PM</span></div>
        <div>Updated By : <span style={{ color: '#0f172a' }}>Admin</span></div>
      </div>

    </div>
  )};

  return (
    <div className="cc-shell-container">
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        <Header 
          title="Assign Access to Employees" 
          subtitle="Assign and manage template based access and additional permissions for the selected employees."
          onLogout={onLogout} 
          userRole={userRole} 
        />

        <main className="cc-main">
          <div className="aa-container">

            {/* Stepper Navigation */}
            {renderStepper()}

            {/* Dynamic Step Content */}
            {currentStep === 1 && renderStep1()}
            {currentStep === 2 && renderStep2()}
            {currentStep === 3 && renderStep3()}
            {currentStep === 4 && renderStep4()}
            {currentStep === 5 && renderStep5()}

            {/* Global Bottom Actions */}
            <div className="aa-bottom-bar">
              {currentStep > 1 ? (
                <button className="aa-btn-outline" onClick={handlePrev}>Previous</button>
              ) : <div></div>}
              
              <div className="aa-bottom-bar-right">
                <button className="aa-btn-outline" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><RotateCcw size={16}/> Reset</button>
                {currentStep < 5 ? (
                  <button className="aa-btn-primary" onClick={handleNext}>Next Step <ArrowRight size={16} /></button>
                ) : (
                  <button className="aa-btn-primary"><Save size={16} /> Save Access</button>
                )}
              </div>
            </div>

          </div>
        </main>
      </div>
    </div>
  );
};

export default AssignAccess;
