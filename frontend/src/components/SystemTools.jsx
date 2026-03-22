import React, { useState } from 'react';
import './SystemTools.css';
import { Code, Check, ExclamationTriangle } from 'react-bootstrap-icons';

/**
 * Componente para mostrar herramientas de sistema disponibles
 * Incluye: SonarQB, APIs, servicios de análisis
 */
export default function SystemTools() {
  const [hoveredTool, setHoveredTool] = useState(null);

  const tools = [
    {
      id: 'sonarqb',
      name: 'SonarQube',
      port: 9000,
      url: 'http://localhost:9000',
      status: 'available',
      user: 'admin',
      password: 'admin',
      description: 'Auditoría de código & vulnerabilidades',
      icon: '🔍',
      features: ['Análisis de código', 'Detecta vulnerabilidades', 'Métricas de calidad', 'SAST & DAST']
    },
    {
      id: 'api',
      name: 'API Backend',
      port: 8000,
      url: 'http://localhost:8000/api/',
      status: 'available',
      description: 'API REST para extracción y análisis',
      icon: '⚙️',
      features: ['Extracción de documentos', 'Análisis médico', 'Gestión de recetas']
    },
    {
      id: 'frontend',
      name: 'Frontend - Histórico Clínico',
      port: 5173,
      url: 'http://localhost:5173',
      status: 'active',
      description: 'Aplicación web de gestión de registros',
      icon: '💻',
      features: ['Interfaz de usuario', 'Subida de documentos', 'Visualización de análisis']
    },
    {
      id: 'database',
      name: 'Base de Datos',
      port: 5432,
      status: 'running',
      description: 'PostgreSQL para almacenamiento de datos',
      icon: '🗄️',
      features: ['Registros clínicos', 'Medicamentos', 'Pacientes']
    }
  ];

  const getStatusColor = (status) => {
    switch(status) {
      case 'available':
      case 'active':
      case 'running':
        return '#4caf50';
      case 'unavailable':
        return '#ff9800';
      case 'error':
        return '#f44336';
      default:
        return '#999';
    }
  };

  const getStatusLabel = (status) => {
    switch(status) {
      case 'available':
        return 'Disponible';
      case 'active':
        return 'Activo';
      case 'running':
        return 'En ejecución';
      case 'unavailable':
        return 'No disponible';
      case 'error':
        return 'Error';
      default:
        return status;
    }
  };

  return (
    <div className="system-tools-container">
      <div className="tools-header">
        <Code size={24} />
        <h3>Herramientas del Sistema</h3>
        <span className="tools-count">{tools.length} servicios</span>
      </div>

      <div className="tools-grid">
        {tools.map((tool) => (
          <div
            key={tool.id}
            className={`tool-card ${hoveredTool === tool.id ? 'hovered' : ''}`}
            onMouseEnter={() => setHoveredTool(tool.id)}
            onMouseLeave={() => setHoveredTool(null)}
          >
            <div className="tool-header-card">
              <div className="tool-icon">{tool.icon}</div>
              <div className="tool-info">
                <h4>{tool.name}</h4>
                <span className="tool-status" style={{ color: getStatusColor(tool.status) }}>
                  <Check size={12} /> {getStatusLabel(tool.status)}
                </span>
              </div>
            </div>

            <div className="tool-details">
              {tool.port && (
                <div className="detail-item">
                  <span className="detail-label">Puerto:</span>
                  <code className="detail-value">{tool.port}</code>
                </div>
              )}

              {tool.url && (
                <div className="detail-item">
                  <span className="detail-label">Acceso:</span>
                  <a href={tool.url} target="_blank" rel="noopener noreferrer" className="detail-link">
                    {tool.url.replace('http://', '')}
                  </a>
                </div>
              )}

              {tool.user && (
                <div className="detail-item">
                  <span className="detail-label">Usuario:</span>
                  <code className="detail-value">{tool.user}</code>
                </div>
              )}

              {tool.password && (
                <div className="detail-item">
                  <span className="detail-label">Contraseña:</span>
                  <code className="detail-value">••••••</code>
                </div>
              )}

              <p className="tool-description">{tool.description}</p>

              {tool.features && tool.features.length > 0 && (
                <div className="tool-features">
                  <span className="features-label">Características:</span>
                  <ul>
                    {tool.features.map((feature, idx) => (
                      <li key={idx}>{feature}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>

            {tool.url && (
              <div className="tool-action">
                <a href={tool.url} target="_blank" rel="noopener noreferrer" className="btn-open">
                  Abrir →
                </a>
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="tools-footer">
        <ExclamationTriangle size={16} />
        <p>Para máxima seguridad, cambia las contraseñas por defecto de SonarQube</p>
      </div>
    </div>
  );
}
