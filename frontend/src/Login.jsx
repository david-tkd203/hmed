import React, { useState } from 'react';
import axios from 'axios';
import { Heart, Eye, EyeSlash, ExclamationCircle, ArrowRepeat } from 'react-bootstrap-icons';
import RateLimitError from './RateLimitError';
import './Login.css';

export default function Login({ onLoginSuccess }) {
  const [isLogin, setIsLogin] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [rateLimitError, setRateLimitError] = useState(null);

  // Form data para Login
  const [loginForm, setLoginForm] = useState({
    username: '',
    password: '',
  });

  // Form data para Register
  const [registerForm, setRegisterForm] = useState({
    username: '',
    password: '',
    email: '',
    first_name: '',
    last_name: '',
    numero_cedula: '',
    genero: 'M',
    fecha_nacimiento: '',
  });

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

  // Manejar cambios en Login
  const handleLoginChange = (e) => {
    const { name, value } = e.target;
    setLoginForm(prev => ({
      ...prev,
      [name]: value
    }));
    setError('');
  };

  // Manejar cambios en Register
  const handleRegisterChange = (e) => {
    const { name, value } = e.target;
    setRegisterForm(prev => ({
      ...prev,
      [name]: value
    }));
    setError('');
  };

  // Handle Login Submit
  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setRateLimitError(null);
    setLoading(true);

    try {
      const response = await axios.post(`${API_URL}/api/login/`, {
        username: loginForm.username,
        password: loginForm.password,
      });

      // Guardar tokens JWT en localStorage
      localStorage.setItem('access_token', response.data.access);
      localStorage.setItem('refresh_token', response.data.refresh);
      localStorage.setItem('user', JSON.stringify({
        id: response.data.user.id,
        username: response.data.user.username,
        email: response.data.user.email,
        first_name: response.data.user.first_name,
        last_name: response.data.user.last_name,
        paciente: response.data.paciente,
      }));

      setSuccess('¡Login exitoso! Redirigiendo...');
      setTimeout(() => {
        onLoginSuccess(response.data);
      }, 1500);
    } catch (err) {
      // Detectar error 429 (Rate Limit)
      if (err.response?.status === 429) {
        const retryAfter = parseInt(err.response.headers['retry-after'] || '3600');
        setRateLimitError({
          retryAfter,
          endpoint: '/api/login/'
        });
      } else {
        setError(err.response?.data?.error || 'Error al iniciar sesión. Intenta nuevamente.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Handle Register Submit
  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setRateLimitError(null);
    setLoading(true);

    // Validaciones
    if (registerForm.password.length < 6) {
      setError('La contraseña debe tener al menos 6 caracteres');
      setLoading(false);
      return;
    }

    if (!registerForm.email.includes('@')) {
      setError('Por favor ingresa un email válido');
      setLoading(false);
      return;
    }

    try {
      const response = await axios.post(`${API_URL}/api/register/`, registerForm);

      // Guardar tokens JWT en localStorage
      localStorage.setItem('access_token', response.data.access);
      localStorage.setItem('refresh_token', response.data.refresh);
      localStorage.setItem('user', JSON.stringify({
        id: response.data.user.id,
        username: response.data.user.username,
        email: response.data.user.email,
        first_name: response.data.user.first_name,
        last_name: response.data.user.last_name,
        paciente: response.data.paciente,
      }));

      setSuccess('¡Registro exitoso! Bienvenido a HMED');
      setTimeout(() => {
        onLoginSuccess(response.data);
      }, 1500);
    } catch (err) {
      // Detectar error 429 (Rate Limit)
      if (err.response?.status === 429) {
        const retryAfter = parseInt(err.response.headers['retry-after'] || '3600');
        setRateLimitError({
          retryAfter,
          endpoint: '/api/register/'
        });
      } else {
        setError(err.response?.data?.error || 'Error al registrarse. Intenta nuevamente.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Mostrar error de rate limiting
  if (rateLimitError) {
    return (
      <RateLimitError
        retryAfter={rateLimitError.retryAfter}
        endpoint={rateLimitError.endpoint}
        onRetry={() => {
          setRateLimitError(null);
          setError('');
        }}
      />
    );
  }

  return (
    <div className="login-container">
      {/* Fondo decorativo */}
      <div className="login-background">
        <div className="circle circle-1"></div>
        <div className="circle circle-2"></div>
        <div className="circle circle-3"></div>
      </div>

      {/* Contenedor principal */}
      <div className="login-wrapper">
        {/* Header con logo */}
        <div className="login-header">
          <div className="logo-container">
            <img src="/logo_horizontal.png" alt="HMED Logo" />
          </div>
          <p className="tagline">Tu historial clínico en un solo lugar</p>
        </div>

        {/* Tarjeta de Login/Register */}
        <div className="login-card">
          {/* Tabs */}
          <div className="tabs">
            <button
              className={`tab ${isLogin ? 'active' : ''}`}
              onClick={() => {
                setIsLogin(true);
                setError('');
                setSuccess('');
              }}
            >
              Iniciar Sesión
            </button>
            <button
              className={`tab ${!isLogin ? 'active' : ''}`}
              onClick={() => {
                setIsLogin(false);
                setError('');
                setSuccess('');
              }}
            >
              Registrarse
            </button>
          </div>

          {/* Mensajes de error y éxito */}
          {error && (
            <div className="alert alert-error">
              <ExclamationCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          {success && (
            <div className="alert alert-success">
              <span>{success}</span>
            </div>
          )}

          {/* Formulario de Login */}
          <form 
            onSubmit={handleLoginSubmit} 
            className={`login-form form-container ${isLogin ? 'form-active' : 'form-hidden'}`}
          >
            <div className="form-group">
              <label htmlFor="login-username">Usuario o Email</label>
              <input
                type="text"
                id="login-username"
                name="username"
                value={loginForm.username}
                onChange={handleLoginChange}
                placeholder="Tu usuario o email"
                required
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="login-password">Contraseña</label>
              <div className="password-input">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="login-password"
                  name="password"
                  value={loginForm.password}
                  onChange={handleLoginChange}
                  placeholder="Tu contraseña"
                  required
                  disabled={loading}
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  disabled={loading}
                >
                  {showPassword ? <EyeSlash size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <button type="submit" className="btn-submit" disabled={loading}>
              {loading ? (
                <>
                  <ArrowRepeat size={18} className="spinner" />
                  Iniciando sesión...
                </>
              ) : (
                'Iniciar Sesión'
              )}
            </button>

            <div className="forgot-password">
              <a href="#forgot">¿Olvidaste tu contraseña?</a>
            </div>
          </form>

          {/* Formulario de Registro */}
          <form 
            onSubmit={handleRegisterSubmit} 
            className={`login-form register-form form-container ${!isLogin ? 'form-active' : 'form-hidden'}`}
          >
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="first-name">Nombre</label>
                <input
                  type="text"
                  id="first-name"
                  name="first_name"
                  value={registerForm.first_name}
                  onChange={handleRegisterChange}
                  placeholder="Tu nombre"
                  required
                  disabled={loading}
                />
              </div>
              <div className="form-group">
                <label htmlFor="last-name">Apellido</label>
                <input
                  type="text"
                  id="last-name"
                  name="last_name"
                  value={registerForm.last_name}
                  onChange={handleRegisterChange}
                  placeholder="Tu apellido"
                  required
                  disabled={loading}
                />
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="reg-username">Usuario</label>
              <input
                type="text"
                id="reg-username"
                name="username"
                value={registerForm.username}
                onChange={handleRegisterChange}
                placeholder="Elige un usuario único"
                required
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="reg-email">Email</label>
              <input
                type="email"
                id="reg-email"
                name="email"
                value={registerForm.email}
                onChange={handleRegisterChange}
                placeholder="tu@email.com"
                required
                disabled={loading}
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label htmlFor="cedula">Cédula</label>
                <input
                  type="text"
                  id="cedula"
                  name="numero_cedula"
                  value={registerForm.numero_cedula}
                  onChange={handleRegisterChange}
                  placeholder="1234567890"
                  required
                  disabled={loading}
                />
              </div>
              <div className="form-group">
                <label htmlFor="genero">Género</label>
                <select
                  id="genero"
                  name="genero"
                  value={registerForm.genero}
                  onChange={handleRegisterChange}
                  disabled={loading}
                >
                  <option value="M">Masculino</option>
                  <option value="F">Femenino</option>
                  <option value="O">Otro</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="fecha-nacimiento">Fecha de Nacimiento</label>
              <input
                type="date"
                id="fecha-nacimiento"
                name="fecha_nacimiento"
                value={registerForm.fecha_nacimiento}
                onChange={handleRegisterChange}
                required
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <label htmlFor="reg-password">Contraseña</label>
              <div className="password-input">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="reg-password"
                  name="password"
                  value={registerForm.password}
                  onChange={handleRegisterChange}
                  placeholder="Mínimo 6 caracteres"
                  required
                  disabled={loading}
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  disabled={loading}
                >
                  {showPassword ? <EyeSlash size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <button type="submit" className="btn-submit" disabled={loading}>
              {loading ? (
                <>
                  <ArrowRepeat size={18} className="spinner" />
                  Registrando...
                </>
              ) : (
                'Crear Cuenta'
              )}
            </button>

            <p className="terms-text">
              Al registrarte, aceptas nuestros Términos de Servicio y Política de Privacidad
            </p>
          </form>
        </div>

        {/* Footer */}
        <div className="login-footer">
          <p>© 2026 HMED. Todos los derechos reservados.</p>
        </div>
      </div>
    </div>
  );
}
