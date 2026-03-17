import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import './AnalysisResults.css';

/**
 * Componente para mostrar resultados de análisis MedSigLIP
 * 
 * Props:
 * - documentId: ID del documento analizado
 * - analysisData: Datos del análisis (embeddings, confidence, etc.)
 * - classificationData: Datos de clasificación de hallazgos
 * - similarDocuments: Lista de documentos similares
 * - onClose: Callback cuando se cierra el modal
 * - loading: Booleano indicando si está cargando
 * - error: Mensaje de error si lo hay
 */
export default function AnalysisResults({
  documentId,
  analysisData = null,
  classificationData = null,
  similarDocuments = [],
  onClose,
  loading = false,
  error = null,
}) {
  const { t } = useTranslation(['documents']);
  const [activeTab, setActiveTab] = useState('analysis');
  const [selectedSimilar, setSelectedSimilar] = useState(null);

  useEffect(() => {
    // Scroll to top cuando se abre modal
    const modal = document.querySelector('.analysis-results-modal');
    if (modal) {
      modal.scrollTop = 0;
    }
  }, []);

  // Renderizar estado de carga
  if (loading) {
    return (
      <div className="analysis-results-overlay">
        <div className="analysis-results-modal">
          <div className="analysis-loading">
            <div className="loading-spinner"></div>
            <p>{t('documents:analysis.analyzing')}</p>
          </div>
        </div>
      </div>
    );
  }

  // Renderizar error
  if (error) {
    return (
      <div className="analysis-results-overlay" onClick={onClose}>
        <div className="analysis-results-modal" onClick={(e) => e.stopPropagation()}>
          <div className="analysis-header">
            <h2>{t('documents:analysis.error')}</h2>
            <button className="close-button" onClick={onClose}>×</button>
          </div>
          <div className="analysis-error">
            <p>{error}</p>
          </div>
          <div className="analysis-footer">
            <button className="btn-close" onClick={onClose}>
              {t('documents:analysis.close')}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="analysis-results-overlay" onClick={onClose}>
      <div className="analysis-results-modal" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="analysis-header">
          <h2>{t('documents:analysis.title')}</h2>
          <button className="close-button" onClick={onClose}>×</button>
        </div>

        {/* Tab Navigation */}
        <div className="analysis-tabs">
          <button
            className={`tab-button ${activeTab === 'analysis' ? 'active' : ''}`}
            onClick={() => setActiveTab('analysis')}
          >
            {t('documents:analysis.tabAnalysis')}
          </button>
          <button
            className={`tab-button ${activeTab === 'classification' ? 'active' : ''}`}
            onClick={() => setActiveTab('classification')}
            disabled={!classificationData}
          >
            {t('documents:analysis.tabClassification')}
          </button>
          <button
            className={`tab-button ${activeTab === 'similar' ? 'active' : ''}`}
            onClick={() => setActiveTab('similar')}
            disabled={!similarDocuments || similarDocuments.length === 0}
          >
            {t('documents:analysis.tabSimilar')}
          </button>
        </div>

        {/* Content */}
        <div className="analysis-content">
          {/* Analysis Tab */}
          {activeTab === 'analysis' && (
            <AnalysisTab data={analysisData} t={t} documentId={documentId} />
          )}

          {/* Classification Tab */}
          {activeTab === 'classification' && classificationData && (
            <ClassificationTab data={classificationData} t={t} />
          )}

          {/* Similar Documents Tab */}
          {activeTab === 'similar' && similarDocuments.length > 0 && (
            <SimilarDocumentsTab
              documents={similarDocuments}
              selected={selectedSimilar}
              onSelect={setSelectedSimilar}
              t={t}
            />
          )}
        </div>

        {/* Footer */}
        <div className="analysis-footer">
          <button className="btn-close" onClick={onClose}>
            {t('documents:analysis.close')}
          </button>
        </div>
      </div>
    </div>
  );
}

/**
 * Pestaña de análisis - Muestra embeddings, confidence, metadata
 */
function AnalysisTab({ data, t, documentId }) {
  if (!data) {
    return (
      <div className="tab-content">
        <p className="no-data">{t('documents:analysis.noAnalysis')}</p>
      </div>
    );
  }

  return (
    <div className="tab-content analysis-tab">
      {/* Metadata */}
      <div className="analysis-section">
        <h3>{t('documents:analysis.metadata')}</h3>
        <div className="metadata-grid">
          <div className="metadata-item">
            <span className="label">{t('documents:analysis.documentId')}</span>
            <span className="value">{documentId}</span>
          </div>
          <div className="metadata-item">
            <span className="label">{t('documents:analysis.model')}</span>
            <span className="value">{data.modelo || 'MedSigLIP-448px'}</span>
          </div>
          <div className="metadata-item">
            <span className="label">{t('documents:analysis.confidence')}</span>
            <div className="confidence-bar">
              <div
                className="confidence-fill"
                style={{
                  width: `${Math.min((data.confidence || 0) * 100, 100)}%`,
                }}
              ></div>
              <span className="confidence-text">
                {((data.confidence || 0) * 100).toFixed(1)}%
              </span>
            </div>
          </div>
          <div className="metadata-item">
            <span className="label">{t('documents:analysis.embeddingDim')}</span>
            <span className="value">{data.embedding_dim || 448}</span>
          </div>
          <div className="metadata-item">
            <span className="label">{t('documents:analysis.processingTime')}</span>
            <span className="value">{(data.processing_time || 0).toFixed(2)}s</span>
          </div>
          <div className="metadata-item">
            <span className="label">{t('documents:analysis.timestamp')}</span>
            <span className="value">
              {new Date(data.timestamp).toLocaleString()}
            </span>
          </div>
        </div>
      </div>

      {/* Image Metadata */}
      {data.image_metadata && (
        <div className="analysis-section">
          <h3>{t('documents:analysis.imageMetadata')}</h3>
          <div className="metadata-grid">
            <div className="metadata-item">
              <span className="label">{t('documents:analysis.imageWidth')}</span>
              <span className="value">{data.image_metadata.width} px</span>
            </div>
            <div className="metadata-item">
              <span className="label">{t('documents:analysis.imageHeight')}</span>
              <span className="value">{data.image_metadata.height} px</span>
            </div>
            <div className="metadata-item">
              <span className="label">{t('documents:analysis.imageFormat')}</span>
              <span className="value">{data.image_metadata.format}</span>
            </div>
          </div>
        </div>
      )}

      {/* Embeddings Info */}
      {data.embeddings && (
        <div className="analysis-section">
          <h3>{t('documents:analysis.embeddings')}</h3>
          <div className="embeddings-info">
            <p>
              {t('documents:analysis.embeddingsDescription', {
                count: data.embeddings.length || 0,
              })}
            </p>
            {data.embeddings.length > 0 && (
              <div className="embeddings-preview">
                <p className="embeddings-label">{t('documents:analysis.preview')}:</p>
                <div className="embeddings-values">
                  {(Array.isArray(data.embeddings)
                    ? data.embeddings.slice(0, 10)
                    : []
                  ).map((val, idx) => (
                    <span key={idx} className="embedding-value">
                      {typeof val === 'number' ? val.toFixed(4) : val}
                    </span>
                  ))}
                  {(Array.isArray(data.embeddings) ? data.embeddings.length : 0) >
                    10 && <span className="more-values">...</span>}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * Pestaña de clasificación - Muestra hallazgos identificados
 */
function ClassificationTab({ data, t }) {
  if (!data || !data.findings) {
    return (
      <div className="tab-content">
        <p className="no-data">{t('documents:analysis.noClassification')}</p>
      </div>
    );
  }

  return (
    <div className="tab-content classification-tab">
      <div className="analysis-section">
        <h3>{t('documents:analysis.findings')}</h3>

        {Object.keys(data.findings).length > 0 ? (
          <div className="findings-grid">
            {Object.entries(data.findings).map(([finding, score]) => (
              <div key={finding} className="finding-card">
                <h4>{finding}</h4>
                <div className="score-bar">
                  <div
                    className="score-fill"
                    style={{
                      width: `${Math.min(Math.max(score, 0), 1) * 100}%`,
                    }}
                  ></div>
                  <span className="score-text">
                    {(Math.max(score, 0) * 100).toFixed(1)}%
                  </span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="no-data">{t('documents:analysis.noFindings')}</p>
        )}

        {data.timestamp && (
          <p className="classification-timestamp">
            {t('documents:analysis.classifiedAt')}:{' '}
            {new Date(data.timestamp).toLocaleString()}
          </p>
        )}
      </div>
    </div>
  );
}

/**
 * Pestaña de documentos similares - Muestra resultados de búsqueda
 */
function SimilarDocumentsTab({ documents, selected, onSelect, t }) {
  if (!documents || documents.length === 0) {
    return (
      <div className="tab-content">
        <p className="no-data">{t('documents:analysis.noSimilar')}</p>
      </div>
    );
  }

  return (
    <div className="tab-content similar-tab">
      <div className="analysis-section">
        <h3>
          {t('documents:analysis.similarCount', {
            count: documents.length,
          })}
        </h3>

        <div className="similar-documents-list">
          {documents.map((doc, idx) => (
            <div
              key={doc.id || idx}
              className={`similar-document-item ${selected === doc.id ? 'selected' : ''}`}
              onClick={() => onSelect(selected === doc.id ? null : doc.id)}
            >
              <div className="document-rank">{doc.rank || idx + 1}</div>
              <div className="document-info">
                <h4>{doc.tipo_documento || 'Documento'}</h4>
                <p className="document-specialty">
                  {doc.especialidad && `${t('documents:analysis.specialty')}: ${doc.especialidad}`}
                </p>
                <p className="document-date">
                  {doc.created_at && new Date(doc.created_at).toLocaleDateString()}
                </p>
              </div>
              <div className="similarity-score">
                <div className="score-badge">
                  <span>{(doc.similarity_score * 100).toFixed(1)}%</span>
                </div>
                <div className="score-bar-small">
                  <div
                    className="score-fill"
                    style={{
                      width: `${Math.min(doc.similarity_score, 1) * 100}%`,
                    }}
                  ></div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {documents.length >= 5 && (
          <p className="similar-info">
            {t('documents:analysis.showingTop5')}
          </p>
        )}
      </div>
    </div>
  );
}
