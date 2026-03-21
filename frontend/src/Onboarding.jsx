import React, { useState } from 'react';
import axiosInstance from './api/axiosInstance';
import { CheckCircle, XCircle, Phone, GeoAlt, ExclamationCircle, Heart } from 'react-bootstrap-icons';
import './Onboarding.css';

export default function Onboarding({ user, paciente, onComplete }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    telefono: paciente?.telefono || '',
    direccion: paciente?.direccion || '',
    ciudad: paciente?.ciudad || '',
    pais: paciente?.pais || 'Colombia',
    alergias: paciente?.alergias || '',
    enfermedades_cronicas: paciente?.enfermedades_cronicas || '',
  });

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
  const accessToken = localStorage.getItem('access_token');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await axiosInstance.patch(
        `/api/paciente/profile/`,
        formData
      );

      // Actualizar localStorage con los datos nuevos
      const updatedUser = JSON.parse(localStorage.getItem('user'));
      updatedUser.paciente = response.data.paciente;
      localStorage.setItem('user', JSON.stringify(updatedUser));

      onComplete();
    } catch (err) {
      setError(err.response?.data?.error || 'Error al guardar los datos');
    } finally {
      setLoading(false);
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  return (
    <div className="onboarding-container">
      <div className="onboarding-card">
        <div className="onboarding-header">
          <Heart className="onboarding-icon" />
          <h1>Completa tu perfil</h1>
          <p>Estos datos nos ayudan a brindarte mejor atención médica</p>
        </div>

        <form onSubmit={handleSubmit} className="onboarding-form">
          {error && (
            <div className="alert alert-error">
              <XCircle /> {error}
            </div>
          )}

          {/* Sección de contacto */}
          <div className="form-section">
            <h3>Información de Contacto</h3>
            
            <div className="form-group">
              <label htmlFor="telefono">
                <Phone size={18} /> Teléfono (Opcional)
              </label>
              <input
                type="tel"
                id="telefono"
                name="telefono"
                placeholder="+57 300 1234567"
                value={formData.telefono}
                onChange={handleChange}
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label htmlFor="direccion">
                <GeoAlt size={18} /> Dirección (Opcional)
              </label>
              <input
                type="text"
                id="direccion"
                name="direccion"
                placeholder="Calle 123 #45-67"
                value={formData.direccion}
                onChange={handleChange}
                className="form-input"
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label htmlFor="ciudad">Ciudad (Opcional)</label>
                <input
                  type="text"
                  id="ciudad"
                  name="ciudad"
                  placeholder="Bogotá"
                  value={formData.ciudad}
                  onChange={handleChange}
                  className="form-input"
                />
              </div>

              <div className="form-group">
                <label htmlFor="pais">País</label>
                <select
                  id="pais"
                  name="pais"
                  value={formData.pais}
                  onChange={handleChange}
                  className="form-input"
                >
                  <option value="Colombia">Colombia</option>
                  <option value="España">España</option>
                  <option value="México">México</option>
                  <option value="Argentina">Argentina</option>
                  <option value="Chile">Chile</option>
                  <option value="Perú">Perú</option>
                  <option value="Otro">Otro</option>
                </select>
              </div>
            </div>
          </div>

          {/* Sección de salud */}
          <div className="form-section">
            <h3>Información Médica</h3>

            <div className="form-group">
              <label htmlFor="alergias">
                <ExclamationCircle size={18} /> Alergias (Opcional)
              </label>
              <textarea
                id="alergias"
                name="alergias"
                placeholder="Ej: Penicilina, Camarones..."
                value={formData.alergias}
                onChange={handleChange}
                className="form-textarea"
                rows="3"
              />
              <small>Especifica las alergias que tengas, separadas por comas</small>
            </div>

            <div className="form-group">
              <label htmlFor="enfermedades_cronicas">
                <Heart size={18} /> Enfermedades Crónicas (Opcional)
              </label>
              <textarea
                id="enfermedades_cronicas"
                name="enfermedades_cronicas"
                placeholder="Ej: Diabetes, Hipertensión..."
                value={formData.enfermedades_cronicas}
                onChange={handleChange}
                className="form-textarea"
                rows="3"
              />
              <small>Menciona las enfermedades crónicas que padezcas</small>
            </div>
          </div>

          {/* Botones de acción */}
          <div className="onboarding-actions">
            <button
              type="button"
              onClick={handleSkip}
              className="btn-skip"
              disabled={loading}
            >
              Omitir por ahora
            </button>
            <button
              type="submit"
              className="btn-submit"
              disabled={loading}
            >
              {loading ? 'Guardando...' : 'Guardar y continuar'}
              {!loading && <CheckCircle size={18} />}
            </button>
          </div>
        </form>

        <p className="onboarding-note">
          💡 Puedes actualizar esta información en cualquier momento desde tu perfil
        </p>
      </div>
    </div>
  );
}
