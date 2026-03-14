import React, { useState } from 'react';
import axios from 'axios';
import { Pill, FileText, Upload, CheckCircle } from 'lucide-react';

function App() {
  const [file, setFile] = useState(null);
  const [status, setStatus] = useState('');

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return alert("Selecciona un archivo primero");

    const formData = new FormData();
    formData.append('documento_respaldo', file);
    formData.append('paciente', 1); // ID temporal del usuario
    formData.append('especialidad', 'General'); // Datos temporales
    formData.append('clinica', 'Clinica Local');
    formData.append('fecha_consulta', '2026-03-14');
    formData.append('diagnostico', 'Pendiente de análisis por IA');

    try {
      setStatus('Subiendo...');
      // Conectamos con el endpoint de Django
      await axios.post('http://localhost:8000/api/medicamentos/', formData);
      setStatus('¡Subido con éxito!');
    } catch (err) {
      console.error(err);
      setStatus('Error al subir');
    }
  };

  return (
    <div style={{ padding: '40px', fontFamily: 'system-ui', backgroundColor: '#f0f2f5', minHeight: '100vh' }}>
      <h1 style={{ color: '#1a73e8' }}>Hmed - Panel de Control</h1>
      
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '20px' }}>
        
        {/* Lado Izquierdo: Lista de Medicamentos */}
        <div style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}>
          <h2 style={{ display: 'flex', alignItems: 'center', gap: '10px' }}><Pill color="#e91e63" /> Medicamentos</h2>
          <p style={{ color: '#666' }}>Aquí aparecerán los medicamentos que la IA extraiga de tus recetas.</p>
        </div>

        {/* Lado Derecho: Subida de archivos */}
        <div style={{ background: 'white', padding: '20px', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}>
          <h3 style={{ marginTop: 0 }}>Nueva Receta / Examen</h3>
          <form onSubmit={handleUpload}>
            <div style={{ border: '2px dashed #ccc', padding: '20px', textAlign: 'center', borderRadius: '8px', marginBottom: '10px' }}>
              <input 
                type="file" 
                onChange={(e) => setFile(e.target.files[0])} 
                id="fileInput"
                style={{ display: 'none' }}
              />
              <label htmlFor="fileInput" style={{ cursor: 'pointer', color: '#1a73e8' }}>
                <Upload size={40} />
                <p>{file ? file.name : "Haz clic para seleccionar"}</p>
              </label>
            </div>
            <button type="submit" style={{ width: '100%', padding: '10px', backgroundColor: '#1a73e8', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer' }}>
              Analizar con IA
            </button>
          </form>
          {status && <p style={{ marginTop: '10px', color: status.includes('éxito') ? 'green' : 'red', display: 'flex', alignItems: 'center', gap: '5px' }}><CheckCircle size={16}/> {status}</p>}
        </div>

      </div>
    </div>
  );
}

export default App;