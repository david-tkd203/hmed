import React, { useState, useEffect } from 'react';
import axiosInstance from './api/axiosInstance';
import { Prescription2, FileText, CloudUpload, CheckCircle, BoxArrowRight, Person, Heart, Gear } from 'react-bootstrap-icons';
import Login from './Login';
import Home from './Home';
import Onboarding from './Onboarding';
import Profile from './Profile';
import DocumentUpload from './DocumentUpload';
import Medications from './Medications';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [showLogin, setShowLogin] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const [showDocuments, setShowDocuments] = useState(false);
  const [showMedications, setShowMedications] = useState(false);
  const [user, setUser] = useState(null);
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(false);
  const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'light');

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

  // Verificar si hay sesión activa al cargar
  useEffect(() => {
    const accessToken = localStorage.getItem('access_token');
    const userData = localStorage.getItem('user');
    
    if (accessToken && userData) {
      setIsAuthenticated(true);
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      
      // Verificar si necesita completar onboarding
      checkOnboarding(parsedUser);
    }
  }, []);

  // Guardar tema cuando cambia
  useEffect(() => {
    localStorage.setItem('theme', theme);
    document.body.className = theme;
  }, [theme]);

  // Función para verificar si el usuario necesita completar onboarding
  const checkOnboarding = (userData) => {
    const paciente = userData?.paciente;
    // Mostrar onboarding si faltan datos importantes
    if (!paciente || !paciente.telefono || !paciente.direccion) {
      setShowOnboarding(true);
    }
  };

  // Manejar login exitoso
  const handleLoginSuccess = (data) => {
    setIsAuthenticated(true);
    const newUser = {
      id: data.user.id,
      username: data.user.username,
      email: data.user.email,
      first_name: data.user.first_name,
      last_name: data.user.last_name,
      paciente: data.paciente,
    };
    setUser(newUser);
    
    // Verificar si necesita onboarding
    checkOnboarding(newUser);
  };

  // Manejar completado de onboarding
  const handleOnboardingComplete = () => {
    setShowOnboarding(false);
  };

  // Manejar logout
  const handleLogout = async () => {
    try {
      const accessToken = localStorage.getItem('access_token');
      if (accessToken) {
        await axiosInstance.post(
          `/api/logout/`,
          {}
        );
      }
    } catch (err) {
      // Error silencioso en logout
    } finally {
      // Limpiar localStorage
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      localStorage.removeItem('user');
      setIsAuthenticated(false);
      setUser(null);
      setStatus('');
    }
  };

  // Manejar carga de archivo
  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return alert("Selecciona un archivo primero");

    const accessToken = localStorage.getItem('access_token');
    const formData = new FormData();
    formData.append('documento_respaldo', file);
    formData.append('paciente', user.id);
    formData.append('especialidad', 'General');
    formData.append('clinica', 'Clínica Local');
    formData.append('fecha_consulta', new Date().toISOString().split('T')[0]);
    formData.append('diagnostico', 'Pendiente de análisis');

    try {
      setLoading(true);
      setStatus('Subiendo...');
      
      await axiosInstance.post(
        `/api/registro/upload/`,
        formData
      );
      
      setStatus('¡Subido con éxito!');
      setFile(null);
      setTimeout(() => setStatus(''), 2000);
    } catch (err) {
      setStatus('Error al subir: ' + (err.response?.data?.detail || 'Intenta nuevamente'));
    } finally {
      setLoading(false);
    }
  };

  // Si no está autenticado, mostrar Home o Login
  if (!isAuthenticated) {
    if (!showLogin) {
      return <Home onNavigateToLogin={() => setShowLogin(true)} />;
    }
    return <Login onLoginSuccess={handleLoginSuccess} />;
  }

  // Si está autenticado pero necesita completar onboarding
  if (showOnboarding) {
    return (
      <Onboarding 
        user={user}
        paciente={user?.paciente}
        onComplete={handleOnboardingComplete}
      />
    );
  }

  // Si está autenticado y muestra perfil
  if (showProfile) {
    return (
      <Profile 
        user={user}
        onLogout={handleLogout}
        onBack={() => setShowProfile(false)}
        theme={theme}
        setTheme={setTheme}
      />
    );
  }

  // Si está autenticado y carga documentos
  if (showDocuments) {
    return (
      <DocumentUpload
        user={user}
        onBack={() => setShowDocuments(false)}
        theme={theme}
      />
    );
  }

  // Si está autenticado y ve medicamentos
  if (showMedications) {
    return (
      <Medications
        theme={theme}
        onBack={() => setShowMedications(false)}
      />
    );
  }

  // Dashboard principal
  return (
    <div className={`app-container ${theme}`}>
      {/* Header */}
      <header className="app-header">
        <div className="header-left">
          <div className="header-logo">
            <img src="/logo_horizontal.png" alt="HMED Logo" />
          </div>
        </div>
        
        <div className="header-center">
          <h1>Panel de Control</h1>
        </div>

        <div className="header-right">
          <button 
            className="btn-profile" 
            onClick={() => setShowProfile(true)}
            title="Ver perfil"
          >
            <Gear size={20} />
          </button>
          <div className="user-info">
            <div className="user-avatar">
              <Person size={20} />
            </div>
            <div className="user-details">
              <p className="user-name">{user.first_name} {user.last_name}</p>
              <p className="user-email">{user.email}</p>
            </div>
          </div>
          <button className="btn-logout" onClick={handleLogout}>
            <BoxArrowRight size={18} />
            Cerrar Sesión
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="app-main">
        {/* Welcome Section con Logo Central */}
        <div className="dashboard-grid">
          <section className="panel welcome-section">
            <img src="/logo_central.png" alt="HMED Central Logo" className="welcome-logo" />
          </section>
        </div>

        <div className="dashboard-grid">
          
          {/* Panel izquierdo: Registros clínicos */}
          <section className="panel panel-registros">
            <div className="section-header">
              <div className="icon-badge">
                <FileText size={24} color="#154360" />
              </div>
              <h2>Tus Registros Clínicos</h2>
            </div>

            <div className="registros-list">
              <div className="empty-state">
                <FileText size={48} color="#ddd" />
                <p>No hay registros aún</p>
                <span>Sube tu primer documento clínico</span>
              </div>
            </div>
          </section>

          {/* Panel derecho: Subida de archivos */}
          <section className="panel panel-upload">
            <div className="section-header">
              <div className="icon-badge">
                <CloudUpload size={24} color="#2A817C" />
              </div>
              <h2>Subir Documento</h2>
            </div>

            <form onSubmit={handleUpload} className="upload-form">
              <div className="upload-area">
                <input
                  type="file"
                  id="file-input"
                  onChange={(e) => setFile(e.target.files[0])}
                  disabled={loading}
                />
                <label htmlFor="file-input" className={`upload-label ${file ? 'has-file' : ''}`}>
                  <CloudUpload size={32} />
                  <p className="upload-main-text">
                    {file ? file.name : 'Arrastra aquí o haz clic'}
                  </p>
                  <p className="upload-sub-text">
                    {file ? 'Listo para subir' : 'PDF, JPG o PNG (máx 10MB)'}
                  </p>
                </label>
              </div>

              {status && (
                <div className={`status-message ${status.includes('Error') ? 'error' : 'success'}`}>
                  {status}
                </div>
              )}

              <button type="submit" className="btn-upload" disabled={loading || !file}>
                {loading ? 'Subiendo...' : 'Subir Documento'}
              </button>

              <button 
                type="button" 
                className="btn-upload-advanced"
                onClick={() => setShowDocuments(true)}
              >
                📂 Ver Carga Avanzada
              </button>
            </form>

            <div className="upload-info">
              <h3>Documentos Aceptados:</h3>
              <ul>
                <li>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                  </svg>
                  Recetas médicas
                </li>
                <li>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                    <polyline points="9 22 9 12 15 12 15 22"></polyline>
                  </svg>
                  Informes clínicos
                </li>
                <li>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <circle cx="12" cy="12" r="6"></circle>
                    <circle cx="12" cy="12" r="2"></circle>
                  </svg>
                  Resultados de laboratorio
                </li>
                <li>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"></path>
                    <path d="M12 6v6h4"></path>
                  </svg>
                  Exámenes médicos
                </li>
              </ul>
            </div>
          </section>
        </div>

        {/* Sección de medicamentos */}
        <section className="panel panel-medicamentos" style={{ marginTop: '30px' }}>
          <div className="section-header">
            <div className="icon-badge">
              <Prescription2 size={24} color="#2A817C" />
            </div>
            <h2>Medicamentos</h2>
          </div>

          <div className="medicamentos-list">
            <div className="empty-state">
              <Prescription2 size={48} color="#ddd" />
              <p>Sin medicamentos registrados</p>
              <span>Se mostrarán aquí los medicamentos extraídos de tus documentos</span>
            </div>
          </div>

          <button 
            className="btn-upload-advanced"
            onClick={() => setShowMedications(true)}
            style={{ marginTop: '20px' }}
          >
            💊 Gestionar Medicamentos
          </button>
        </section>
      </main>

      {/* Footer */}
      <footer className="app-footer">
        <p>&copy; 2026 HMED - Tu historial clínico en un solo lugar</p>
      </footer>
    </div>
  );
}

export default App;