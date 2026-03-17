import React, { useState, useEffect } from 'react';
import { Clock, ExclamationCircle, ArrowRepeat } from 'react-bootstrap-icons';
import './RateLimitError.css';

export default function RateLimitError({ retryAfter, onRetry, endpoint }) {
  const [remainingTime, setRemainingTime] = useState(retryAfter);

  useEffect(() => {
    if (remainingTime <= 0) return;

    const interval = setInterval(() => {
      setRemainingTime(prev => {
        if (prev <= 1) {
          clearInterval(interval);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [remainingTime]);

  const formatTime = (seconds) => {
    if (seconds < 60) return `${seconds}s`;
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}m ${secs}s`;
  };

  return (
    <div className="rate-limit-error-overlay">
      <div className="rate-limit-error-card">
        <div className="error-icon-container">
          <ExclamationCircle size={64} className="error-icon" />
        </div>

        <h2>Demasiados Intentos</h2>
        <p className="error-message">
          Has excedido el límite de intentos permitidos.
        </p>

        <div className="endpoint-info">
          <small>Endpoint: <code>{endpoint}</code></small>
        </div>

        <div className="timer-section">
          <Clock size={24} className="timer-icon" />
          <div className="timer">
            <p className="timer-label">Por favor espera:</p>
            <p className="timer-value">{formatTime(remainingTime)}</p>
          </div>
        </div>

        <div className="error-details">
          <ul>
            <li>Intentos que realizaste: Demasiados en poco tiempo</li>
            <li>Tu cuenta está protegida temporalmente</li>
            <li>El acceso será restaurado automáticamente</li>
          </ul>
        </div>

        <button
          className="btn-retry"
          onClick={onRetry}
          disabled={remainingTime > 0}
        >
          {remainingTime > 0 ? (
            <>
              <Clock size={18} />
              Espera {formatTime(remainingTime)}
            </>
          ) : (
            <>
              <ArrowRepeat size={18} />
              Intentar de Nuevo
            </>
          )}
        </button>

        <div className="security-info">
          <p>
            <strong>Nota de Seguridad:</strong> Este límite existe para proteger tu cuenta
            de accesos no autorizados. Si no reconoces estos intentos, por favor contacta con soporte.
          </p>
        </div>
      </div>
    </div>
  );
}
