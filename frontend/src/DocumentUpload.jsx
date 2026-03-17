import React, { useState, useRef } from 'react';
import axios from 'axios';
import { CloudUpload, FileEarmarkText, X, CheckCircle, ExclamationCircle, ArrowClockwise, Eye } from 'react-bootstrap-icons';
import { useTranslation } from 'react-i18next';
import AnalysisResults from './components/AnalysisResults';
import './DocumentUpload.css';

export default function DocumentUpload({ user, onBack, theme }) {
  const { t } = useTranslation();
  const [files, setFiles] = useState([]);
  const [isDragging, setIsDragging] = useState(false);
  const [uploadProgress, setUploadProgress] = useState({});
  const [uploadStatus, setUploadStatus] = useState({});
  const [analysisState, setAnalysisState] = useState({});
  const [selectedAnalysis, setSelectedAnalysis] = useState(null);
  const [showAnalysisModal, setShowAnalysisModal] = useState(false);
  const fileInputRef = useRef(null);

  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
  const accessToken = localStorage.getItem('access_token');
  
  // Tipos MIME aceptados
  const ALLOWED_TYPES = {
    'image/jpeg': ['.jpg', '.jpeg'],
    'image/png': ['.png'],
    'image/tiff': ['.tiff', '.tif'],
    'application/pdf': ['.pdf'],
    'application/dicom': ['.dcm'],
  };

  const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
  const MAX_FILES = 10;

  const validateFile = (file) => {
    // Verificar tipo MIME
    if (!ALLOWED_TYPES[file.type]) {
      return {
        valid: false,
        error: t('documents.invalidFormat')
      };
    }

    // Verificar tamaño
    if (file.size > MAX_FILE_SIZE) {
      return {
        valid: false,
        error: t('documents.fileTooLarge')
      };
    }

    return { valid: true };
  };

  const handleDragEnter = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    const droppedFiles = Array.from(e.dataTransfer.files);
    handleFiles(droppedFiles);
  };

  const handleFileInput = (e) => {
    const selectedFiles = Array.from(e.target.files);
    handleFiles(selectedFiles);
  };

  const handleFiles = (newFiles) => {
    if (files.length + newFiles.length > MAX_FILES) {
      alert(t('documents.maxFilesExceeded'));
      return;
    }

    const validFiles = newFiles.map(file => {
      const validation = validateFile(file);
      return {
        id: `${file.name}-${Date.now()}`,
        file,
        preview: file.type.startsWith('image/') ? URL.createObjectURL(file) : null,
        error: validation.error,
        valid: validation.valid,
        uploaded: false,
        docId: null, // ID del documento después de subir
      };
    });

    setFiles(prev => [...prev, ...validFiles]);
  };

  const removeFile = (id) => {
    setFiles(prev => {
      const fileToRemove = prev.find(f => f.id === id);
      if (fileToRemove?.preview) {
        URL.revokeObjectURL(fileToRemove.preview);
      }
      return prev.filter(f => f.id !== id);
    });
    setUploadProgress(prev => {
      const newProgress = { ...prev };
      delete newProgress[id];
      return newProgress;
    });
    setUploadStatus(prev => {
      const newStatus = { ...prev };
      delete newStatus[id];
      return newStatus;
    });
    setAnalysisState(prev => {
      const newAnalysis = { ...prev };
      delete newAnalysis[id];
      return newAnalysis;
    });
  };

  const uploadFile = async (fileObj) => {
    if (!fileObj.valid) return;
    
    const formData = new FormData();
    formData.append('document', fileObj.file);
    formData.append('tipo_documento', 'medico');
    formData.append('descripcion', fileObj.file.name);

    try {
      
      const response = await axios.post(
        `${API_URL}/api/documents/upload/`,
        formData,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
          onUploadProgress: (progressEvent) => {
            const percentCompleted = Math.round(
              (progressEvent.loaded * 100) / progressEvent.total
            );
            setUploadProgress(prev => ({
              ...prev,
              [fileObj.id]: percentCompleted
            }));
          }
        }
      );

      // Guardar ID del documento para análisis
      const uploadedDocId = response.data.id;
      setFiles(prev => prev.map(f =>
        f.id === fileObj.id ? { ...f, uploaded: true, docId: uploadedDocId } : f
      ));

      setUploadStatus(prev => ({
        ...prev,
        [fileObj.id]: { success: true, message: t('documents.uploadSuccess') }
      }));
    } catch (error) {
      const errorMsg = error.response?.data?.detail || error.message || t('documents.uploadError');
      setUploadStatus(prev => ({
        ...prev,
        [fileObj.id]: { success: false, message: errorMsg }
      }));
    }
  };

  const uploadAllFiles = async () => {
    const validFiles = files.filter(f => f.valid && !f.uploaded);
    for (const fileObj of validFiles) {
      await uploadFile(fileObj);
    }
  };

  const analyzeDocument = async (fileObj) => {
    if (!fileObj.docId) return;

    setAnalysisState(prev => ({
      ...prev,
      [fileObj.id]: { loading: true, error: null }
    }));

    try {
      const response = await axios.post(
        `${API_URL}/api/documents/${fileObj.docId}/analyze/`,
        {},
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          }
        }
      );

      setAnalysisState(prev => ({
        ...prev,
        [fileObj.id]: { 
          loading: false, 
          completed: true,
          analysis: response.data.analysis,
          documentId: fileObj.docId
        }
      }));

      // Mostrar modal con resultados
      setSelectedAnalysis({
        fileId: fileObj.id,
        documentId: fileObj.docId,
        analysis: response.data.analysis
      });
      setShowAnalysisModal(true);
    } catch (error) {
      const errorMsg = error.response?.data?.error || error.message || 'Error en análisis';
      setAnalysisState(prev => ({
        ...prev,
        [fileObj.id]: { loading: false, error: errorMsg }
      }));
    }
  };

  const getFileObj = (id) => files.find(f => f.id === id);

  return (
    <div className={`document-upload-container ${theme}`}>
      {/* Header */}
      <div className="upload-header">
        <button onClick={onBack} className="back-btn">
          ← {t('navigation.back')}
        </button>
        <h1>{t('documents.uploadDocuments')}</h1>
        <div className="header-spacer"></div>
      </div>

      {/* Zone de arrastrar y soltar */}
      <div
        className={`drop-zone ${isDragging ? 'active' : ''}`}
        onDragEnter={handleDragEnter}
        onDragLeave={handleDragLeave}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
      >
        <CloudUpload size={64} className="drop-icon" />
        <h2>{t('documents.dragAndDrop')}</h2>
        <p>{t('documents.orClickBelow')}</p>
        <button
          onClick={() => fileInputRef.current?.click()}
          className="btn-select-files"
        >
          {t('documents.selectFiles')}
        </button>
        <input
          ref={fileInputRef}
          type="file"
          multiple
          onChange={handleFileInput}
          style={{ display: 'none' }}
          accept={Object.keys(ALLOWED_TYPES).join(',')}
        />
        <p className="supported-formats">
          {t('documents.supportedFormats')}: JPG, PNG, TIFF, PDF, DICOM ({t('documents.maxSize')}: 50MB)
        </p>
      </div>

      {/* Lista de archivos */}
      {files.length > 0 && (
        <div className="files-section">
          <h2>{t('documents.filesToUpload')} ({files.length}/{MAX_FILES})</h2>

          <div className="files-grid">
            {files.map((fileObj) => (
              <div key={fileObj.id} className="file-card">
                {/* Miniatura */}
                <div className="file-preview">
                  {fileObj.preview ? (
                    <img src={fileObj.preview} alt={fileObj.file.name} />
                  ) : (
                    <div className="file-icon">
                      <FileEarmarkText size={48} />
                    </div>
                  )}
                  {fileObj.uploaded && (
                    <div className="uploaded-badge">
                      <CheckCircle size={24} className="success-icon" />
                    </div>
                  )}
                </div>

                {/* Información del archivo */}
                <div className="file-info">
                  <p className="file-name" title={fileObj.file.name}>
                    {fileObj.file.name}
                  </p>
                  <p className="file-size">
                    {(fileObj.file.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>

                {/* Estado */}
                <div className="file-status">
                  {fileObj.error && (
                    <div className="error-message">
                      <ExclamationCircle size={16} />
                      <span>{fileObj.error}</span>
                    </div>
                  )}

                  {fileObj.valid && !fileObj.uploaded && (
                    <>
                      {uploadProgress[fileObj.id] !== undefined && (
                        <div className="progress-container">
                          <div
                            className="progress-bar"
                            style={{ width: `${uploadProgress[fileObj.id]}%` }}
                          ></div>
                          <span className="progress-text">
                            {uploadProgress[fileObj.id]}%
                          </span>
                        </div>
                      )}
                    </>
                  )}

                  {uploadStatus[fileObj.id] && (
                    <div
                      className={`status-message ${
                        uploadStatus[fileObj.id].success ? 'success' : 'error'
                      }`}
                    >
                      {uploadStatus[fileObj.id].success ? (
                        <CheckCircle size={16} />
                      ) : (
                        <ExclamationCircle size={16} />
                      )}
                      <span>{uploadStatus[fileObj.id].message}</span>
                    </div>
                  )}

                  {/* Estado de análisis */}
                  {analysisState[fileObj.id] && (
                    <div className="analysis-status-message">
                      {analysisState[fileObj.id].loading && (
                        <>
                          <ArrowClockwise size={16} className="spinner-mini" />
                          <span>{t('documents.analysis.analyzing')}</span>
                        </>
                      )}
                      {analysisState[fileObj.id].error && (
                        <>
                          <ExclamationCircle size={16} />
                          <span>{analysisState[fileObj.id].error}</span>
                        </>
                      )}
                      {analysisState[fileObj.id].completed && (
                        <>
                          <CheckCircle size={16} />
                          <span>Análisis completado</span>
                        </>
                      )}
                    </div>
                  )}
                </div>

                {/* Acciones */}
                <div className="file-actions">
                  {fileObj.uploaded && (
                    <button
                      onClick={() => analyzeDocument(fileObj)}
                      className="btn-analyze"
                      disabled={analysisState[fileObj.id]?.loading}
                      title={t('documents.analyzeWithAI')}
                    >
                      {analysisState[fileObj.id]?.loading ? (
                        <>
                          <ArrowClockwise size={16} className="spinner-mini" />
                        </>
                      ) : (
                        <>
                          <Eye size={16} />
                        </>
                      )}
                      {t('documents.analyzeWithAI')}
                    </button>
                  )}

                  {!fileObj.uploaded && (
                    <button
                      onClick={() => removeFile(fileObj.id)}
                      className="btn-remove"
                      title={t('documents.removeFile')}
                    >
                      <X size={20} />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* Botón de upload */}
          {files.some(f => f.valid && !f.uploaded) && (
            <button onClick={uploadAllFiles} className="btn-upload-all">
              <ArrowClockwise size={20} className="spinner" />
              {t('documents.uploadAll')}
            </button>
          )}
        </div>
      )}

      {/* Mensaje vacío */}
      {files.length === 0 && (
        <div className="empty-state">
          <p>{t('documents.noFilesSelected')}</p>
        </div>
      )}

      {/* Analysis Results Modal */}
      {showAnalysisModal && selectedAnalysis && (
        <AnalysisResults
          documentId={selectedAnalysis.documentId}
          analysisData={selectedAnalysis.analysis}
          onClose={() => setShowAnalysisModal(false)}
          loading={false}
          error={null}
        />
      )}
    </div>
  );
}
