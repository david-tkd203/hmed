import React, { useState } from 'react';
import axiosInstance from './api/axiosInstance';
import { ArrowLeft, Gear, Moon, Sun, Globe, Heart, Lock, Bell, Eye, Shield, Save, X } from 'react-bootstrap-icons';
import { useTranslation } from 'react-i18next';
import './Profile.css';

export default function Profile({ user, onLogout, onBack, theme, setTheme }) {
  const { t, i18n } = useTranslation();
  const [activeTab, setActiveTab] = useState('profile');
  const [profileData, setProfileData] = useState({
    nombre: user?.paciente?.nombre_completo || '',
    email: user?.email || '',
    telefono: user?.paciente?.telefono || '',
    cedula: user?.paciente?.cedula || '',
    direccion: user?.paciente?.direccion || '',
    ciudad: user?.paciente?.ciudad || '',
  });
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [changePassword, setChangePassword] = useState(false);
  const [passwords, setPasswords] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

  const handleProfileChange = (e) => {
    const { name, value } = e.target;
    setProfileData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSaveProfile = async () => {
    if (!profileData.nombre || !profileData.email) {
      setMessage('El nombre y email son requeridos');
      return;
    }

    setLoading(true);
    try {
      await axiosInstance.put(
        `/api/profile/update/`,
        {
          nombre_completo: profileData.nombre,
          cedula: profileData.cedula,
          telefono: profileData.telefono,
          direccion: profileData.direccion,
          ciudad: profileData.ciudad,
          email: profileData.email,
        }
      );

      setMessage('Perfil actualizado correctamente');
      setIsEditing(false);
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Error al actualizar perfil: ' + (error.response?.data?.detail || error.message));
    } finally {
      setLoading(false);
    }
  };

  const handleChangePassword = async () => {
    if (!passwords.currentPassword || !passwords.newPassword || !passwords.confirmPassword) {
      setMessage('Completa todos los campos');
      return;
    }

    if (passwords.newPassword !== passwords.confirmPassword) {
      setMessage('Las contraseñas nuevas no coinciden');
      return;
    }

    if (passwords.newPassword.length < 8) {
      setMessage('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setLoading(true);
    try {
      await axiosInstance.post(
        `/api/profile/change-password/`,
        {
          current_password: passwords.currentPassword,
          new_password: passwords.newPassword,
        }
      );

      setMessage('Contraseña actualizada correctamente');
      setChangePassword(false);
      setPasswords({ currentPassword: '', newPassword: '', confirmPassword: '' });
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Error al cambiar contraseña: ' + (error.response?.data?.detail || 'No se pudo actualizar la contraseña'));
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    if (confirm('¿Estás seguro de que deseas cerrar sesión?')) {
      onLogout();
    }
  };

  const changeLanguage = (lang) => {
    i18n.changeLanguage(lang);
    localStorage.setItem('language', lang);
  };

  return (
    <div className={`profile-container ${theme}`}>
      {/* Header */}
      <div className="profile-header">
        <button onClick={onBack} className="back-btn">
          <ArrowLeft size={24} /> {t('navigation.back')}
        </button>
        <h1>{t('profile.myProfile')}</h1>
        <div className="header-spacer"></div>
      </div>

      {/* User Avatar Card */}
      <div className="user-avatar-card">
        <div className="avatar-circle">
          {profileData.nombre ? profileData.nombre.charAt(0).toUpperCase() : 'U'}
        </div>
        <div className="user-info-summary">
          <h2>{profileData.nombre || t('profile.user')}</h2>
          <p className="user-email">{profileData.email}</p>
          {profileData.cedula && <p className="user-cedula">{t('profile.cedula')}: {profileData.cedula}</p>}
        </div>
      </div>

      {/* Tabs */}
      <div className="profile-tabs">
        <button
          className={`tab ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          <Heart size={20} /> {t('profile.profile')}
        </button>
        <button
          className={`tab ${activeTab === 'settings' ? 'active' : ''}`}
          onClick={() => setActiveTab('settings')}
        >
          <Gear size={20} /> {t('settings.settings')}
        </button>
      </div>

      {/* Messages */}
      {message && <div className={`message ${message.toLowerCase().includes('error') || message.toLowerCase().includes('no se pudo') ? 'error' : 'success'}`}>{message}</div>}

      {/* Profile Tab */}
      {activeTab === 'profile' && (
        <div className="profile-content">
          <div className="profile-card">
            <div className="card-header">
              <Heart size={24} />
              <h2>{t('profile.personalInfo')}</h2>
            </div>

            {!isEditing ? (
              <div className="profile-view">
                <div className="info-row">
                  <div className="info-group">
                    <label>{t('profile.fullName')}</label>
                    <p>{profileData.nombre || t('profile.notSpecified')}</p>
                  </div>
                  <div className="info-group">
                    <label>{t('profile.email')}</label>
                    <p>{profileData.email}</p>
                  </div>
                </div>
                <div className="info-row">
                  <div className="info-group">
                    <label>{t('profile.cedula')}</label>
                    <p>{profileData.cedula || t('profile.notSpecified')}</p>
                  </div>
                  <div className="info-group">
                    <label>{t('profile.phone')}</label>
                    <p>{profileData.telefono || t('profile.notSpecified')}</p>
                  </div>
                </div>
                <div className="info-row">
                  <div className="info-group">
                    <label>{t('profile.address')}</label>
                    <p>{profileData.direccion || t('profile.notSpecified')}</p>
                  </div>
                  <div className="info-group">
                    <label>{t('profile.city')}</label>
                    <p>{profileData.ciudad || t('profile.notSpecified')}</p>
                  </div>
                </div>
                <button onClick={() => setIsEditing(true)} className="btn-edit">
                  {t('profile.editProfile')}
                </button>
              </div>
            ) : (
              <div className="profile-edit">
                <input
                  type="text"
                  name="nombre"
                  placeholder={t('profile.fullName')}
                  value={profileData.nombre}
                  onChange={handleProfileChange}
                />
                <input
                  type="email"
                  name="email"
                  placeholder={t('profile.email')}
                  value={profileData.email}
                  onChange={handleProfileChange}
                />
                <input
                  type="text"
                  name="cedula"
                  placeholder={t('profile.cedula')}
                  value={profileData.cedula}
                  onChange={handleProfileChange}
                />
                <input
                  type="tel"
                  name="telefono"
                  placeholder={t('profile.phone')}
                  value={profileData.telefono}
                  onChange={handleProfileChange}
                />
                <input
                  type="text"
                  name="direccion"
                  placeholder={t('profile.address')}
                  value={profileData.direccion}
                  onChange={handleProfileChange}
                />
                <input
                  type="text"
                  name="ciudad"
                  placeholder={t('profile.city')}
                  value={profileData.ciudad}
                  onChange={handleProfileChange}
                />
                <div className="profile-actions">
                  <button
                    onClick={handleSaveProfile}
                    className="btn-save"
                    disabled={loading}
                  >
                    <Save size={18} /> {loading ? t('profile.saving') : t('profile.saveChanges')}
                  </button>
                  <button
                    onClick={() => setIsEditing(false)}
                    className="btn-cancel"
                  >
                    <X size={18} /> {t('profile.cancel')}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Security Card */}
          <div className="profile-card">
            <div className="card-header">
              <Lock size={24} />
              <h2>{t('profile.security')}</h2>
            </div>
            {!changePassword ? (
              <button onClick={() => setChangePassword(true)} className="btn-change-pwd">
                <Lock size={18} /> {t('profile.changePassword')}
              </button>
            ) : (
              <div className="password-form">
                <input
                  type="password"
                  placeholder={t('profile.currentPassword')}
                  value={passwords.currentPassword}
                  onChange={(e) => setPasswords(prev => ({ ...prev, currentPassword: e.target.value }))}
                />
                <input
                  type="password"
                  placeholder={t('profile.newPassword')}
                  value={passwords.newPassword}
                  onChange={(e) => setPasswords(prev => ({ ...prev, newPassword: e.target.value }))}
                />
                <input
                  type="password"
                  placeholder={t('profile.confirmPassword')}
                  value={passwords.confirmPassword}
                  onChange={(e) => setPasswords(prev => ({ ...prev, confirmPassword: e.target.value }))}
                />
                <div className="password-actions">
                  <button
                    onClick={handleChangePassword}
                    className="btn-save"
                    disabled={loading}
                  >
                    <Save size={18} /> {loading ? t('profile.updating') : t('profile.updatePassword')}
                  </button>
                  <button
                    onClick={() => {
                      setChangePassword(false);
                      setPasswords({ currentPassword: '', newPassword: '', confirmPassword: '' });
                    }}
                    className="btn-cancel"
                  >
                    <X size={18} /> {t('profile.cancel')}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Logout */}
          <div className="profile-card logout-section">
            <button onClick={handleLogout} className="btn-logout">
              {t('profile.logout')}
            </button>
          </div>
        </div>
      )}

      {/* Settings Tab */}
      {activeTab === 'settings' && (
        <div className="settings-content">
          {/* Theme Settings */}
          <div className="settings-card">
            <div className="card-header">
              <Sun size={24} />
              <h2>{t('settings.appearance')}</h2>
            </div>
            <div className="setting-group">
              <label>{t('settings.darkMode')}</label>
              <div className="theme-toggle">
                <button
                  className={`theme-btn ${theme === 'light' ? 'active' : ''}`}
                  onClick={() => setTheme('light')}
                >
                  <Sun size={20} /> {t('settings.light')}
                </button>
                <button
                  className={`theme-btn ${theme === 'dark' ? 'active' : ''}`}
                  onClick={() => setTheme('dark')}
                >
                  <Moon size={20} /> {t('settings.dark')}
                </button>
              </div>
            </div>
          </div>

          {/* Language Settings */}
          <div className="settings-card">
            <div className="card-header">
              <Globe size={24} />
              <h2>{t('settings.language')}</h2>
            </div>
            <div className="setting-group">
              <label>{t('settings.selectLanguage')}</label>
              <div className="language-options">
                <button
                  className={`lang-btn ${i18n.language === 'es' ? 'active' : ''}`}
                  onClick={() => changeLanguage('es')}
                >
                  <Globe size={20} /> {t('settings.spanish')}
                </button>
                <button
                  className={`lang-btn ${i18n.language === 'en' ? 'active' : ''}`}
                  onClick={() => changeLanguage('en')}
                >
                  <Globe size={20} /> {t('settings.english')}
                </button>
                <button
                  className={`lang-btn ${i18n.language === 'pt' ? 'active' : ''}`}
                  onClick={() => changeLanguage('pt')}
                >
                  <Globe size={20} /> {t('settings.portuguese')}
                </button>
              </div>
            </div>
          </div>

          {/* Notifications Settings */}
          <div className="settings-card">
            <div className="card-header">
              <Bell size={24} />
              <h2>{t('settings.notifications')}</h2>
            </div>
            <div className="setting-group">
              <label className="checkbox-label">
                <input type="checkbox" defaultChecked />
                <span>{t('settings.emailNotifications')}</span>
              </label>
              <label className="checkbox-label">
                <input type="checkbox" defaultChecked />
                <span>{t('settings.appointmentReminders')}</span>
              </label>
              <label className="checkbox-label">
                <input type="checkbox" />
                <span>{t('settings.medicalAlerts')}</span>
              </label>
            </div>
          </div>

          {/* Privacy Settings */}
          <div className="settings-card">
            <div className="card-header">
              <Shield size={24} />
              <h2>{t('settings.privacy')}</h2>
            </div>
            <div className="setting-group">
              <label className="checkbox-label">
                <input type="checkbox" defaultChecked />
                <span>{t('settings.allowDoctorsView')}</span>
              </label>
              <label className="checkbox-label">
                <input type="checkbox" />
                <span>{t('settings.shareResearch')}</span>
              </label>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
