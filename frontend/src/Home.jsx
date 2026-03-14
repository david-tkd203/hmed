import { useState } from 'react';
import { Prescription2, FileText, ShieldCheck, ArrowRight } from 'react-bootstrap-icons';
import './Home.css';

export default function Home({ onNavigateToLogin }) {
  const [hoveredCard, setHoveredCard] = useState(null);

  const features = [
    {
      icon: FileText,
      title: 'Historial Centralizado',
      description: 'Todos tus registros médicos en un solo lugar seguro'
    },
    {
      icon: Prescription2,
      title: 'Gestión de Medicinas',
      description: 'Controla tus medicamentos y dosificaciones'
    },
    {
      icon: ShieldCheck,
      title: 'Privacidad Garantizada',
      description: 'Datos encriptados y protegidos al máximo'
    }
  ];

  return (
    <div className="home-container">
      {/* Hero Section */}
      <section className="hero">
        <div className="hero-content">
          <h1 className="hero-title">Tu Historial Clínico en Un Solo Lugar</h1>
          <p className="hero-subtitle">HMED: La plataforma segura para gestionar tu salud</p>
          
          <div className="hero-buttons">
            <button className="btn-primary" onClick={onNavigateToLogin}>
              Iniciar Sesión
              <ArrowRight size={18} />
            </button>
            <button className="btn-secondary" onClick={onNavigateToLogin}>
              Registrarse
            </button>
          </div>
        </div>

        <div className="hero-image">
          <div className="medical-icon">
            <Prescription2 size={80} color="#2A817C" />
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features">
        <h2>¿Por qué elegir HMED?</h2>
        <div className="features-grid">
          {features.map((feature, index) => {
            const Icon = feature.icon;
            return (
              <div
                key={index}
                className="feature-card"
                onMouseEnter={() => setHoveredCard(index)}
                onMouseLeave={() => setHoveredCard(null)}
                style={{
                  transform: hoveredCard === index ? 'translateY(-8px)' : 'translateY(0)'
                }}
              >
                <div className="feature-icon">
                  <Icon size={40} color="#154360" />
                </div>
                <h3>{feature.title}</h3>
                <p>{feature.description}</p>
              </div>
            );
          })}
        </div>
      </section>

      {/* CTA Section */}
      <section className="cta">
        <h2>Comienza a gestionar tu salud hoy</h2>
        <p>Únete a miles de usuarios que confían en HMED</p>
        <button className="btn-cta" onClick={onNavigateToLogin}>
          Acceder Ahora
        </button>
      </section>
    </div>
  );
}
