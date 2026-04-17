// ============================================================
// MediChain Frontend Application
// Role-based views: Admin, Doctor, Patient
// ============================================================

const API = '';
let currentUser = null;
let jwtToken = null;
let cachedData = {};
let auditData = [];

// ============================================================
// DARK MODE
// ============================================================
function toggleDarkMode() {
    const html = document.documentElement;
    const isDark = html.getAttribute('data-theme') === 'dark';
    html.setAttribute('data-theme', isDark ? 'light' : 'dark');
    localStorage.setItem('medichain-theme', isDark ? 'light' : 'dark');
    updateDarkModeIcons();
}

function updateDarkModeIcons() {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const icon = isDark ? '\u2600' : '\u263E';
    const loginBtn = document.getElementById('loginDarkBtn');
    const appBtn = document.getElementById('appDarkBtn');
    if (loginBtn) loginBtn.innerHTML = icon;
    if (appBtn) appBtn.innerHTML = icon;
}

// Load saved theme
(function() {
    const saved = localStorage.getItem('medichain-theme');
    if (saved === 'dark') {
        document.documentElement.setAttribute('data-theme', 'dark');
    }
    updateDarkModeIcons();
})();

// ============================================================
// TOAST NOTIFICATIONS
// ============================================================
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = 'toast ' + type;
    toast.textContent = message;
    container.appendChild(toast);
    setTimeout(() => { toast.style.opacity = '0'; toast.style.transform = 'translateX(40px)'; setTimeout(() => toast.remove(), 300); }, 3500);
}

// ============================================================
// API HELPER
// ============================================================
async function api(endpoint, method = 'GET', body = null) {
    const opts = { method, headers: { 'Content-Type': 'application/json' } };
    if (jwtToken) opts.headers['Authorization'] = 'Bearer ' + jwtToken;
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(API + endpoint, opts);
    const data = await res.json();
    if (!res.ok) {
        if (res.status === 401) { logout(); showToast('Session expired. Please login again.', 'error'); }
        throw new Error(data.error || data.message || 'Request failed');
    }
    return data;
}

// ============================================================
// LOGIN & AUTH
// ============================================================
function selectLoginRole(role, evt) {
    document.querySelectorAll('.role-btn').forEach(b => b.classList.remove('active'));
    if (evt && evt.target) evt.target.classList.add('active');
    const hints = {
        admin: 'Admin credentials pre-filled',
        doctor: 'Doctor credentials pre-filled',
        patient: 'Patient credentials pre-filled'
    };
    const creds = {
        admin: ['admin', 'password123'],
        doctor: ['dr.anil', 'password123'],
        patient: ['rahul.verma', 'password123']
    };
    document.getElementById('loginHint').innerHTML = hints[role];
    document.getElementById('loginUsername').value = creds[role][0];
    document.getElementById('loginPassword').value = creds[role][1];
}

function getSelectedLoginRole() {
    const activeBtn = document.querySelector('.role-btn.active');
    if (!activeBtn) return 'admin';
    const text = activeBtn.textContent.trim().toLowerCase();
    return text;
}

async function login() {
    const username = document.getElementById('loginUsername').value;
    const password = document.getElementById('loginPassword').value;
    const role = getSelectedLoginRole();
    try {
        const data = await api('/api/auth/login', 'POST', { username, password, role });
        currentUser = data;
        jwtToken = data.token || null;
        sessionStorage.setItem('medichain-jwt', jwtToken || '');
        document.getElementById('loginPage').style.display = 'none';
        document.getElementById('appContainer').style.display = 'flex';
        document.getElementById('appContainer').classList.remove('hidden');
        document.getElementById('topBarUser').textContent = data.username;
        document.getElementById('topBarRole').textContent = data.role;
        document.getElementById('topBarRole').className = 'badge badge-role-' + data.role;

        buildSidebar(data.role);
        navigateToDefault(data.role);
        showToast('Welcome, ' + data.username + '!', 'success');
    } catch (e) {
        const el = document.getElementById('loginError');
        el.textContent = e.message;
        el.classList.remove('hidden');
    }
}

function logout() {
    currentUser = null;
    jwtToken = null;
    cachedData = {};
    sessionStorage.removeItem('medichain-jwt');
    document.getElementById('loginPage').style.display = 'flex';
    document.getElementById('appContainer').style.display = 'none';
    document.getElementById('loginError').classList.add('hidden');
}

// Check for saved session on load
(function() {
    const savedToken = sessionStorage.getItem('medichain-jwt');
    if (savedToken) jwtToken = savedToken;
})();

document.getElementById('loginPassword').addEventListener('keypress', e => { if (e.key === 'Enter') login(); });
document.getElementById('loginUsername').addEventListener('keypress', e => { if (e.key === 'Enter') login(); });

// ============================================================
// SIDEBAR BUILDER
// ============================================================
function buildSidebar(role) {
    const sidebar = document.getElementById('sidebar');
    let html = `<div class="sidebar-header"><h1>MediChain</h1><small>Healthcare Data Exchange</small></div><div class="sidebar-nav">`;

    if (role === 'admin') {
        html += `
            <div class="nav-section">Main</div>
            ${navItem('dashboard', 'Dashboard', iconDashboard())}
            <div class="nav-section">Clinical</div>
            ${navItem('patients', 'Patients', iconPatients())}
            ${navItem('doctors', 'Doctors', iconDoctors())}
            ${navItem('hospitals', 'Hospitals', iconHospitals())}
            ${navItem('encounters', 'Encounters', iconEncounters())}
            <div class="nav-section">Medication</div>
            ${navItem('prescriptions', 'Prescriptions', iconPrescriptions())}
            <div class="nav-section">Diagnostics</div>
            ${navItem('lab', 'Lab Orders & Results', iconLab())}
            <div class="nav-section">Access Control</div>
            ${navItem('consent', 'Consent & Access', iconConsent())}
            <div class="nav-section">Security</div>
            ${navItem('audit', 'Audit Logs', iconAudit())}
            <div class="nav-section">DBMS Demo</div>
            ${navItem('txn-demo', 'Transaction Demo', iconTxn())}`;
    } else if (role === 'doctor') {
        html += `
            <div class="nav-section">Main</div>
            ${navItem('doc-dashboard', 'Dashboard', iconDashboard())}
            <div class="nav-section">Clinical</div>
            ${navItem('doc-patients', 'My Patients', iconPatients())}
            ${navItem('doc-lookup', 'Patient Lookup', iconSearch())}
            ${navItem('doc-encounters', 'My Encounters', iconEncounters())}
            <div class="nav-section">Medication</div>
            ${navItem('doc-prescriptions', 'Prescriptions', iconPrescriptions())}
            <div class="nav-section">Diagnostics</div>
            ${navItem('doc-lab', 'Lab Orders', iconLab())}`;
    } else if (role === 'patient') {
        html += `
            <div class="nav-section">Main</div>
            ${navItem('pat-dashboard', 'Dashboard', iconDashboard())}
            <div class="nav-section">My Health</div>
            ${navItem('pat-profile', 'My Profile', iconProfile())}
            ${navItem('pat-encounters', 'Encounters', iconEncounters())}
            ${navItem('pat-prescriptions', 'Prescriptions', iconPrescriptions())}
            ${navItem('pat-lab', 'Lab Results', iconLab())}
            ${navItem('pat-consents', 'My Consents', iconConsent())}
            ${navItem('pat-access-requests', 'Access Requests', iconDoctors())}`;
    }

    html += `</div><div class="sidebar-footer">
        <div style="margin-bottom:8px;color:#94a3b8;font-size:0.82rem">${currentUser.username} (${role})</div>
        <button class="btn btn-ghost btn-sm" onclick="logout()" style="width:100%;justify-content:center;color:#94a3b8;border-color:rgba(255,255,255,0.1)">Logout</button>
    </div>`;

    sidebar.innerHTML = html;
}

function navItem(section, label, icon) {
    return `<div class="nav-item" onclick="navigate('${section}')">${icon}${label}</div>`;
}

// ============================================================
// NAVIGATION
// ============================================================
function navigateToDefault(role) {
    if (role === 'admin') navigate('dashboard');
    else if (role === 'doctor') navigate('doc-dashboard');
    else if (role === 'patient') navigate('pat-dashboard');
}

function navigate(section) {
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    const sec = document.getElementById('sec-' + section);
    if (sec) sec.classList.add('active');

    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const activeNav = document.querySelector('.nav-item[onclick*="' + section + '"]');
    if (activeNav) activeNav.classList.add('active');
    else {
        const firstNav = document.querySelector('.nav-item');
        if (firstNav) firstNav.classList.add('active');
    }

    const titles = {
        'dashboard': 'Dashboard', 'patients': 'Patient Management', 'doctors': 'Doctor Registry',
        'hospitals': 'Hospital Registry', 'encounters': 'Clinical Encounters',
        'prescriptions': 'Prescription Management', 'lab': 'Laboratory Orders & Results',
        'consent': 'Consent & Access Control', 'audit': 'Audit Trail & Integrity', 'txn-demo': 'Transaction Demo',
        'doc-dashboard': 'Doctor Dashboard', 'doc-patients': 'My Patients',
        'doc-lookup': 'Patient Lookup', 'doc-encounters': 'My Encounters',
        'doc-prescriptions': 'My Prescriptions', 'doc-lab': 'My Lab Orders',
        'pat-dashboard': 'Patient Dashboard', 'pat-profile': 'My Profile',
        'pat-encounters': 'My Encounters', 'pat-prescriptions': 'My Prescriptions',
        'pat-lab': 'My Lab Results', 'pat-consents': 'My Consents',
        'pat-access-requests': 'Access Requests'
    };
    document.getElementById('pageTitle').textContent = titles[section] || section;

    const loaders = {
        'dashboard': loadDashboard, 'patients': loadPatients, 'doctors': loadDoctors,
        'hospitals': loadHospitals, 'encounters': loadEncounters, 'prescriptions': loadPrescriptions,
        'lab': loadLabOrders, 'consent': loadConsents, 'audit': loadAuditLogs, 'txn-demo': () => {},
        'doc-dashboard': loadDocDashboard, 'doc-patients': loadDocPatients,
        'doc-lookup': () => {}, 'doc-encounters': loadDocEncounters,
        'doc-prescriptions': loadDocPrescriptions, 'doc-lab': loadDocLab,
        'pat-dashboard': loadPatDashboard, 'pat-profile': loadPatProfile,
        'pat-encounters': loadPatEncounters, 'pat-prescriptions': loadPatPrescriptions,
        'pat-lab': loadPatLab, 'pat-consents': loadPatConsents,
        'pat-access-requests': loadPatAccessRequests
    };
    if (loaders[section]) loaders[section]();
}

// ============================================================
// MODAL
// ============================================================
function showModal(id) { document.getElementById(id).classList.add('active'); }
function closeModal(id) { document.getElementById(id).classList.remove('active'); }

// ============================================================
// ADMIN: DASHBOARD
// ============================================================
async function loadDashboard() {
    try {
        const data = await api('/api/dashboard/stats');
        cachedData.stats = data;
        document.getElementById('dashStats').innerHTML = `
            <div class="stat-card"><h3>Patients</h3><div class="value">${data.total_patients}</div></div>
            <div class="stat-card green"><h3>Doctors</h3><div class="value">${data.total_doctors}</div></div>
            <div class="stat-card cyan"><h3>Hospitals</h3><div class="value">${data.total_hospitals}</div></div>
            <div class="stat-card"><h3>Encounters</h3><div class="value">${data.total_encounters}</div></div>
            <div class="stat-card green"><h3>Active Rx</h3><div class="value">${data.active_prescriptions}</div></div>
            <div class="stat-card yellow"><h3>Pending Labs</h3><div class="value">${data.pending_lab_orders}</div></div>
            <div class="stat-card red"><h3>Critical Alerts</h3><div class="value">${data.critical_alerts}</div></div>
            <div class="stat-card cyan"><h3>Audit Entries</h3><div class="value">${data.audit_log_count}</div></div>
            <div class="stat-card"><h3>Active Consents</h3><div class="value">${data.active_consents}</div></div>
            <div class="stat-card red"><h3>Pending Reviews</h3><div class="value">${data.pending_emergency_reviews}</div></div>`;
        const tbody = document.getElementById('dashRecentEncounters');
        tbody.innerHTML = (data.recent_encounters || []).map(e => `<tr>
            <td>${e.encounter_id}</td>
            <td>${e.fname} ${e.lname} (${e.health_id})</td>
            <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
            <td>${fmtDate(e.encounter_date_time)}</td>
            <td>${e.hospital_name || '-'}</td>
        </tr>`).join('');
    } catch (e) { console.error('Dashboard error:', e); }
}

// ============================================================
// ADMIN: PATIENTS
// ============================================================
async function loadPatients() {
    const data = await api('/api/patients');
    cachedData.patients = data;
    renderPatients(data);
}

function renderPatients(data) {
    document.getElementById('patientTable').innerHTML = data.map(p => `<tr>
        <td><strong>${p.health_id}</strong></td>
        <td>${p.fname} ${p.mname || ''} ${p.lname}</td>
        <td>${p.age || '-'}</td>
        <td>${p.gender}</td>
        <td>${p.blood_group || '-'}</td>
        <td>${p.address_city || '-'}</td>
        <td>${p.insurance_provider || '-'}</td>
        <td><button class="btn btn-outline btn-sm" onclick="viewPatient('${p.health_id}')">View</button></td>
    </tr>`).join('');
}

async function searchPatients() {
    const q = document.getElementById('patientSearch').value;
    if (q.length === 0) return loadPatients();
    if (q.length < 2) return;
    const data = await api('/api/patients?search=' + encodeURIComponent(q));
    renderPatients(data);
}

async function viewPatient(healthId) {
    const p = await api('/api/patients/' + healthId);
    const allergies = await api('/api/patients/' + healthId + '/allergies');
    let html = `<h3>${p.fname} ${p.mname || ''} ${p.lname}</h3>
        <p><strong>Health ID:</strong> ${p.health_id} | <strong>Age:</strong> ${p.age} (${p.age_category}) |
        <strong>Gender:</strong> ${p.gender} | <strong>Blood Group:</strong> ${p.blood_group || 'N/A'}</p>
        <p><strong>Address:</strong> ${[p.address_street, p.address_city, p.address_state, p.postal_code].filter(Boolean).join(', ') || 'N/A'}</p>
        <p><strong>Emergency Contact:</strong> ${p.emergency_contact_name || 'N/A'} (${p.emergency_contact_phone || 'N/A'})</p>
        <p><strong>Insurance:</strong> ${p.insurance_provider || 'N/A'} | Policy: ${p.policy_type || 'N/A'}</p>
        <hr style="margin:15px 0;border:none;border-top:1px solid var(--border)">
        <h4>Active Allergies</h4>`;
    if (allergies.length === 0) html += '<p style="color:var(--text-muted)">No known allergies</p>';
    else html += '<table><thead><tr><th>Allergen</th><th>Severity</th><th>Reaction</th></tr></thead><tbody>' +
        allergies.map(a => `<tr><td>${a.allergen}</td><td><span class="badge badge-${a.severity === 'Severe' || a.severity === 'Life-threatening' ? 'critical' : 'pending'}">${a.severity}</span></td><td>${a.reaction_description || '-'}</td></tr>`).join('') +
        '</tbody></table>';
    showDetail('Patient Details', html);
}

async function createPatient() {
    try {
        await api('/api/patients', 'POST', {
            health_id: gv('pHealthId'), fname: gv('pFname'), mname: gv('pMname') || null, lname: gv('pLname'),
            address_street: gv('pStreet') || null, address_city: gv('pCity') || null,
            address_state: gv('pState') || null, postal_code: gv('pPostal') || null,
            date_of_birth: gv('pDob'), gender: gv('pGender'), blood_group: gv('pBlood') || null,
            emergency_contact_name: gv('pEmName') || null, emergency_contact_phone: gv('pEmPhone') || null,
            insurance_provider: gv('pInsProvider') || null, insurance_start: gv('pInsStart') || null,
            insurance_end: gv('pInsEnd') || null, policy_type: gv('pPolicyType') || null
        });
        closeModal('patientModal');
        loadPatients();
        showToast('Patient registered successfully!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: DOCTORS
// ============================================================
async function loadDoctors() {
    const data = await api('/api/doctors');
    cachedData.doctors = data;
    document.getElementById('doctorTable').innerHTML = data.map(d => `<tr>
        <td>${d.doctor_id}</td><td>${d.name}</td><td>${d.medical_license_number}</td>
        <td>${d.specialization || '-'}</td><td>${d.phone_number || '-'}</td><td>${d.hospitals || '-'}</td>
    </tr>`).join('');
}

async function createDoctor() {
    try {
        await api('/api/doctors', 'POST', {
            medical_license_number: gv('dLicense'), name: gv('dName'), phone_number: gv('dPhone') || null,
            email: gv('dEmail') || null, date_of_birth: gv('dDob') || null, specialization: gv('dSpec') || null
        });
        closeModal('doctorModal');
        loadDoctors();
        showToast('Doctor registered!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: HOSPITALS
// ============================================================
async function loadHospitals() {
    const data = await api('/api/hospitals');
    cachedData.hospitals = data;
    document.getElementById('hospitalTable').innerHTML = data.map(h => `<tr>
        <td>${h.hospital_id}</td><td>${h.hospital_name}</td><td>${h.license_number}</td>
        <td>${h.facility_type || '-'}</td><td>${h.address_city || '-'}</td>
        <td>${h.bed_capacity || '-'}</td><td>${h.phone || '-'}</td>
    </tr>`).join('');
}

async function createHospital() {
    try {
        await api('/api/hospitals', 'POST', {
            hospital_name: gv('hName'), license_number: gv('hLicense'), phone: gv('hPhone') || null,
            email: gv('hEmail') || null, bed_capacity: gv('hBeds') ? parseInt(gv('hBeds')) : null,
            facility_type: gv('hType'), address_street: gv('hStreet') || null,
            address_city: gv('hCity') || null, address_state: gv('hState') || null, postal_code: gv('hPostal') || null
        });
        closeModal('hospitalModal');
        loadHospitals();
        showToast('Hospital registered!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: ENCOUNTERS
// ============================================================
async function loadEncounters() {
    const data = await api('/api/encounters');
    await loadDropdowns();
    document.getElementById('encounterTable').innerHTML = data.map(e => `<tr>
        <td>${e.encounter_id}</td>
        <td>${e.fname} ${e.lname} (${e.health_id})</td>
        <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
        <td>${fmtDate(e.encounter_date_time)}</td>
        <td>${e.hospital_name || '-'}</td>
        <td>${e.doctors || '-'}</td>
        <td>
            <button class="btn btn-outline btn-sm" onclick="viewEncounter(${e.encounter_id})">Details</button>
            <button class="btn btn-success btn-sm" onclick="openVitals(${e.encounter_id})">Vitals</button>
        </td>
    </tr>`).join('');
}

async function viewEncounter(id) {
    const e = await api('/api/encounters/' + id);
    let html = `<h3>Encounter #${e.encounter_id} - ${e.encounter_type}</h3>
        <p><strong>Patient:</strong> ${e.fname} ${e.lname} (${e.health_id}) | <strong>Hospital:</strong> ${e.hospital_name || 'N/A'}</p>
        <p><strong>Date:</strong> ${fmtDate(e.encounter_date_time)} | <strong>Complaint:</strong> ${e.chief_complaint || 'N/A'}</p>
        <p><strong>Treatment Plan:</strong> ${e.treatment_plan || 'N/A'}</p>`;
    if (e.doctors && e.doctors.length) {
        html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Assigned Doctors</h4><table><thead><tr><th>Name</th><th>Specialization</th><th>Role</th><th>Primary</th></tr></thead><tbody>';
        html += e.doctors.map(d => `<tr><td>${d.name}</td><td>${d.specialization || '-'}</td><td>${d.role || '-'}</td><td>${d.is_primary ? 'Yes' : 'No'}</td></tr>`).join('') + '</tbody></table>';
    }
    if (e.vitals && e.vitals.length) {
        html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Vital Signs</h4><table><thead><tr><th>Time</th><th>BP</th><th>Pulse</th><th>Temp</th><th>RR</th><th>O2</th></tr></thead><tbody>';
        html += e.vitals.map(v => `<tr><td>${fmtDate(v.reading_timestamp)}</td><td>${v.bp_systolic || '-'}/${v.bp_diastolic || '-'}</td><td>${v.pulse || '-'}</td><td>${v.temperature || '-'}</td><td>${v.respiratory_rate || '-'}</td><td>${v.oxygen_saturation || '-'}%</td></tr>`).join('') + '</tbody></table>';
    }
    if (e.diagnoses && e.diagnoses.length) {
        html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Diagnoses</h4><table><thead><tr><th>ICD-10</th><th>Description</th><th>Type</th><th>Status</th></tr></thead><tbody>';
        html += e.diagnoses.map(d => `<tr><td>${d.icd10_code}</td><td>${d.description}</td><td>${d.diagnosis_type}</td><td>${d.status}</td></tr>`).join('') + '</tbody></table>';
    }
    showDetail('Encounter Details', html);
}

async function createEncounter() {
    try {
        const type = gv('eType');
        const body = {
            health_id: gv('eHealthId'), hospital_id: parseInt(gv('eHospital')),
            encounter_date_time: gv('eDateTime'), encounter_type: type,
            doctor_id: parseInt(gv('eDoctor')),
            chief_complaint: gv('eComplaint') || null, treatment_plan: gv('ePlan') || null
        };
        if (type === 'Inpatient') { body.admission_date_time = gv('eDateTime'); body.bed_number = gv('eBed'); }
        await api('/api/encounters', 'POST', body);
        closeModal('encounterModal');
        if (currentUser.role === 'admin') loadEncounters();
        else loadDocEncounters();
        showToast('Encounter created!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

function openVitals(encId) { document.getElementById('vEncId').value = encId; showModal('vitalsModal'); }

async function recordVitals() {
    try {
        await api('/api/encounters/' + gv('vEncId') + '/vitals', 'POST', {
            bp_systolic: intOrNull('vSys'), bp_diastolic: intOrNull('vDia'),
            pulse: intOrNull('vPulse'), temperature: floatOrNull('vTemp'),
            respiratory_rate: intOrNull('vRR'), height: floatOrNull('vHeight'),
            weight: floatOrNull('vWeight'), oxygen_saturation: intOrNull('vO2')
        });
        closeModal('vitalsModal');
        showToast('Vital signs recorded!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: PRESCRIPTIONS
// ============================================================
async function loadPrescriptions() {
    const data = await api('/api/prescriptions');
    await loadDropdowns();
    document.getElementById('prescriptionTable').innerHTML = data.map(p => `<tr>
        <td>${p.prescription_id}</td>
        <td>${p.fname} ${p.lname} (${p.health_id})</td>
        <td>${p.doctor_name}</td>
        <td>${p.prescription_date || '-'}</td>
        <td><span class="badge badge-${p.status === 'Active' ? 'active' : p.status === 'Completed' ? 'completed' : 'cancelled'}">${p.status}</span></td>
        <td>
            <button class="btn btn-outline btn-sm" onclick="viewPrescription(${p.prescription_id})">View</button>
            <button class="btn btn-primary btn-sm" onclick="openAddMed(${p.prescription_id}, '${p.health_id}')">+ Med</button>
            ${p.status === 'Active' ? `<button class="btn btn-warning btn-sm" onclick="updateRxStatus(${p.prescription_id},'Completed')">Complete</button>` : ''}
        </td>
    </tr>`).join('');
}

async function viewPrescription(id) {
    const rx = await api('/api/prescriptions/' + id);
    let html = `<h3>Prescription #${rx.prescription_id}</h3>
        <p><strong>Patient:</strong> ${rx.fname} ${rx.lname} (${rx.health_id}) | <strong>Doctor:</strong> ${rx.doctor_name}</p>
        <p><strong>Period:</strong> ${rx.start_date || 'N/A'} to ${rx.end_date || 'Ongoing'} | <strong>Status:</strong> ${rx.status}</p>`;
    if (rx.items && rx.items.length) {
        html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Medications</h4><table><thead><tr><th>Medication</th><th>Dosage</th><th>Frequency</th><th>Duration</th><th>Instructions</th><th>Override</th></tr></thead><tbody>';
        html += rx.items.map(i => `<tr><td><strong>${i.generic_name}</strong> (${i.brand_name || '-'})<br><small style="color:var(--text-muted)">${i.drug_class || ''}</small></td><td>${i.dosage_strength || '-'} ${i.dosage_form || ''}</td><td>${i.frequency || '-'}</td><td>${i.duration_days || '-'} days</td><td>${i.instructions || '-'}</td><td>${i.allergy_override ? '<span class="badge badge-critical">Allergy</span> ' : ''}${i.interaction_override ? '<span class="badge badge-pending">Interaction</span>' : '-'}</td></tr>`).join('') + '</tbody></table>';
    } else html += '<p style="color:var(--text-muted)">No medications added yet</p>';
    showDetail('Prescription Details', html);
}

async function createPrescription() {
    try {
        await api('/api/prescriptions', 'POST', {
            encounter_id: parseInt(gv('rxEncounter')), doctor_id: parseInt(gv('rxDoctor')),
            start_date: gv('rxStart') || null, end_date: gv('rxEnd') || null
        });
        closeModal('prescriptionModal');
        if (currentUser.role === 'admin') loadPrescriptions();
        else loadDocPrescriptions();
        showToast('Prescription created!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

let currentRxPatient = null;
async function openAddMed(rxId, healthId) {
    document.getElementById('medRxId').value = rxId;
    currentRxPatient = healthId;
    document.getElementById('medAlerts').innerHTML = '';
    document.getElementById('overrideSection').classList.add('hidden');
    const meds = await api('/api/prescriptions/medications');
    const sel = document.getElementById('medSelect');
    sel.innerHTML = '<option value="">-- Select Medication --</option>' +
        meds.map(m => `<option value="${m.medication_id}">${m.generic_name} (${m.brand_name || 'Generic'}) - ${m.drug_class || ''}</option>`).join('');
    showModal('addMedModal');
}

async function checkMedSafety() {
    const medId = gv('medSelect');
    if (!medId || !currentRxPatient) return;
    let alerts = '';
    let needOverride = false;
    try {
        const allergy = await api(`/api/prescriptions/check-allergy?health_id=${currentRxPatient}&medication_id=${medId}`);
        if (allergy.has_allergy) {
            alerts += '<div class="alert alert-danger"><strong>ALLERGY ALERT:</strong> Patient has a severe allergy. ' +
                allergy.allergies.map(a => `Allergen: ${a.allergen}, Severity: ${a.severity}`).join('; ') + '</div>';
            needOverride = true;
        }
        const interactions = await api(`/api/prescriptions/check-interactions?health_id=${currentRxPatient}&medication_id=${medId}`);
        if (interactions.has_interactions) {
            alerts += '<div class="alert alert-warning"><strong>DRUG INTERACTION:</strong> ' +
                interactions.interactions.map(i => `${i.drug1_name} + ${i.drug2_name}: ${i.severity}`).join('<br>') + '</div>';
            if (interactions.interactions.some(i => i.severity === 'Severe' || i.severity === 'Life-threatening')) needOverride = true;
        }
        if (!allergy.has_allergy && !interactions.has_interactions) {
            alerts = '<div class="alert alert-success">No allergy or interaction alerts.</div>';
        }
    } catch (e) { alerts = ''; }
    document.getElementById('medAlerts').innerHTML = alerts;
    document.getElementById('overrideSection').classList.toggle('hidden', !needOverride);
}

async function addMedication() {
    try {
        await api('/api/prescriptions/' + gv('medRxId') + '/items', 'POST', {
            medication_id: parseInt(gv('medSelect')),
            dosage_strength: gv('medDosage') || null, dosage_form: gv('medForm') || null,
            frequency: gv('medFreq') || null, duration_days: intOrNull('medDuration'),
            quantity_dispensed: intOrNull('medQty'), instructions: gv('medInstructions') || null,
            allergy_override: document.getElementById('medAllergyOverride').checked,
            interaction_override: document.getElementById('medInteractionOverride').checked,
            override_justification: gv('medOverrideJustification') || null
        });
        closeModal('addMedModal');
        if (currentUser.role === 'admin') loadPrescriptions();
        else loadDocPrescriptions();
        showToast('Medication added!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function updateRxStatus(id, status) {
    if (!confirm(`Change prescription status to ${status}?`)) return;
    try {
        await api('/api/prescriptions/' + id + '/status', 'PUT', { status });
        if (currentUser.role === 'admin') loadPrescriptions();
        else loadDocPrescriptions();
        showToast('Status updated!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: LAB ORDERS
// ============================================================
async function loadLabOrders() {
    const data = await api('/api/lab/orders');
    await loadDropdowns();
    const catalog = await api('/api/lab/catalog');
    document.getElementById('loTest').innerHTML = catalog.map(t => `<option value="${t.test_code}">${t.test_name} (${t.test_code})</option>`).join('');
    document.getElementById('labOrderTable').innerHTML = data.map(o => `<tr>
        <td>${o.lab_order_id}</td>
        <td>${o.fname} ${o.lname} (${o.health_id})</td>
        <td>${o.test_name}</td>
        <td><span class="badge badge-${o.priority.toLowerCase()}">${o.priority}</span></td>
        <td><span class="badge badge-${o.order_status === 'Completed' ? 'completed' : o.order_status === 'Pending' ? 'pending' : 'active'}">${o.order_status}</span></td>
        <td>${o.doctor_name}</td>
        <td>${fmtDate(o.order_date_time)}</td>
        <td>
            ${o.order_status === 'Pending' ? `<button class="btn btn-outline btn-sm" onclick="collectSpecimen(${o.lab_order_id})">Collect</button>` : ''}
            ${o.order_status !== 'Completed' && o.order_status !== 'Cancelled' ? `<button class="btn btn-primary btn-sm" onclick="openLabResult(${o.lab_order_id})">+ Result</button>` : ''}
            <button class="btn btn-outline btn-sm" onclick="viewLabOrder(${o.lab_order_id})">View</button>
        </td>
    </tr>`).join('');
}

async function viewLabOrder(id) {
    const o = await api('/api/lab/orders/' + id);
    let html = `<h3>Lab Order #${o.lab_order_id}</h3>
        <p><strong>Test:</strong> ${o.test_name} (${o.test_code})</p>
        <p><strong>Patient:</strong> ${o.fname} ${o.lname} (${o.health_id}) | <strong>Doctor:</strong> ${o.doctor_name}</p>
        <p><strong>Priority:</strong> ${o.priority} | <strong>Status:</strong> ${o.order_status}</p>
        <p><strong>Specimen:</strong> ${o.specimen_id || 'N/A'} | <strong>Collected:</strong> ${o.specimen_collected_at ? fmtDate(o.specimen_collected_at) : 'Not yet'}</p>`;
    if (o.results && o.results.length) {
        html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Results</h4><table><thead><tr><th>Value</th><th>Unit</th><th>Reference</th><th>Abnormal</th><th>Critical</th><th>Acknowledged</th></tr></thead><tbody>';
        html += o.results.map(r => `<tr><td><strong>${r.result_value || '-'}</strong></td><td>${r.result_unit || '-'}</td><td>${r.reference_range || '-'}</td><td>${r.abnormal_flag ? '<span class="badge badge-pending">Yes</span>' : 'No'}</td><td>${r.critical_flag ? '<span class="badge badge-critical">CRITICAL</span>' : '-'}</td><td>${r.physician_acknowledged ? 'Yes' : '<span class="badge badge-pending">Pending</span>'}</td></tr>`).join('') + '</tbody></table>';
    }
    showDetail('Lab Order Details', html);
}

async function createLabOrder() {
    try {
        await api('/api/lab/orders', 'POST', {
            encounter_id: parseInt(gv('loEncounter')), doctor_id: parseInt(gv('loDoctor')),
            test_code: gv('loTest'), priority: gv('loPriority'), clinical_info: gv('loClinicalInfo') || null
        });
        closeModal('labOrderModal');
        if (currentUser.role === 'admin') loadLabOrders();
        else loadDocLab();
        showToast('Lab order created!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function collectSpecimen(id) {
    try {
        await api('/api/lab/orders/' + id + '/collect', 'PUT');
        loadLabOrders();
        showToast('Specimen collected!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

function openLabResult(orderId) { document.getElementById('lrOrderId').value = orderId; showModal('labResultModal'); }

async function addLabResult() {
    try {
        await api('/api/lab/results', 'POST', {
            lab_order_id: parseInt(gv('lrOrderId')), result_value: gv('lrValue'),
            result_unit: gv('lrUnit') || null, reference_range: gv('lrRange') || null,
            abnormal_flag: document.getElementById('lrAbnormal').checked,
            critical_flag: document.getElementById('lrCritical').checked,
            verified_by_doctor_id: intOrNull('lrVerifiedBy')
        });
        closeModal('labResultModal');
        if (currentUser.role === 'admin') loadLabOrders();
        else loadDocLab();
        showToast('Result submitted!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function loadCriticalResults() {
    const data = await api('/api/lab/critical');
    if (data.length === 0) {
        document.getElementById('criticalAlerts').innerHTML = '<div class="alert alert-success">No critical unacknowledged results.</div>';
        return;
    }
    let html = '<div class="card mb-20"><div class="card-header" style="border-left:4px solid var(--danger)"><h3 style="color:var(--danger)">Critical Results</h3></div><div class="card-body table-container"><table><thead><tr><th>Patient</th><th>Test</th><th>Value</th><th>Doctor</th><th>Action</th></tr></thead><tbody>';
    html += data.map(r => `<tr><td>${r.fname} ${r.lname}</td><td>${r.test_name}</td><td><strong>${r.result_value || '-'}</strong></td><td>${r.doctor_name}</td><td><button class="btn btn-danger btn-sm" onclick="acknowledgeResult(${r.result_id}, ${r.doctor_id})">Acknowledge</button></td></tr>`).join('') + '</tbody></table></div></div>';
    document.getElementById('criticalAlerts').innerHTML = html;
}

async function acknowledgeResult(resultId, doctorId) {
    try {
        await api('/api/lab/results/' + resultId + '/acknowledge', 'PUT', { doctor_id: doctorId });
        loadLabOrders();
        loadCriticalResults();
        showToast('Result acknowledged!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: CONSENT
// ============================================================
function switchConsentTab(tab, evt) {
    document.querySelectorAll('#sec-consent .tab').forEach(t => t.classList.remove('active'));
    if (evt && evt.target) evt.target.classList.add('active');
    document.getElementById('consentTabConsents').classList.toggle('hidden', tab !== 'consents');
    document.getElementById('consentTabEmergency').classList.toggle('hidden', tab !== 'emergency');
    if (tab === 'emergency') loadEmergencyAccesses();
}

async function loadConsents() {
    const data = await api('/api/consent');
    await loadDropdowns();
    document.getElementById('consentTable').innerHTML = data.map(c => `<tr>
        <td>${c.consent_id}</td><td>${c.fname} ${c.lname}</td><td>${c.hospital_name}</td>
        <td>${c.access_level}</td><td>${c.purpose || '-'}</td><td>${c.effective_date}</td>
        <td>${c.expiration_date || 'Never'}</td>
        <td><span class="badge badge-${c.status === 'Active' ? 'active' : c.status === 'Expired' ? 'pending' : 'cancelled'}">${c.status}</span></td>
        <td>${c.status === 'Active' ? `<button class="btn btn-danger btn-sm" onclick="revokeConsent(${c.consent_id})">Revoke</button>` : '-'}</td>
    </tr>`).join('');
}

async function createConsent() {
    try {
        await api('/api/consent', 'POST', {
            health_id: gv('cPatient'), hospital_id: parseInt(gv('cHospital')),
            access_level: gv('cAccess'), purpose: gv('cPurpose') || null,
            effective_date: gv('cEffective'), expiration_date: gv('cExpiration') || null
        });
        closeModal('consentModal');
        loadConsents();
        showToast('Consent granted!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function revokeConsent(id) {
    if (!confirm('Revoke this consent?')) return;
    try {
        await api('/api/consent/' + id + '/revoke', 'PUT');
        loadConsents();
        showToast('Consent revoked!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function loadEmergencyAccesses() {
    await loadDropdowns();
    const data = await api('/api/consent/emergency-access');
    document.getElementById('emergencyTable').innerHTML = data.map(e => `<tr>
        <td>${e.access_id}</td><td>${e.fname} ${e.lname}</td><td>${e.doctor_name}</td>
        <td>${e.emergency_type}</td><td style="max-width:200px">${e.justification}</td>
        <td>${fmtDate(e.access_time)}</td>
        <td><span class="badge badge-${e.review_status === 'Pending Review' ? 'pending' : e.review_status === 'Approved' ? 'active' : 'critical'}">${e.review_status}</span></td>
        <td>${e.review_status === 'Pending Review' ? `
            <button class="btn btn-success btn-sm" onclick="reviewEmergency(${e.access_id}, 'Approved')">Approve</button>
            <button class="btn btn-danger btn-sm" onclick="reviewEmergency(${e.access_id}, 'Flagged')">Flag</button>` : '-'}</td>
    </tr>`).join('');
}

async function requestEmergencyAccess() {
    try {
        const data = await api('/api/consent/emergency-access', 'POST', {
            health_id: gv('emPatient'), doctor_id: parseInt(gv('emDoctor')),
            emergency_type: gv('emType'), justification: gv('emJustification')
        });
        closeModal('emergencyModal');
        showToast(data.message, 'success');
        loadEmergencyAccesses();
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function reviewEmergency(id, status) {
    try {
        await api('/api/consent/emergency-access/' + id + '/review', 'PUT', {
            review_status: status, reviewed_by: currentUser.user_id
        });
        loadEmergencyAccesses();
        showToast('Review submitted!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: AUDIT LOGS
// ============================================================
async function loadAuditLogs() {
    const filter = gv('auditFilter');
    let url = '/api/audit?limit=200';
    if (filter) url += '&action_type=' + encodeURIComponent(filter);
    const data = await api(url);
    auditData = data.logs || [];

    const types = await api('/api/audit/action-types');
    const sel = document.getElementById('auditFilter');
    const current = sel.value;
    sel.innerHTML = '<option value="">All Actions</option>' +
        types.map(t => `<option value="${t}" ${t === current ? 'selected' : ''}>${t}</option>`).join('');

    document.getElementById('auditTable').innerHTML = auditData.map(l => `<tr>
        <td>${l.log_id}</td>
        <td>${fmtDate(l.event_time)}</td>
        <td>${l.username || 'System'}</td>
        <td><span class="badge badge-${l.action_type.includes('ALERT') || l.action_type.includes('VIOLATION') || l.action_type.includes('EMERGENCY') ? 'critical' : l.action_type.includes('REGISTER') || l.action_type === 'UPDATE' ? 'pending' : 'active'}">${l.action_type}</span></td>
        <td>${l.table_name || '-'}</td>
        <td>${l.record_id || '-'}</td>
        <td style="max-width:250px;font-size:0.78rem">${l.notes || '-'}</td>
        <td><div class="hash-display">${l.hash_value ? l.hash_value.substring(0, 16) + '...' : '-'}</div></td>
    </tr>`).join('');
}

async function verifyAuditChain() {
    const result = await api('/api/audit/verify');
    const el = document.getElementById('auditChainResult');
    if (result.valid) {
        el.innerHTML = `<div class="integrity-pass">INTEGRITY VERIFIED - Audit chain intact. No tampering detected. (${new Date().toLocaleString()})</div>`;
    } else {
        el.innerHTML = `<div class="integrity-fail">INTEGRITY COMPROMISED - Tampering detected at log #${result.broken_at_log_id}. ${result.message}</div>`;
    }
}

// ============================================================
// PDF EXPORT (AUDIT LOG)
// ============================================================
async function exportAuditPDF() {
    if (!auditData.length) await loadAuditLogs();
    try {
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF('l', 'mm', 'a4');

        // Header
        doc.setFontSize(20);
        doc.setTextColor(79, 70, 229);
        doc.text('MediChain - Immutable Audit Log', 14, 20);
        doc.setFontSize(10);
        doc.setTextColor(100);
        doc.text('Generated: ' + new Date().toLocaleString(), 14, 28);
        doc.text('Total Entries: ' + auditData.length, 14, 34);
        doc.text('Exported by: ' + (currentUser ? currentUser.username : 'Admin'), 14, 40);

        // Table
        doc.autoTable({
            startY: 46,
            head: [['ID', 'Time', 'User', 'Action', 'Table', 'Record', 'Notes', 'Hash (first 16)']],
            body: auditData.map(l => [
                l.log_id,
                fmtDate(l.event_time),
                l.username || 'System',
                l.action_type,
                l.table_name || '-',
                l.record_id || '-',
                (l.notes || '-').substring(0, 80),
                l.hash_value ? l.hash_value.substring(0, 16) : '-'
            ]),
            styles: { fontSize: 7, cellPadding: 2 },
            headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold' },
            alternateRowStyles: { fillColor: [245, 247, 250] },
            didDrawPage: function(data) {
                doc.setFontSize(8);
                doc.setTextColor(150);
                doc.text('MediChain Audit Log - Page ' + doc.internal.getCurrentPageInfo().pageNumber, 14, doc.internal.pageSize.height - 10);
                doc.text('CONFIDENTIAL - Tamper-Evident Blockchain Audit Trail', doc.internal.pageSize.width - 14, doc.internal.pageSize.height - 10, { align: 'right' });
            }
        });

        doc.save('MediChain_Audit_Log_' + new Date().toISOString().split('T')[0] + '.pdf');
        showToast('PDF exported successfully!', 'success');
    } catch (e) {
        showToast('PDF export failed: ' + e.message, 'error');
    }
}

// ============================================================
// DOCTOR PORTAL
// ============================================================
async function loadDocDashboard() {
    try {
        const data = await api('/api/doctor-portal/dashboard?doctor_id=' + currentUser.doctor_id);
        document.getElementById('docDashStats').innerHTML = `
            <div class="stat-card"><h3>My Patients</h3><div class="value">${data.my_patients}</div></div>
            <div class="stat-card green"><h3>My Encounters</h3><div class="value">${data.my_encounters}</div></div>
            <div class="stat-card cyan"><h3>Active Rx</h3><div class="value">${data.active_prescriptions}</div></div>
            <div class="stat-card yellow"><h3>Pending Labs</h3><div class="value">${data.pending_labs}</div></div>
            <div class="stat-card green"><h3>Completed Labs</h3><div class="value">${data.completed_labs}</div></div>
            <div class="stat-card red"><h3>Critical Alerts</h3><div class="value">${data.critical_alerts}</div></div>`;
        document.getElementById('docRecentEncounters').innerHTML = (data.recent_encounters || []).map(e => `<tr>
            <td>${e.encounter_id}</td>
            <td>${e.fname} ${e.lname} (${e.health_id})</td>
            <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
            <td>${fmtDate(e.encounter_date_time)}</td>
            <td>${e.hospital_name || '-'}</td>
        </tr>`).join('');
    } catch (e) { console.error('Doc dashboard error:', e); }
}

async function loadDocPatients() {
    const data = await api('/api/doctor-portal/my-patients?doctor_id=' + currentUser.doctor_id);
    document.getElementById('docPatientTable').innerHTML = data.map(p => `<tr>
        <td><strong>${p.health_id}</strong></td>
        <td>${p.fname} ${p.mname || ''} ${p.lname}</td>
        <td>${p.age || '-'}</td><td>${p.gender}</td><td>${p.blood_group || '-'}</td>
        <td>${p.address_city || '-'}</td>
        <td><button class="btn btn-outline btn-sm" onclick="docViewPatient('${p.health_id}')">View</button></td>
    </tr>`).join('');
}

async function docViewPatient(healthId) {
    try {
        const data = await api('/api/doctor-portal/patient-detail/' + encodeURIComponent(healthId) + '?doctor_id=' + currentUser.doctor_id);
        const p = data.patient;
        const allergies = data.allergies || [];
        let html = `<h3>${p.fname} ${p.mname || ''} ${p.lname}</h3>
            <p><strong>Health ID:</strong> ${p.health_id} | <strong>Age:</strong> ${p.age} (${p.age_category}) |
            <strong>Gender:</strong> ${p.gender === 'M' ? 'Male' : p.gender === 'F' ? 'Female' : 'Other'} | <strong>Blood Group:</strong> ${p.blood_group || 'N/A'}</p>
            <p><strong>Address:</strong> ${[p.address_street, p.address_city, p.address_state, p.postal_code].filter(Boolean).join(', ') || 'N/A'}</p>
            <p><strong>Emergency Contact:</strong> ${p.emergency_contact_name || 'N/A'} (${p.emergency_contact_phone || 'N/A'})</p>
            <p><strong>Insurance:</strong> ${p.insurance_provider || 'N/A'} | Policy: ${p.policy_type || 'N/A'}</p>
            <hr style="margin:15px 0;border:none;border-top:1px solid var(--border)">
            <h4>Active Allergies</h4>`;
        if (allergies.length === 0) html += '<p style="color:var(--text-muted)">No known allergies</p>';
        else html += '<table><thead><tr><th>Allergen</th><th>Severity</th><th>Reaction</th></tr></thead><tbody>' +
            allergies.map(a => `<tr><td>${a.allergen}</td><td><span class="badge badge-${a.severity === 'Severe' || a.severity === 'Life-threatening' ? 'critical' : 'pending'}">${a.severity}</span></td><td>${a.reaction_description || '-'}</td></tr>`).join('') +
            '</tbody></table>';
        showDetail('Patient Details', html);
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function loadDocEncounters() {
    await loadDropdowns();
    const data = await api('/api/doctor-portal/my-encounters?doctor_id=' + currentUser.doctor_id);
    document.getElementById('docEncounterTable').innerHTML = data.map(e => `<tr>
        <td>${e.encounter_id}</td>
        <td>${e.fname} ${e.lname} (${e.health_id})</td>
        <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
        <td>${fmtDate(e.encounter_date_time)}</td>
        <td>${e.hospital_name || '-'}</td>
        <td>${e.role || '-'} ${e.is_primary ? '(Primary)' : ''}</td>
        <td>
            <button class="btn btn-outline btn-sm" onclick="viewEncounter(${e.encounter_id})">Details</button>
            <button class="btn btn-success btn-sm" onclick="openVitals(${e.encounter_id})">Vitals</button>
        </td>
    </tr>`).join('');
}

async function loadDocPrescriptions() {
    await loadDropdowns();
    const data = await api('/api/doctor-portal/my-prescriptions?doctor_id=' + currentUser.doctor_id);
    document.getElementById('docPrescriptionTable').innerHTML = data.map(p => `<tr>
        <td>${p.prescription_id}</td>
        <td>${p.fname} ${p.lname} (${p.health_id})</td>
        <td>${p.prescription_date || '-'}</td>
        <td><span class="badge badge-${p.status === 'Active' ? 'active' : p.status === 'Completed' ? 'completed' : 'cancelled'}">${p.status}</span></td>
        <td>
            <button class="btn btn-outline btn-sm" onclick="viewPrescription(${p.prescription_id})">View</button>
            <button class="btn btn-primary btn-sm" onclick="openAddMed(${p.prescription_id}, '${p.health_id}')">+ Med</button>
            ${p.status === 'Active' ? `<button class="btn btn-warning btn-sm" onclick="updateRxStatus(${p.prescription_id},'Completed')">Complete</button>` : ''}
        </td>
    </tr>`).join('');
}

async function loadDocLab() {
    const data = await api('/api/doctor-portal/my-lab-orders?doctor_id=' + currentUser.doctor_id);
    await loadDropdowns();
    try {
        const catalog = await api('/api/lab/catalog');
        document.getElementById('loTest').innerHTML = catalog.map(t => `<option value="${t.test_code}">${t.test_name} (${t.test_code})</option>`).join('');
    } catch(e) {}
    document.getElementById('docLabTable').innerHTML = data.map(o => `<tr>
        <td>${o.lab_order_id}</td>
        <td>${o.fname} ${o.lname} (${o.health_id})</td>
        <td>${o.test_name}</td>
        <td><span class="badge badge-${(o.priority||'Routine').toLowerCase()}">${o.priority}</span></td>
        <td><span class="badge badge-${o.order_status === 'Completed' ? 'completed' : o.order_status === 'Pending' ? 'pending' : 'active'}">${o.order_status}</span></td>
        <td>${o.result_value ? o.result_value + ' ' + (o.result_unit || '') : '-'}</td>
        <td>${o.critical_flag ? '<span class="badge badge-critical">CRITICAL</span>' : o.abnormal_flag ? '<span class="badge badge-pending">Abnormal</span>' : '-'}</td>
    </tr>`).join('');
}

// ============================================================
// PATIENT PORTAL
// ============================================================
async function loadPatDashboard() {
    try {
        const data = await api('/api/patient-portal/dashboard?health_id=' + currentUser.health_id);
        document.getElementById('patDashStats').innerHTML = `
            <div class="stat-card"><h3>Total Encounters</h3><div class="value">${data.total_encounters}</div></div>
            <div class="stat-card green"><h3>Active Rx</h3><div class="value">${data.active_prescriptions}</div></div>
            <div class="stat-card yellow"><h3>Pending Labs</h3><div class="value">${data.pending_labs}</div></div>
            <div class="stat-card green"><h3>Completed Labs</h3><div class="value">${data.completed_labs}</div></div>
            <div class="stat-card cyan"><h3>Active Consents</h3><div class="value">${data.active_consents}</div></div>
            <div class="stat-card red"><h3>Allergies</h3><div class="value">${data.allergies}</div></div>`;

        document.getElementById('patRecentEncounters').innerHTML = (data.recent_encounters || []).map(e => `<tr>
            <td>${fmtDate(e.encounter_date_time)}</td>
            <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
            <td>${e.hospital_name || '-'}</td>
            <td>${e.doctors || '-'}</td>
        </tr>`).join('');

        document.getElementById('patAllergyTable').innerHTML = (data.active_allergies || []).map(a => `<tr>
            <td>${a.allergen}</td>
            <td><span class="badge badge-${a.severity === 'Severe' || a.severity === 'Life-threatening' ? 'critical' : 'pending'}">${a.severity}</span></td>
            <td>${a.reaction_description || '-'}</td>
        </tr>`).join('') || '<tr><td colspan="3" style="text-align:center;color:var(--text-muted)">No known allergies</td></tr>';
    } catch (e) { console.error('Patient dashboard error:', e); }
}

async function loadPatProfile() {
    try {
        const data = await api('/api/patient-portal/profile?health_id=' + currentUser.health_id);
        const p = data.patient;
        window._patProfile = p; // Cache for edit modal
        const allergies = data.allergies || [];
        let html = `<div class="profile-card">
            <div><div class="profile-avatar">${(p.fname||'?')[0]}${(p.lname||'?')[0]}</div></div>
            <div class="profile-info">
                <h2>${p.fname} ${p.mname || ''} ${p.lname}</h2>
                <div class="profile-id">Health ID: ${p.health_id} | Age: ${p.age}</div>
                <div class="profile-detail-grid">
                    <div class="profile-detail"><label>Gender</label><span>${p.gender === 'M' ? 'Male' : p.gender === 'F' ? 'Female' : 'Other'}</span></div>
                    <div class="profile-detail"><label>Blood Group</label><span>${p.blood_group || 'N/A'}</span></div>
                    <div class="profile-detail"><label>Date of Birth</label><span>${p.date_of_birth || 'N/A'}</span></div>
                    <div class="profile-detail"><label>Street</label><span>${p.address_street || 'N/A'}</span></div>
                    <div class="profile-detail"><label>City</label><span>${p.address_city || 'N/A'}</span></div>
                    <div class="profile-detail"><label>State</label><span>${p.address_state || 'N/A'}</span></div>
                    <div class="profile-detail"><label>Postal Code</label><span>${p.postal_code || 'N/A'}</span></div>
                    <div class="profile-detail"><label>Emergency Contact</label><span>${p.emergency_contact_name || 'N/A'} (${p.emergency_contact_phone || 'N/A'})</span></div>
                    <div class="profile-detail"><label>Insurance</label><span>${p.insurance_provider || 'N/A'}</span></div>
                    <div class="profile-detail"><label>Policy Type</label><span>${p.policy_type || 'N/A'}</span></div>
                    <div class="profile-detail"><label>Insurance Period</label><span>${p.insurance_start || 'N/A'} to ${p.insurance_end || 'N/A'}</span></div>
                </div>
                <button class="btn btn-primary" style="margin-top:16px" onclick="openPatProfileEdit()">Edit Profile</button>
            </div>
        </div>`;
        document.getElementById('patProfileCard').innerHTML = html;
    } catch (e) { console.error('Profile error:', e); }
}

function openPatProfileEdit() {
    const p = window._patProfile;
    if (!p) return;
    document.getElementById('patEditStreet').value = p.address_street || '';
    document.getElementById('patEditCity').value = p.address_city || '';
    document.getElementById('patEditState').value = p.address_state || '';
    document.getElementById('patEditPostal').value = p.postal_code || '';
    document.getElementById('patEditEmName').value = p.emergency_contact_name || '';
    document.getElementById('patEditEmPhone').value = p.emergency_contact_phone || '';
    document.getElementById('patEditInsProvider').value = p.insurance_provider || '';
    document.getElementById('patEditPolicyType').value = p.policy_type || '';
    document.getElementById('patEditInsStart').value = p.insurance_start || '';
    document.getElementById('patEditInsEnd').value = p.insurance_end || '';
    showModal('patProfileEditModal');
}

async function updatePatProfile() {
    try {
        await api('/api/patient-portal/update-profile', 'PUT', {
            health_id: currentUser.health_id,
            address_street: document.getElementById('patEditStreet').value || null,
            address_city: document.getElementById('patEditCity').value || null,
            address_state: document.getElementById('patEditState').value || null,
            postal_code: document.getElementById('patEditPostal').value || null,
            emergency_contact_name: document.getElementById('patEditEmName').value || null,
            emergency_contact_phone: document.getElementById('patEditEmPhone').value || null,
            insurance_provider: document.getElementById('patEditInsProvider').value || null,
            insurance_start: document.getElementById('patEditInsStart').value || null,
            insurance_end: document.getElementById('patEditInsEnd').value || null,
            policy_type: document.getElementById('patEditPolicyType').value || null
        });
        closeModal('patProfileEditModal');
        loadPatProfile();
        showToast('Profile updated successfully!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function loadPatEncounters() {
    const data = await api('/api/patient-portal/my-encounters?health_id=' + currentUser.health_id);
    document.getElementById('patEncounterTable').innerHTML = data.map(e => `<tr>
        <td>${fmtDate(e.encounter_date_time)}</td>
        <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
        <td>${e.hospital_name || '-'}</td>
        <td>${e.doctors || '-'}</td>
        <td style="max-width:250px;font-size:0.78rem">${e.diagnoses || '-'}</td>
        <td><button class="btn btn-outline btn-sm" onclick="patViewEncounter(${e.encounter_id})">Details</button></td>
    </tr>`).join('');
}

async function patViewEncounter(id) {
    try {
        const e = await api('/api/patient-portal/encounter/' + id + '?health_id=' + currentUser.health_id);
        let html = `<h3>Encounter #${e.encounter_id} - ${e.encounter_type}</h3>
            <p><strong>Patient:</strong> ${e.fname} ${e.lname} (${e.health_id}) | <strong>Hospital:</strong> ${e.hospital_name || 'N/A'}</p>
            <p><strong>Date:</strong> ${fmtDate(e.encounter_date_time)} | <strong>Complaint:</strong> ${e.chief_complaint || 'N/A'}</p>
            <p><strong>Treatment Plan:</strong> ${e.treatment_plan || 'N/A'}</p>`;
        if (e.doctors && e.doctors.length) {
            html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Assigned Doctors</h4><table><thead><tr><th>Name</th><th>Specialization</th><th>Role</th><th>Primary</th></tr></thead><tbody>';
            html += e.doctors.map(d => `<tr><td>${d.name}</td><td>${d.specialization || '-'}</td><td>${d.role || '-'}</td><td>${d.is_primary ? 'Yes' : 'No'}</td></tr>`).join('') + '</tbody></table>';
        }
        if (e.vitals && e.vitals.length) {
            html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Vital Signs</h4><table><thead><tr><th>Time</th><th>BP</th><th>Pulse</th><th>Temp</th><th>RR</th><th>O2</th></tr></thead><tbody>';
            html += e.vitals.map(v => `<tr><td>${fmtDate(v.reading_timestamp)}</td><td>${v.bp_systolic || '-'}/${v.bp_diastolic || '-'}</td><td>${v.pulse || '-'}</td><td>${v.temperature || '-'}</td><td>${v.respiratory_rate || '-'}</td><td>${v.oxygen_saturation || '-'}%</td></tr>`).join('') + '</tbody></table>';
        }
        if (e.diagnoses && e.diagnoses.length) {
            html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Diagnoses</h4><table><thead><tr><th>ICD-10</th><th>Description</th><th>Type</th><th>Status</th></tr></thead><tbody>';
            html += e.diagnoses.map(d => `<tr><td>${d.icd10_code}</td><td>${d.description}</td><td>${d.diagnosis_type}</td><td>${d.status}</td></tr>`).join('') + '</tbody></table>';
        }
        if (e.procedures && e.procedures.length) {
            html += '<hr style="margin:12px 0;border:none;border-top:1px solid var(--border)"><h4>Procedures</h4><table><thead><tr><th>CPT Code</th><th>Description</th><th>Category</th><th>Cost</th></tr></thead><tbody>';
            html += e.procedures.map(p => `<tr><td>${p.cpt_code}</td><td>${p.description}</td><td>${p.category || '-'}</td><td>${p.base_cost ? '₹' + p.base_cost : '-'}</td></tr>`).join('') + '</tbody></table>';
        }
        showDetail('Encounter Details', html);
    } catch (e) { showToast('Error loading encounter: ' + e.message, 'error'); }
}

async function loadPatPrescriptions() {
    const data = await api('/api/patient-portal/my-prescriptions?health_id=' + currentUser.health_id);
    if (data.length === 0) {
        document.getElementById('patPrescriptionList').innerHTML = '<div class="card"><div class="card-body-padded empty-state"><h4>No prescriptions found</h4></div></div>';
        return;
    }
    document.getElementById('patPrescriptionList').innerHTML = data.map(rx => {
        let html = `<div class="card mb-20">
            <div class="card-header">
                <h3>Prescription #${rx.prescription_id}</h3>
                <span class="badge badge-${rx.status === 'Active' ? 'active' : rx.status === 'Completed' ? 'completed' : 'cancelled'}">${rx.status}</span>
            </div>
            <div class="card-body-padded">
                <p style="margin-bottom:12px"><strong>Doctor:</strong> ${rx.doctor_name} (${rx.specialization || 'General'}) | <strong>Date:</strong> ${rx.prescription_date || '-'} | <strong>Period:</strong> ${rx.start_date || '-'} to ${rx.end_date || 'Ongoing'}</p>`;
        if (rx.items && rx.items.length) {
            html += '<table><thead><tr><th>Medication</th><th>Dosage</th><th>Frequency</th><th>Duration</th><th>Instructions</th></tr></thead><tbody>';
            html += rx.items.map(i => `<tr><td><strong>${i.generic_name}</strong> (${i.brand_name || '-'})<br><small style="color:var(--text-muted)">${i.drug_class || ''}</small></td><td>${i.dosage_strength || '-'} ${i.dosage_form || ''}</td><td>${i.frequency || '-'}</td><td>${i.duration_days || '-'} days</td><td>${i.instructions || '-'}</td></tr>`).join('') + '</tbody></table>';
        } else html += '<p style="color:var(--text-muted)">No medications</p>';
        html += '</div></div>';
        return html;
    }).join('');
}

async function loadPatLab() {
    const data = await api('/api/patient-portal/my-lab-results?health_id=' + currentUser.health_id);
    document.getElementById('patLabTable').innerHTML = data.map(o => `<tr>
        <td>${fmtDate(o.order_date_time)}</td>
        <td>${o.test_name}</td>
        <td>${o.doctor_name}</td>
        <td><span class="badge badge-${o.order_status === 'Completed' ? 'completed' : 'pending'}">${o.order_status}</span></td>
        <td>${o.result_value ? o.result_value + ' ' + (o.result_unit || '') : '-'}</td>
        <td>${o.abnormal_flag ? '<span class="badge badge-pending">Yes</span>' : 'Normal'}</td>
        <td>${o.critical_flag ? '<span class="badge badge-critical">CRITICAL</span>' : '-'}</td>
    </tr>`).join('');
}

async function loadPatConsents() {
    const data = await api('/api/patient-portal/my-consents?health_id=' + currentUser.health_id);
    window._patConsents = data; // Cache for edit
    document.getElementById('patConsentTable').innerHTML = data.map(c => `<tr>
        <td>${c.hospital_name}</td>
        <td>${c.access_level}</td>
        <td>${c.purpose || '-'}</td>
        <td>${c.effective_date}</td>
        <td>${c.expiration_date || 'Never'}</td>
        <td><span class="badge badge-${c.status === 'Active' ? 'active' : c.status === 'Expired' ? 'pending' : 'cancelled'}">${c.status}</span></td>
        <td>${c.status === 'Active' ? `<button class="btn btn-outline btn-sm" onclick="patEditConsent(${c.consent_id})" style="margin-right:4px">Edit</button><button class="btn btn-danger btn-sm" onclick="patRevokeConsent(${c.consent_id})">Revoke</button>` : '-'}</td>
    </tr>`).join('');

    // Load hospitals for the grant consent modal
    try {
        const hospitals = await api('/api/patient-portal/hospitals');
        const sel = document.getElementById('patCHospital');
        if (sel) sel.innerHTML = '<option value="">-- Select Hospital --</option>' +
            hospitals.map(h => `<option value="${h.hospital_id}">${h.hospital_name} (${h.address_city || ''})</option>`).join('');
    } catch(e) {}
}

async function patRevokeConsent(consentId) {
    if (!confirm('Are you sure you want to revoke this consent? This will immediately prevent this hospital from accessing your records.')) return;
    try {
        await api('/api/patient-portal/revoke-consent/' + consentId + '?health_id=' + currentUser.health_id, 'PUT');
        loadPatConsents();
        showToast('Consent revoked successfully. Access has been immediately removed.', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function patGrantConsent() {
    try {
        const effectiveDate = document.getElementById('patCEffective').value;
        if (!effectiveDate) { showToast('Effective date is required', 'error'); return; }
        const hospitalId = document.getElementById('patCHospital').value;
        if (!hospitalId) { showToast('Please select a hospital', 'error'); return; }

        await api('/api/patient-portal/grant-consent', 'POST', {
            health_id: currentUser.health_id,
            hospital_id: parseInt(hospitalId),
            access_level: document.getElementById('patCAccess').value,
            purpose: document.getElementById('patCPurpose').value || null,
            effective_date: effectiveDate,
            expiration_date: document.getElementById('patCExpiration').value || null
        });
        closeModal('patConsentModal');
        loadPatConsents();
        showToast('Consent granted successfully!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

function patEditConsent(consentId) {
    const c = (window._patConsents || []).find(x => x.consent_id === consentId);
    if (!c) return;
    document.getElementById('patCEditId').value = consentId;
    document.getElementById('patCEditHospital').value = c.hospital_name;
    document.getElementById('patCEditAccess').value = c.access_level;
    document.getElementById('patCEditPurpose').value = c.purpose || '';
    document.getElementById('patCEditExpiration').value = c.expiration_date || '';
    showModal('patConsentEditModal');
}

async function patUpdateConsent() {
    try {
        const consentId = document.getElementById('patCEditId').value;
        await api('/api/patient-portal/update-consent/' + consentId, 'PUT', {
            health_id: currentUser.health_id,
            access_level: document.getElementById('patCEditAccess').value,
            purpose: document.getElementById('patCEditPurpose').value || null,
            expiration_date: document.getElementById('patCEditExpiration').value || null
        });
        closeModal('patConsentEditModal');
        loadPatConsents();
        showToast('Consent updated successfully!', 'success');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// ADMIN: TRANSACTION DEMO
// ============================================================
async function runTransactionTests() {
    const container = document.getElementById('txnResults');
    container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--text-muted)"><div class="loading-spinner"></div><p>Running 6 transaction tests against the database...</p></div>';
    document.getElementById('txnRunBtn').disabled = true;
    document.getElementById('txnRunBtn').textContent = 'Running...';

    try {
        const tests = await api('/api/transaction-demo/run-all');
        let html = '';
        let passed = 0;
        let failed = 0;

        tests.forEach((t, idx) => {
            const isPass = t.status === 'PASS';
            if (isPass) passed++; else failed++;
            html += `<div class="card mb-20" style="border-left:4px solid ${isPass ? 'var(--success)' : 'var(--danger)'}">
                <div class="card-header" style="cursor:pointer" onclick="document.getElementById('txnDetail${idx}').classList.toggle('hidden')">
                    <h3>
                        <span class="badge badge-${isPass ? 'active' : 'critical'}" style="margin-right:8px">${t.status}</span>
                        Test ${idx + 1}: ${t.test_name}
                    </h3>
                    <span style="font-size:0.82rem;color:var(--text-muted)">Click to expand</span>
                </div>
                <div class="card-body-padded">
                    <p style="margin-bottom:12px;color:var(--text-muted);font-size:0.88rem"><strong>Description:</strong> ${t.description}</p>
                    <div id="txnDetail${idx}" class="hidden">
                        <div style="background:var(--bg);border:1px solid var(--border);border-radius:var(--radius);padding:16px;margin-bottom:12px;font-family:monospace;font-size:0.82rem;line-height:1.7;overflow-x:auto">`;
            (t.steps || []).forEach(step => {
                let color = 'var(--text)';
                if (step.startsWith('ERROR') || step.includes('ERROR:')) color = 'var(--danger)';
                else if (step.includes('COMMIT')) color = 'var(--success)';
                else if (step.includes('ROLLBACK')) color = '#e67e22';
                else if (step.startsWith('[Txn A]')) color = 'var(--primary)';
                else if (step.startsWith('[Txn B]')) color = '#06b6d4';
                else if (step.startsWith('SETUP') || step.startsWith('CLEANUP') || step.startsWith('FINAL')) color = '#94a3b8';
                html += `<div style="color:${color}">${step}</div>`;
            });
            html += `</div>
                        <div class="alert alert-${isPass ? 'success' : 'danger'}"><strong>Conclusion:</strong> ${t.conclusion || t.error || 'N/A'}</div>
                    </div>
                </div>
            </div>`;
        });

        // Summary at top
        const summary = `<div class="stats-grid mb-20">
            <div class="stat-card green"><h3>Tests Passed</h3><div class="value">${passed}</div></div>
            <div class="stat-card red"><h3>Tests Failed</h3><div class="value">${failed}</div></div>
            <div class="stat-card cyan"><h3>Total Tests</h3><div class="value">${tests.length}</div></div>
        </div>
        <div class="alert alert-info mb-20" style="font-size:0.88rem">
            <strong>What this demonstrates:</strong> These tests execute real SQL transactions against the database showing ACID properties:
            <strong>Atomicity</strong> (all-or-nothing commits/rollbacks),
            <strong>Consistency</strong> (constraint violations trigger rollback),
            <strong>Isolation</strong> (concurrent transactions cannot see uncommitted data), and
            <strong>Durability</strong> (committed data persists).
            Click each test to expand the step-by-step SQL execution log.
        </div>`;

        container.innerHTML = summary + html;
    } catch (e) {
        container.innerHTML = '<div class="alert alert-danger">Error running tests: ' + e.message + '</div>';
    } finally {
        document.getElementById('txnRunBtn').disabled = false;
        document.getElementById('txnRunBtn').textContent = 'Run All Transaction Tests';
    }
}

// ============================================================
// DROPDOWN LOADERS
// ============================================================
async function loadDropdowns() {
    if (currentUser.role === 'doctor') {
        // Doctor uses own patients and self as doctor
        if (!cachedData.patients) cachedData.patients = await api('/api/doctor-portal/my-patients?doctor_id=' + currentUser.doctor_id);
        if (!cachedData.hospitals) cachedData.hospitals = await api('/api/hospitals');
        cachedData.doctors = [{ doctor_id: currentUser.doctor_id, name: currentUser.username, specialization: '' }];
    } else {
        if (!cachedData.patients) cachedData.patients = await api('/api/patients');
        if (!cachedData.doctors) cachedData.doctors = await api('/api/doctors');
        if (!cachedData.hospitals) cachedData.hospitals = await api('/api/hospitals');
    }

    const patientOpts = cachedData.patients.map(p => `<option value="${p.health_id}">${p.fname} ${p.lname} (${p.health_id})</option>`).join('');
    ['eHealthId', 'cPatient', 'emPatient'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.innerHTML = '<option value="">-- Select --</option>' + patientOpts;
    });

    const doctorOpts = cachedData.doctors.map(d => `<option value="${d.doctor_id}">${d.name} (${d.specialization || 'General'})</option>`).join('');
    ['eDoctor', 'rxDoctor', 'loDoctor', 'emDoctor'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.innerHTML = '<option value="">-- Select --</option>' + doctorOpts;
    });

    const hospitalOpts = cachedData.hospitals.map(h => `<option value="${h.hospital_id}">${h.hospital_name}</option>`).join('');
    ['eHospital', 'cHospital'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.innerHTML = '<option value="">-- Select --</option>' + hospitalOpts;
    });
}

// ============================================================
// DETAIL MODAL HELPER
// ============================================================
function showDetail(title, html) {
    document.getElementById('detailModalTitle').textContent = title;
    document.getElementById('detailModalBody').innerHTML = html;
    showModal('detailModal');
}

// ============================================================
// UTILITY
// ============================================================
function gv(id) { return document.getElementById(id).value; }
function intOrNull(id) { const v = gv(id); return v ? parseInt(v) : null; }
function floatOrNull(id) { const v = gv(id); return v ? parseFloat(v) : null; }
function fmtDate(d) {
    if (!d) return '-';
    const dt = new Date(d);
    return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) + ' ' +
           dt.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
}

// ============================================================
// SVG ICONS
// ============================================================
function iconDashboard() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>'; }
function iconPatients() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>'; }
function iconDoctors() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>'; }
function iconHospitals() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M12 8v8"/><path d="M8 12h8"/></svg>'; }
function iconEncounters() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>'; }
function iconPrescriptions() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2z"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>'; }
function iconLab() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 3v7.2a4 4 0 0 1-1.2 2.8L4 17h16l-3.8-4a4 4 0 0 1-1.2-2.8V3"/><path d="M7 3h10"/></svg>'; }
function iconConsent() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>'; }
function iconAudit() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>'; }
function iconProfile() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>'; }
function iconSearch() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>'; }
function iconTxn() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16v16H4z"/><path d="M4 12h16"/><path d="M12 4v16"/></svg>'; }

// ============================================================
// DOCTOR: PATIENT LOOKUP
// ============================================================
async function searchAllPatients() {
    const q = document.getElementById('lookupHealthId').value.trim();
    if (!q) { showToast('Please enter a Health ID or name', 'error'); return; }

    try {
        const data = await api('/api/doctor-portal/search-patients?q=' + encodeURIComponent(q) + '&doctor_id=' + currentUser.doctor_id);
        const container = document.getElementById('lookupSearchResults');
        container.classList.remove('hidden');
        document.getElementById('lookupResult').innerHTML = '';

        if (data.length === 0) {
            document.getElementById('lookupSearchTable').innerHTML = '<tr><td colspan="7" style="text-align:center;color:var(--text-muted)">No patients found</td></tr>';
            return;
        }

        document.getElementById('lookupSearchTable').innerHTML = data.map(p => {
            let accessBadge, actions;
            if (p.has_full_access) {
                accessBadge = '<span class="badge badge-active">Full Access</span>';
                actions = `<button class="btn btn-outline btn-sm" onclick="lookupPatientHistory('${p.health_id}')">View History</button>`;
            } else if (p.has_pending_request) {
                accessBadge = '<span class="badge badge-pending">Request Pending</span>';
                actions = `<button class="btn btn-warning btn-sm" disabled>Awaiting Approval</button>
                    <button class="btn btn-danger btn-sm" onclick="openEmergencyAccess('${p.health_id}', '${p.fname} ${p.lname}')">Emergency Access</button>`;
            } else if (p.has_treated) {
                accessBadge = '<span class="badge badge-pending">No Consent</span>';
                actions = `<button class="btn btn-primary btn-sm" onclick="openRegularAccess('${p.health_id}', '${p.fname} ${p.lname}')">Request Access</button>
                    <button class="btn btn-danger btn-sm" onclick="openEmergencyAccess('${p.health_id}', '${p.fname} ${p.lname}')">Emergency Access</button>`;
            } else {
                accessBadge = '<span class="badge badge-cancelled">No Relationship</span>';
                actions = `<button class="btn btn-primary btn-sm" onclick="openRegularAccess('${p.health_id}', '${p.fname} ${p.lname}')">Request Access</button>
                    <button class="btn btn-danger btn-sm" onclick="openEmergencyAccess('${p.health_id}', '${p.fname} ${p.lname}')">Emergency Access</button>`;
            }
            return `<tr>
                <td><strong>${p.health_id}</strong></td>
                <td>${p.fname} ${p.lname}</td>
                <td>${p.age || '-'}</td>
                <td>${p.gender === 'M' ? 'Male' : p.gender === 'F' ? 'Female' : 'Other'}</td>
                <td>${p.blood_group || '-'}</td>
                <td>${accessBadge}</td>
                <td>${actions}</td>
            </tr>`;
        }).join('');
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

function openEmergencyAccess(healthId, patientName) {
    document.getElementById('emAccessHealthId').value = healthId;
    document.getElementById('emAccessPatientName').value = patientName + ' (' + healthId + ')';
    document.getElementById('emAccessType').value = '';
    document.getElementById('emAccessJustification').value = '';
    showModal('emergencyAccessModal');
}

async function submitEmergencyAccess() {
    const healthId = document.getElementById('emAccessHealthId').value;
    const emergencyType = document.getElementById('emAccessType').value;
    const justification = document.getElementById('emAccessJustification').value;

    if (!emergencyType) { showToast('Please select an emergency type', 'error'); return; }
    if (!justification || justification.trim().length < 20) {
        showToast('Justification must be at least 20 characters', 'error'); return;
    }

    try {
        const result = await api('/api/doctor-portal/emergency-access', 'POST', {
            health_id: healthId,
            doctor_id: currentUser.doctor_id,
            emergency_type: emergencyType,
            justification: justification
        });
        closeModal('emergencyAccessModal');
        showToast(result.message, 'success');
        // Refresh search results and auto-load the patient history
        searchAllPatients();
        setTimeout(() => lookupPatientHistory(healthId), 500);
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// DOCTOR: REGULAR ACCESS REQUEST
// ============================================================
function openRegularAccess(healthId, patientName) {
    document.getElementById('regAccessHealthId').value = healthId;
    document.getElementById('regAccessPatientName').value = patientName + ' (' + healthId + ')';
    document.getElementById('regAccessReason').value = '';
    showModal('regularAccessModal');
}

async function submitRegularAccess() {
    const healthId = document.getElementById('regAccessHealthId').value;
    const reason = document.getElementById('regAccessReason').value;

    if (!reason || reason.trim().length < 10) {
        showToast('Reason must be at least 10 characters', 'error'); return;
    }

    try {
        const result = await api('/api/doctor-portal/request-access', 'POST', {
            health_id: healthId,
            doctor_id: currentUser.doctor_id,
            reason: reason
        });
        closeModal('regularAccessModal');
        showToast(result.message, 'success');
        searchAllPatients();
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

// ============================================================
// PATIENT: ACCESS REQUESTS
// ============================================================
async function loadPatAccessRequests() {
    try {
        const data = await api('/api/patient-portal/access-requests?health_id=' + currentUser.health_id);
        const pending = data.filter(r => r.status === 'Pending');
        const responded = data.filter(r => r.status !== 'Pending');

        let html = '';
        if (pending.length > 0) {
            html += '<div class="card mb-20" style="border-left:4px solid var(--primary)"><div class="card-header"><h3>Pending Access Requests (' + pending.length + ')</h3></div><div class="card-body table-container">';
            html += '<table><thead><tr><th>Doctor</th><th>Specialization</th><th>Reason</th><th>Requested</th><th>Actions</th></tr></thead><tbody>';
            html += pending.map(r => `<tr>
                <td><strong>${r.doctor_name}</strong></td>
                <td>${r.specialization || '-'}</td>
                <td style="max-width:250px;font-size:0.85rem">${r.request_reason}</td>
                <td>${fmtDate(r.request_time)}</td>
                <td>
                    <button class="btn btn-success btn-sm" onclick="respondAccessRequest(${r.request_id}, 'approve')">Approve</button>
                    <button class="btn btn-danger btn-sm" onclick="respondAccessRequest(${r.request_id}, 'deny')">Deny</button>
                </td>
            </tr>`).join('') + '</tbody></table></div></div>';
        } else {
            html += '<div class="card mb-20"><div class="card-body-padded" style="text-align:center;color:var(--text-muted);padding:24px">No pending access requests</div></div>';
        }

        if (responded.length > 0) {
            html += '<div class="card"><div class="card-header"><h3>Past Requests</h3></div><div class="card-body table-container">';
            html += '<table><thead><tr><th>Doctor</th><th>Specialization</th><th>Reason</th><th>Requested</th><th>Status</th><th>Responded</th></tr></thead><tbody>';
            html += responded.map(r => `<tr>
                <td>${r.doctor_name}</td>
                <td>${r.specialization || '-'}</td>
                <td style="max-width:250px;font-size:0.85rem">${r.request_reason}</td>
                <td>${fmtDate(r.request_time)}</td>
                <td><span class="badge badge-${r.status === 'Approved' ? 'active' : 'critical'}">${r.status}</span></td>
                <td>${r.responded_at ? fmtDate(r.responded_at) : '-'}</td>
            </tr>`).join('') + '</tbody></table></div></div>';
        }

        document.getElementById('patAccessRequestList').innerHTML = html;
    } catch (e) { console.error('Access requests error:', e); }
}

async function respondAccessRequest(requestId, action) {
    const label = action === 'approve' ? 'approve access for this doctor' : 'deny this access request';
    if (!confirm('Are you sure you want to ' + label + '?')) return;
    try {
        const result = await api('/api/patient-portal/access-requests/' + requestId + '/respond', 'PUT', {
            health_id: currentUser.health_id,
            action: action
        });
        showToast(result.message, 'success');
        loadPatAccessRequests();
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
}

async function lookupPatientHistory(healthId) {
    if (!healthId) healthId = document.getElementById('lookupHealthId').value.trim();
    if (!healthId) { showToast('Please enter a Health ID', 'error'); return; }

    const container = document.getElementById('lookupResult');
    container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--text-muted)"><div class="loading-spinner"></div><p>Loading patient history...</p></div>';

    try {
        const data = await api('/api/doctor-portal/patient-history?health_id=' + encodeURIComponent(healthId) + '&doctor_id=' + currentUser.doctor_id);
        const p = data.patient;
        let html = '';

        // Patient Profile Card
        html += `<div class="card mb-20"><div class="card-body-padded">
            <div class="profile-card">
                <div><div class="profile-avatar">${(p.fname||'?')[0]}${(p.lname||'?')[0]}</div></div>
                <div class="profile-info">
                    <h2>${p.fname} ${p.mname || ''} ${p.lname}</h2>
                    <div class="profile-id">Health ID: ${p.health_id} | Age: ${p.age} (${p.age_category}) | Gender: ${p.gender === 'M' ? 'Male' : p.gender === 'F' ? 'Female' : 'Other'} | Blood: ${p.blood_group || 'N/A'}</div>
                    <div style="margin-top:8px;color:var(--text-muted)">
                        ${p.address_city ? p.address_city + ', ' + (p.address_state || '') : 'N/A'} |
                        Emergency: ${p.emergency_contact_name || 'N/A'} (${p.emergency_contact_phone || 'N/A'}) |
                        Insurance: ${p.insurance_provider || 'None'}
                    </div>
                </div>
            </div>
        </div></div>`;

        // Active Allergies
        const allergies = data.allergies || [];
        if (allergies.length > 0) {
            html += `<div class="card mb-20" style="border-left:4px solid var(--danger)"><div class="card-header"><h3 style="color:var(--danger)">Active Allergies (${allergies.length})</h3></div><div class="card-body table-container">
                <table><thead><tr><th>Allergen</th><th>Severity</th><th>Reaction</th><th>Since</th></tr></thead><tbody>`;
            html += allergies.map(a => `<tr>
                <td><strong>${a.allergen}</strong></td>
                <td><span class="badge badge-${a.severity === 'Severe' || a.severity === 'Life-threatening' ? 'critical' : 'pending'}">${a.severity}</span></td>
                <td>${a.reaction_description || '-'}</td>
                <td>${a.identified_date || '-'}</td>
            </tr>`).join('') + '</tbody></table></div></div>';
        }

        // Recent Vitals
        const vitals = data.vitals || [];
        if (vitals.length > 0) {
            html += `<div class="card mb-20"><div class="card-header"><h3>Recent Vital Signs</h3></div><div class="card-body table-container">
                <table><thead><tr><th>Date</th><th>BP</th><th>Pulse</th><th>Temp</th><th>RR</th><th>O2 Sat</th><th>Height</th><th>Weight</th></tr></thead><tbody>`;
            html += vitals.map(v => `<tr>
                <td>${fmtDate(v.reading_timestamp)}</td>
                <td>${v.bp_systolic || '-'}/${v.bp_diastolic || '-'}</td>
                <td>${v.pulse || '-'}</td>
                <td>${v.temperature || '-'}&deg;C</td>
                <td>${v.respiratory_rate || '-'}</td>
                <td>${v.oxygen_saturation || '-'}%</td>
                <td>${v.height || '-'} cm</td>
                <td>${v.weight || '-'} kg</td>
            </tr>`).join('') + '</tbody></table></div></div>';
        }

        // Encounters
        const encounters = data.encounters || [];
        html += `<div class="card mb-20"><div class="card-header"><h3>Encounter History (${encounters.length})</h3></div><div class="card-body table-container">
            <table><thead><tr><th>Date</th><th>Type</th><th>Hospital</th><th>Doctors</th><th>Chief Complaint</th><th>Diagnoses</th></tr></thead><tbody>`;
        if (encounters.length === 0) html += '<tr><td colspan="6" style="text-align:center;color:var(--text-muted)">No encounters</td></tr>';
        else html += encounters.map(e => `<tr>
            <td>${fmtDate(e.encounter_date_time)}</td>
            <td><span class="badge badge-${e.encounter_type === 'Emergency' ? 'critical' : 'active'}">${e.encounter_type}</span></td>
            <td>${e.hospital_name || '-'}</td>
            <td>${e.doctors || '-'}</td>
            <td style="max-width:200px;font-size:0.8rem">${e.chief_complaint || '-'}</td>
            <td style="max-width:200px;font-size:0.8rem">${e.diagnoses || '-'}</td>
        </tr>`).join('');
        html += '</tbody></table></div></div>';

        // Prescriptions
        const prescriptions = data.prescriptions || [];
        html += `<div class="card mb-20"><div class="card-header"><h3>Prescriptions (${prescriptions.length})</h3></div><div class="card-body-padded">`;
        if (prescriptions.length === 0) html += '<p style="color:var(--text-muted)">No prescriptions</p>';
        else prescriptions.forEach(rx => {
            html += `<div style="border:1px solid var(--border);border-radius:var(--radius);padding:12px;margin-bottom:12px">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
                    <strong>Rx #${rx.prescription_id}</strong>
                    <span class="badge badge-${rx.status === 'Active' ? 'active' : rx.status === 'Completed' ? 'completed' : 'cancelled'}">${rx.status}</span>
                </div>
                <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:8px">Dr. ${rx.doctor_name} (${rx.specialization || 'General'}) | ${rx.prescription_date || '-'} | ${rx.start_date || '-'} to ${rx.end_date || 'Ongoing'}</p>`;
            if (rx.items && rx.items.length) {
                html += '<table style="font-size:0.82rem"><thead><tr><th>Medication</th><th>Dosage</th><th>Frequency</th><th>Duration</th></tr></thead><tbody>';
                html += rx.items.map(i => `<tr><td>${i.generic_name} (${i.brand_name || '-'})</td><td>${i.dosage_strength || '-'} ${i.dosage_form || ''}</td><td>${i.frequency || '-'}</td><td>${i.duration_days || '-'} days</td></tr>`).join('') + '</tbody></table>';
            }
            html += '</div>';
        });
        html += '</div></div>';

        // Lab Results
        const labs = data.lab_results || [];
        html += `<div class="card mb-20"><div class="card-header"><h3>Lab Results (${labs.length})</h3></div><div class="card-body table-container">
            <table><thead><tr><th>Date</th><th>Test</th><th>Doctor</th><th>Status</th><th>Result</th><th>Reference</th><th>Abnormal</th><th>Critical</th></tr></thead><tbody>`;
        if (labs.length === 0) html += '<tr><td colspan="8" style="text-align:center;color:var(--text-muted)">No lab results</td></tr>';
        else html += labs.map(o => `<tr>
            <td>${fmtDate(o.order_date_time)}</td>
            <td>${o.test_name}</td>
            <td>${o.doctor_name}</td>
            <td><span class="badge badge-${o.order_status === 'Completed' ? 'completed' : 'pending'}">${o.order_status}</span></td>
            <td>${o.result_value ? '<strong>' + o.result_value + '</strong> ' + (o.result_unit || '') : '-'}</td>
            <td>${o.reference_range || '-'}</td>
            <td>${o.abnormal_flag ? '<span class="badge badge-pending">Yes</span>' : 'Normal'}</td>
            <td>${o.critical_flag ? '<span class="badge badge-critical">CRITICAL</span>' : '-'}</td>
        </tr>`).join('');
        html += '</tbody></table></div></div>';

        container.innerHTML = html;
    } catch (e) {
        container.innerHTML = `<div class="card"><div class="card-body-padded" style="text-align:center;padding:40px">
            <h3 style="color:var(--danger)">Access Denied</h3>
            <p style="color:var(--text-muted);margin-top:8px">${e.message || 'No active consent or emergency access for this patient.'}</p>
            <div style="margin-top:16px;display:flex;gap:12px;justify-content:center">
                <button class="btn btn-primary" onclick="openRegularAccess('${healthId}', '${healthId}')">Request Regular Access</button>
                <button class="btn btn-danger" onclick="openEmergencyAccess('${healthId}', '${healthId}')">Emergency Access</button>
            </div>
            <p style="color:var(--text-muted);margin-top:12px;font-size:0.82rem">Regular access requires patient approval. Emergency access is immediate but logged and reviewed.</p>
        </div></div>`;
    }
}

// Allow Enter key in lookup input
document.addEventListener('DOMContentLoaded', () => {
    const lookupInput = document.getElementById('lookupHealthId');
    if (lookupInput) lookupInput.addEventListener('keypress', e => { if (e.key === 'Enter') searchAllPatients(); });
});
