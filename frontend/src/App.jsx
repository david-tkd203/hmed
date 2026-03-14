import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Prescription2, FileText, CloudUpload, CheckCircle, BoxArrowRight, Person, Heart } from 'react-bootstrap-icons';
import Login from './Login';
import Home from './Home';
import Onboarding from './Onboarding';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [showLogin, setShowLogin] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [user, setUser] = useState(null);
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(false);

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
        await axios.post(
          `${API_URL}/api/logout/`,
          {},
          {
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            }
          }
        );
      }
    } catch (err) {
      console.error('Error al cerrar sesión:', err);
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
      
      await axios.post(
        `${API_URL}/api/registros/`,
        formData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'multipart/form-data',
          }
        }
      );
      
      setStatus('¡Subido con éxito!');
      setFile(null);
      setTimeout(() => setStatus(''), 2000);
    } catch (err) {
      console.error(err);
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

  // Dashboard principal
  return (
    <div className="app-container">
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
                  {status.includes('Error') ? '❌' : '✅'} {status}
                </div>
              )}

              <button type="submit" className="btn-upload" disabled={loading || !file}>
                {loading ? 'Subiendo...' : 'Subir Documento'}
              </button>
            </form>

            <div className="upload-info">
              <h3>Documentos Aceptados:</h3>
              <ul>
                <li>📄 Recetas médicas</li>
                <li>📋 Informes clínicos</li>
                <li>🔬 Resultados de laboratorio</li>
                <li>🩺 Exámenes médicos</li>
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