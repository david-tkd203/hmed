import React, { useState, useEffect } from 'react';
import axiosInstance from './api/axiosInstance';
import { ArrowLeft, Search, Prescription2, ExclamationCircle, Gear } from 'react-bootstrap-icons';
import { useTranslation } from 'react-i18next';
import './Medications.css';

export default function Medications({ user, onBack, theme }) {
  const { t, i18n } = useTranslation();
  const [medications, setMedications] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedMedication, setSelectedMedication] = useState(null);
  const [myMedications, setMyMedications] = useState([]);

  // Cargar medicamentos del usuario desde LocalStorage
  useEffect(() => {
    const saved = localStorage.getItem('user_medications');
    if (saved) {
      setMyMedications(JSON.parse(saved));
    }
  }, []);

  // Función para extraer cantidad del nombre (ej: "Mejoral 400mg" -> "400mg")
  const extractQuantityFromName = (name) => {
    const match = name.match(/(\d+(?:\.\d+)?\s*(?:mg|g|ml|mcg|IU|%))$/i);
    return match ? match[1] : '';
  };

  // Función para limpiar el nombre removiendo la cantidad
  const cleanName = (name) => {
    return name.replace(/\s*\d+(?:\.\d+)?\s*(?:mg|g|ml|mcg|IU|%)?\s*$/i, '').trim();
  };

  // Buscar medicamentos en base de datos local ISP Chile
  const searchMedications = async (query) => {
    if (!query.trim()) {
      setMedications([]);
      return;
    }

    setLoading(true);
    setError('');
    try {
      const queryLower = query.toLowerCase();
      
      // Buscar en base de datos local del ISP
      const results = searchInLocalISPDatabase(queryLower);

      if (results.length > 0) {
        const formatted = results.map((drug, idx) => {
          const nombreCompleto = drug.nombre || drug.nombreComercial || query;
          const cantidad = extractQuantityFromName(nombreCompleto);
          const nombre = cleanName(nombreCompleto);
          const nombreGenerico = drug.principioActivo || drug.nombreGenerico || 'No especificado';
          const fabricante = drug.laboratorio || drug.fabricante || 'Fabricante desconocido';
          const presentacion = drug.presentacion || drug.dosageForm || 'No especificada';
          
          return {
            id: `${idx}-${Date.now()}-${drug.rut || 'isp'}`,
            name: nombre,
            quantity: cantidad,
            genericName: nombreGenerico,
            manufacturer: fabricante,
            activeIngredients: [nombreGenerico],
            excipients: drug.excipientes || [],
            dosageForm: presentacion,
            rut: drug.rut || '',
            estado: drug.estado || 'Vigente',
            indications: drug.indicaciones || 'No especificadas',
            contraindications: drug.contraindicaciones || [],
            precautions: drug.precauciones || [],
            pregnancyLactation: drug.embarazoLactancia || 'Consulte con profesional de salud',
            warnings: drug.warnings || [],
            purpose: drug.purpose || `Medicamento registrado en Chile`,
            fullData: drug
          };
        });

        setMedications(formatted);
      } else {
        setMedications([]);
        setError(`No se encontraron medicamentos para "${query}". Intenta con otro término.`);
      }
    } catch (err) {
      setMedications([]);
      setError(`Error en búsqueda: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // Base de datos local del ISP para búsquedas offline - Medicamentos chilenos con ingredientes completos
  const searchInLocalISPDatabase = (query) => {
    const ispDatabase = [
      // Analgésicos y antiinflamatorios
      { nombre: 'Paracetamol 500mg', principioActivo: 'Paracetamol', laboratorio: 'Bayer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Celulosa microcristalina', 'Estearato de magnesio', 'Talco', 'Dióxido de silicio'], indicaciones: 'Analgésico y antifebril para dolores leves a moderados y fiebre', contraindicaciones: ['Hipersensibilidad al paracetamol', 'Insuficiencia hepática grave', 'Consumo excesivo de alcohol'], precauciones: ['No exceder 3-4g diarios en adultos', 'Usar con cautela en pacientes con enfermedad hepática', 'Riesgo de daño hepático con sobredosis'], embarazoLactancia: 'Compatible durante embarazo y lactancia en dosis terapéuticas. Considerado de primera línea para fiebre y dolor en gestación' },
      { nombre: 'Kitadol 500mg', principioActivo: 'Paracetamol', laboratorio: 'Tecnoquímica', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Celulosa microcristalina', 'Estearato de magnesio', 'Talco'], indicaciones: 'Analgésico y antitérmico para dolores leves a moderados y fiebre', contraindicaciones: ['Alergia al paracetamol', 'Insuficiencia hepática severa'], precauciones: ['Límite máximo 4g/día', 'Evitar con enfermedad hepática crónica', 'Cautela con consumo de alcohol'], embarazoLactancia: 'Seguro en embarazo y lactancia. Fármaco de elección para síntomas febriles' },
      { nombre: 'Ibupirac 400mg', principioActivo: 'Ibuprofeno', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio', 'Dióxido de silicio', 'Óxido de hierro'], indicaciones: 'Antiinflamatorio selectivo para dolores, inflamación, fiebre y menstruación dolorosa', contraindicaciones: ['Úlcera péptica activa', 'Alergia a AINE', 'Insuficiencia cardíaca severa', 'Embarazo (especialmente 3er trimestre)'], precauciones: ['Usar dosis mínima efectiva', 'Riesgo gastrointestinal y cardiovascular', 'Evitar en insuficiencia renal', 'No combinar con otros AINE'], embarazoLactancia: 'CONTRAINDICADO en 3er trimestre. Evitar en 1er y 2do trimestre. Consultar profesional antes de usar' },
      { nombre: 'Omeprazol 20mg', principioActivo: 'Omeprazol', laboratorio: 'Raffo', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Fosfato dibásico de calcio dihidrato', 'Celulosa microcristalina', 'Talco', 'Estearato de magnesio', 'Hipromelosa', 'Dióxido de titanio'], indicaciones: 'Inhibidor de bomba de protones para acidez, reflujo, úlceras gástricas y esofagitis', contraindicaciones: ['Hipersensibilidad al omeprazol', 'Combinación con clopidogrel (reduce efectividad)'], precauciones: ['Uso prolongado puede reducir absorción de calcio y vitamina B12', 'Riesgo aumentado de fracturas óseas con uso crónico', 'Puede enmascarar malignidad gástrica', 'Monitoreo renal en uso prolongado'], embarazoLactancia: 'Categoría B - Seguro en embarazo. Pasa a leche materna en pequeñas cantidades. Generalmente seguro en lactancia' },
      { nombre: 'Metformina 850mg', principioActivo: 'Metformina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio', 'Dióxido de silicio coloidal'], indicaciones: 'Antidiabético biguanida para diabetes tipo 2, síndrome de ovario poliquístico', contraindicaciones: ['Insuficiencia renal (TFG <30 mL/min)', 'Acidosis metabólica o cetoacidosis diabética', 'Falla cardíaca descompensada', 'Enfermedad hepática grave'], precauciones: ['Riesgo de acidosis láctica especialmente en disfunción renal', 'Monitorear función renal anualmente', 'Discontinuar antes de procedimientos con contraste yodado', 'Evitar en ayuno prolongado'], embarazoLactancia: 'Controversia en embarazo - algunos consideran relativo seguro, otros prefieren insulina. Pasa a leche materna. Consultar especialista' },
      { nombre: 'Alprazolam 0.5mg', principioActivo: 'Alprazolam', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'], indicaciones: 'Ansiolítico benzodiacepina para ansiedad, ataques de pánico, insomnio relacionado con ansiedad', contraindicaciones: ['Hipersensibilidad a benzodiacepinas', 'Miastenia gravis', 'Apnea del sueño severa', 'Insuficiencia hepática grave'], precauciones: ['Potencial de dependencia y abuso', 'Riesgo de depresión del SNC con otros depresores', 'Evitar cambios abruptos de dosis', 'No conducir ni operar maquinaria', 'Riesgo de caídas en adultos mayores'], embarazoLactancia: 'CONTRAINDICADO en embarazo especialmente 1er trimestre - riesgo de malformaciones. Pasa a leche - riesgo de sedación infantil' },
      { nombre: 'Sertraline 50mg', principioActivo: 'Sertralina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio', 'Dióxido de silicio'], indicaciones: 'ISRS para depresión, ansiedad, TOC, TEPT, trastorno disfórico premenstrual', contraindicaciones: ['Combinación con IMAO', 'Hipersensibilidad', 'Uso simultáneo de linezolid'], precauciones: ['Síndrome de serotonina con otros serotoninérgicos', 'Riesgo de hemorragia aumentado', 'Hiponatremia principalmente en adultos mayores', 'Latencia de efecto 2-4 semanas', 'Evitar discontinuación abrupta (síndrome de supresión)'], embarazoLactancia: 'Categoría C - Riesgo moderado. Beneficio puede superar riesgo en depresión severa. Comunmente usado en embarazo. Pasa a leche en cantidades pequeñas' },

      { nombre: 'Ranitidina 150mg', principioActivo: 'Ranitidina', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Famotidina 20mg', principioActivo: 'Famotidina', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Croscarmelosa', 'Estearato de magnesio'] },
      { nombre: 'Metoclopramida 10mg', principioActivo: 'Metoclopramida', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio', 'Talco', 'Dióxido de silicio'] },
      { nombre: 'Domperidona 10mg', principioActivo: 'Domperidona', laboratorio: 'Janssen', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Simeticona 80mg', principioActivo: 'Simeticona', laboratorio: 'Bayer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Almidón', 'Estearato de magnesio'] },
      { nombre: 'Lactasa 4500UI', principioActivo: 'Lactasa', laboratorio: 'Sofar', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Estearato de magnesio', 'Dióxido de silicio'] },
      
      // Cardiovasculares (mantener formato corto para brevedad)
      { nombre: 'Atorvastatina 10mg', principioActivo: 'Atorvastatina', laboratorio: 'Pharmalink', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Dihidrógeno fosfato de calcio', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Atorvastatina 20mg', principioActivo: 'Atorvastatina', laboratorio: 'Pharmalink', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Dihidrógeno fosfato de calcio', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Atorvastatina 40mg', principioActivo: 'Atorvastatina', laboratorio: 'Pharmalink', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Dihidrógeno fosfato de calcio', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Simvastatina 20mg', principioActivo: 'Simvastatina', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Lovastatina 20mg', principioActivo: 'Lovastatina', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Lisinopril 5mg', principioActivo: 'Lisinopril', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Lisinopril 10mg', principioActivo: 'Lisinopril', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Lisinopril 20mg', principioActivo: 'Lisinopril', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Enalapril 5mg', principioActivo: 'Enalapril', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Enalapril 10mg', principioActivo: 'Enalapril', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Losartán 50mg', principioActivo: 'Losartán', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Valsartán 80mg', principioActivo: 'Valsartán', laboratorio: 'Novartis', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Metoprolol 50mg', principioActivo: 'Metoprolol', laboratorio: 'AstraZeneca', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Metoprolol 100mg', principioActivo: 'Metoprolol', laboratorio: 'AstraZeneca', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Atenolol 25mg', principioActivo: 'Atenolol', laboratorio: 'Zenith', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Atenolol 50mg', principioActivo: 'Atenolol', laboratorio: 'Zenith', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Propranolol 10mg', principioActivo: 'Propranolol', laboratorio: 'Zenith', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Amlodipina 5mg', principioActivo: 'Amlodipina', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Amlodipina 10mg', principioActivo: 'Amlodipina', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Diltiazem 30mg', principioActivo: 'Diltiazem', laboratorio: 'Boehringer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Aspirina 100mg', principioActivo: 'Ácido Acetilsalicílico', laboratorio: 'Bayer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Celulosa', 'Estearato de magnesio'] },
      
      // Diabetes
      { nombre: 'Metformina 500mg', principioActivo: 'Metformina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio', 'Dióxido de silicio coloidal'] },
      { nombre: 'Metformina 850mg', principioActivo: 'Metformina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio', 'Dióxido de silicio coloidal'] },
      { nombre: 'Glibenclamida 2.5mg', principioActivo: 'Glibenclamida', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Glibenclamida 5mg', principioActivo: 'Glibenclamida', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Glipizida 5mg', principioActivo: 'Glipizida', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Insulina Humana 100UI', principioActivo: 'Insulina Humana', laboratorio: 'Novo Nordisk', presentacion: 'Inyectable', estado: 'Vigente', excipientes: ['Fenol', 'Glicerol', 'Agua para inyectables', 'Cloruro de sodio', 'Fosfato de sodio dibásico'] },
      
      // Psicotropos (algunos representativos)
      { nombre: 'Alprazolam 0.25mg', principioActivo: 'Alprazolam', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Alprazolam 0.5mg', principioActivo: 'Alprazolam', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Alprazolam 1mg', principioActivo: 'Alprazolam', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Diazepam 5mg', principioActivo: 'Diazepam', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio', 'Talco'] },
      { nombre: 'Diazepam 10mg', principioActivo: 'Diazepam', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio', 'Talco'] },
      { nombre: 'Flurazepam 15mg', principioActivo: 'Flurazepam', laboratorio: 'Roche', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Midazolam 15mg', principioActivo: 'Midazolam', laboratorio: 'Roche', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Sertraline 50mg', principioActivo: 'Sertralina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Sertraline 100mg', principioActivo: 'Sertralina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Fluoxetina 20mg', principioActivo: 'Fluoxetina', laboratorio: 'Eli Lilly', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Estearato de magnesio', 'Dióxido de silicio'] },
      { nombre: 'Fluoxetina 40mg', principioActivo: 'Fluoxetina', laboratorio: 'Eli Lilly', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Estearato de magnesio'] },
      { nombre: 'Paroxetina 20mg', principioActivo: 'Paroxetina', laboratorio: 'GlaxoSmithKline', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Citalopram 20mg', principioActivo: 'Citalopram', laboratorio: 'Lundbeck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Venlafaxina 37.5mg', principioActivo: 'Venlafaxina', laboratorio: 'Wyeth', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Estearato de magnesio'] },
      { nombre: 'Amitriptilina 10mg', principioActivo: 'Amitriptilina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Amitriptilina 25mg', principioActivo: 'Amitriptilina', laboratorio: 'Raffo', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Clomipramina 10mg', principioActivo: 'Clomipramina', laboratorio: 'Anafranil', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Haloperidol 1mg', principioActivo: 'Haloperidol', laboratorio: 'McNeil', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Risperidona 1mg', principioActivo: 'Risperidona', laboratorio: 'Janssen', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Olanzapina 5mg', principioActivo: 'Olanzapina', laboratorio: 'Eli Lilly', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Quetiapina 25mg', principioActivo: 'Quetiapina', laboratorio: 'AstraZeneca', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Levodopa 250mg', principioActivo: 'Levodopa', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Bromocriptina 2.5mg', principioActivo: 'Bromocriptina', laboratorio: 'Sandoz', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      
      // Antibióticos (representativos)
      { nombre: 'Amoxicilina 500mg', principioActivo: 'Amoxicilina', laboratorio: 'Panalab', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Talco', 'Dióxido de titanio', 'Óxido de hierro rojo', 'Gelatina'] },
      { nombre: 'Amoxicilina 250mg', principioActivo: 'Amoxicilina', laboratorio: 'Panalab', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Talco', 'Dióxido de titanio', 'Gelatina'] },
      { nombre: 'Amoxicilina + Clavulánico', principioActivo: 'Amoxicilina/Ácido Clavulánico', laboratorio: 'GlaxoSmithKline', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Cefalexina 500mg', principioActivo: 'Cefalexina', laboratorio: 'Raffo', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Dióxido de titanio', 'Gelatina'] },
      { nombre: 'Cefalexina 250mg', principioActivo: 'Cefalexina', laboratorio: 'Raffo', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Cefixima 200mg', principioActivo: 'Cefixima', laboratorio: 'Sanofi', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Ciprofloxacina 250mg', principioActivo: 'Ciprofloxacina', laboratorio: 'Bayer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Ciprofloxacina 500mg', principioActivo: 'Ciprofloxacina', laboratorio: 'Bayer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Azitromicina 250mg', principioActivo: 'Azitromicina', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Azitromicina 500mg', principioActivo: 'Azitromicina', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Claritromicina 250mg', principioActivo: 'Claritromicina', laboratorio: 'Abbott', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Eritromicina 250mg', principioActivo: 'Eritromicina', laboratorio: 'Abbott', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Tetraciclina 250mg', principioActivo: 'Tetraciclina', laboratorio: 'Lederle', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Doxiciclina 100mg', principioActivo: 'Doxiciclina', laboratorio: 'Wyeth', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Clindamicina 300mg', principioActivo: 'Clindamicina', laboratorio: 'Pfizer', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Sulfametoxazol + Trimetoprim', principioActivo: 'Sulfametoxazol/Trimetoprim', laboratorio: 'Roche', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Metronidazol 250mg', principioActivo: 'Metronidazol', laboratorio: 'Panalab', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      
      // Antihistamínicos
      { nombre: 'Loratadina 10mg', principioActivo: 'Loratadina', laboratorio: 'Schering', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Ebastina 10mg', principioActivo: 'Ebastina', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Cetirizina 10mg', principioActivo: 'Cetirizina', laboratorio: 'UCB', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Desloratadina 5mg', principioActivo: 'Desloratadina', laboratorio: 'Schering', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Fexofenadina 180mg', principioActivo: 'Fexofenadina', laboratorio: 'Aventis', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Goma de tragacanto', 'Estearato de magnesio'] },
      { nombre: 'Difenhidramina 25mg', principioActivo: 'Difenhidramina', laboratorio: 'Parke Davis', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Prometazina 25mg', principioActivo: 'Prometazina', laboratorio: 'Aventis', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      
      // Broncodilatadores
      { nombre: 'Salbutamol 100mcg', principioActivo: 'Salbutamol', laboratorio: 'GlaxoSmithKline', presentacion: 'Inhalador', estado: 'Vigente', excipientes: ['HFA-134a', 'Oleato de sorbitán', 'Alcohol etílico'] },
      { nombre: 'Fenoterol 100mcg', principioActivo: 'Fenoterol', laboratorio: 'Boehringer Ingelheim', presentacion: 'Inhalador', estado: 'Vigente', excipientes: ['HFA-134a', 'Oleato de sorbitán'] },
      { nombre: 'Terbutalina 2.5mg', principioActivo: 'Terbutalina', laboratorio: 'Boehringer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      { nombre: 'Teofilina 100mg', principioActivo: 'Teofilina', laboratorio: 'Abbott', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Fluticasona 250mcg', principioActivo: 'Fluticasona', laboratorio: 'GlaxoSmithKline', presentacion: 'Inhalador', estado: 'Vigente', excipientes: ['HFA-134a', 'Oleato de sorbitán'] },
      { nombre: 'Beclometasona 50mcg', principioActivo: 'Beclometasona', laboratorio: 'Aventis', presentacion: 'Inhalador', estado: 'Vigente', excipientes: ['HFA-134a', 'Oleato de sorbitán'] },
      
      // Anticoagulantes
      { nombre: 'Warfarina 2mg', principioActivo: 'Warfarina', laboratorio: 'Bristol Myers', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Warfarina 5mg', principioActivo: 'Warfarina', laboratorio: 'Bristol Myers', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Clopidogrel 75mg', principioActivo: 'Clopidogrel', laboratorio: 'Sanofi', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Heparina 5000UI', principioActivo: 'Heparina', laboratorio: 'Roche', presentacion: 'Inyectable', estado: 'Vigente', excipientes: ['Solución salina normal', 'Agua para inyectables'] },
      
      // Vitaminas (resto)
      { nombre: 'Vitamina C 500mg', principioActivo: 'Ácido Ascórbico', laboratorio: 'Various', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Vitamina D 1000UI', principioActivo: 'Colecalciferol', laboratorio: 'Various', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Lactosa monohidrato', 'Estearato de magnesio'] },
      { nombre: 'Vitamina B12 1000mcg', principioActivo: 'Cianocobalamina', laboratorio: 'Various', presentacion: 'Inyectable', estado: 'Vigente', excipientes: ['Agua para inyectables', 'Cloruro de sodio'] },
      { nombre: 'Hierro 300mg', principioActivo: 'Sulfato Ferroso', laboratorio: 'Various', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Almidón de maíz', 'Talco', 'Gelatina'] },
      { nombre: 'Calcio 500mg', principioActivo: 'Carbonato de Calcio', laboratorio: 'Various', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Magnesio 250mg', principioActivo: 'Magnesio', laboratorio: 'Various', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Zinc 15mg', principioActivo: 'Zinc', laboratorio: 'Various', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      
      // Oftalmológicos
      { nombre: 'Brimonidina 0.2%', principioActivo: 'Brimonidina', laboratorio: 'Allergan', presentacion: 'Gotas', estado: 'Vigente', excipientes: ['Borax', 'Ácido bórico', 'Cloruro de sodio', 'Agua purificada'] },
      { nombre: 'Timolol 0.5%', principioActivo: 'Timolol', laboratorio: 'Merck', presentacion: 'Gotas', estado: 'Vigente', excipientes: ['Fosfato dibásico de sodio', 'Fosfato monobásico de sodio', 'Cloruro de sodio'] },
      { nombre: 'Latanoprost 0.005%', principioActivo: 'Latanoprost', laboratorio: 'Pfizer', presentacion: 'Gotas', estado: 'Vigente', excipientes: ['Fosfato de sodio dibásico', 'Fosfato de sodio monobásico', 'Cloruro de sodio'] },
      
      // Dermatológicos
      { nombre: 'Terbinafina 250mg', principioActivo: 'Terbinafina', laboratorio: 'Novartis', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Clotrimazol 1%', principioActivo: 'Clotrimazol', laboratorio: 'Bayer', presentacion: 'Pomada', estado: 'Vigente', excipientes: ['Alcohol bencílico', 'Estearato de polietileno glicol', 'Base de pomada'] },
      { nombre: 'Ketoconazol 200mg', principioActivo: 'Ketoconazol', laboratorio: 'Janssen', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      
      // Antiparasitarios
      { nombre: 'Mebendazol 500mg', principioActivo: 'Mebendazol', laboratorio: 'Janssen', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Albendazol 400mg', principioActivo: 'Albendazol', laboratorio: 'GSK', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Ivermectina 6mg', principioActivo: 'Ivermectina', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      
      // Hormonales
      { nombre: 'Levotiroxina 50mcg', principioActivo: 'Levotiroxina', laboratorio: 'Abbott', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Levotiroxina 100mcg', principioActivo: 'Levotiroxina', laboratorio: 'Abbott', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Levotiroxina 200mcg', principioActivo: 'Levotiroxina', laboratorio: 'Abbott', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Dexametasona 0.5mg', principioActivo: 'Dexametasona', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Prednisolona 5mg', principioActivo: 'Prednisolona', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      
      // Antiinfecciosos
      { nombre: 'Fluconazol 150mg', principioActivo: 'Fluconazol', laboratorio: 'Pfizer', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Estearato de magnesio'] },
      { nombre: 'Griseofulvina 250mg', principioActivo: 'Griseofulvina', laboratorio: 'Novartis', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa', 'Celulosa', 'Estearato de magnesio'] },
      
      // Otros
      { nombre: 'Sildenafilo 100mg', principioActivo: 'Sildenafilo', laboratorio: 'Pfizer', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Dihidrógeno fosfato de calcio', 'Croscarmelosa sódica', 'Estearato de magnesio'] },
      { nombre: 'Finasterida 5mg', principioActivo: 'Finasterida', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] },
      { nombre: 'Tamsulosina 0.4mg', principioActivo: 'Tamsulosina', laboratorio: 'Yamanouchi', presentacion: 'Cápsula', estado: 'Vigente', excipientes: ['Celulosa microcristalina', 'Almidón de maíz', 'Dióxido de silicio coloidal'] },
      { nombre: 'Fenilefrina 10mg', principioActivo: 'Fenilefrina', laboratorio: 'Merck', presentacion: 'Tableta', estado: 'Vigente', excipientes: ['Lactosa monohidrato', 'Celulosa microcristalina', 'Estearato de magnesio'] }
    ];

    return ispDatabase.filter(med => 
      med.nombre?.toLowerCase().includes(query) ||
      med.principioActivo?.toLowerCase().includes(query)
    ).slice(0, 20);
  };

  // Debounce para búsqueda
  useEffect(() => {
    const timer = setTimeout(() => {
      if (searchTerm.trim()) {
        searchMedications(searchTerm);
      }
    }, 500);

    return () => clearTimeout(timer);
  }, [searchTerm]);

  // Agregar medicamento a mi lista
  const addToMyMedications = (medication) => {
    const newMed = {
      id: Date.now(),
      ...medication,
      addedAt: new Date().toLocaleDateString()
    };

    const updated = [...myMedications, newMed];
    setMyMedications(updated);
    localStorage.setItem('user_medications', JSON.stringify(updated));
  };

  // Eliminar de mi lista
  const removeMedication = (id) => {
    const updated = myMedications.filter(m => m.id !== id);
    setMyMedications(updated);
    localStorage.setItem('user_medications', JSON.stringify(updated));
  };

  return (
    <div className={`medications-container ${theme}`}>
      {/* Header */}
      <div className="medications-header">
        <button onClick={onBack} className="back-btn">
          <ArrowLeft size={24} /> {t('navigation.back')}
        </button>
        <h1>{t('medications.title')}</h1>
        <div className="header-spacer"></div>
      </div>

      {/* Search Section */}
      <div className="search-section">
        <div className="search-container">
          <Search size={20} />
          <input
            type="text"
            placeholder={t('medications.searchPlaceholder')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
        </div>
      </div>

      <main className="medications-main">
        {/* Mi Lista de Medicamentos */}
        <section className="my-medications">
          <div className="section-header">
            <Prescription2 size={28} />
            <h2>{t('medications.myMedications')}</h2>
          </div>

          {myMedications.length === 0 ? (
            <div className="empty-state">
              <Prescription2 size={48} />
              <p>{t('medications.noMedications')}</p>
              <span>{t('medications.addMedications')}</span>
            </div>
          ) : (
            <div className="medications-grid">
              {myMedications.map((med) => (
                <div key={med.id} className="medication-card my-med-card">
                  <div className="card-header">
                    <h3>{med.name}</h3>
                    <button
                      onClick={() => removeMedication(med.id)}
                      className="btn-remove"
                      title={t('medications.removeFromMyMedications')}
                    >
                      ×
                    </button>
                  </div>
                  <div className="card-body">
                    <p className="generic"><strong>{t('medications.genericName')}:</strong> {med.genericName}</p>
                    <p className="manufacturer"><strong>{t('medications.manufacturer')}:</strong> {med.manufacturer}</p>
                    <p className="dosage"><strong>{t('medications.dosage')}:</strong> {med.dosageForm}</p>
                    <p className="added-date">{t('medications.addedDate')}: {med.addedAt}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* Búsqueda de Medicamentos */}
        {searchTerm && (
          <section className="search-results">
            <div className="section-header">
              <Search size={28} />
              <h2>{t('medications.searchResults')}</h2>
            </div>

            {loading ? (
              <div className="loading-container">
                <Gear size={40} className="spinner" />
                <p>{t('medications.loading')}</p>
              </div>
            ) : error ? (
              <div className="error-message">
                <ExclamationCircle size={32} />
                <p>{error}</p>
              </div>
            ) : medications.length === 0 && !loading ? (
              <div className="empty-state">
                <Search size={48} />
                <p>{t('medications.noResults')}</p>
                <span>{t('medications.tryAgain')}</span>
              </div>
            ) : (
              <div className="medications-grid">
                {medications.map((med) => {
                  const isAdded = myMedications.some(m => m.name === med.name);
                  return (
                    <div
                      key={med.id}
                      className={`medication-card ${isAdded ? 'added' : ''}`}
                      onClick={() => setSelectedMedication(med)}
                    >
                      <div className="card-header">
                        <h3>{med.name}</h3>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            isAdded ? removeMedication(med.id) : addToMyMedications(med);
                          }}
                          className={`btn-add ${isAdded ? 'btn-remove' : 'btn-add'}`}
                        >
                          {isAdded ? `✓ ${t('medications.alreadyAdded')}` : `+ ${t('medications.addMedicationBtn')}`}
                        </button>
                      </div>
                      <div className="card-body">
                        <p className="generic"><strong>{t('medications.genericName')}:</strong> {med.genericName}</p>
                        <p className="manufacturer"><strong>{t('medications.manufacturer')}:</strong> {med.manufacturer}</p>
                        <p className="dosage"><strong>{t('medications.dosage')}:</strong> {med.dosageForm}</p>
                        {med.quantity && (
                          <p className="quantity"><strong>{t('medications.quantity')}:</strong> {med.quantity}</p>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </section>
        )}
      </main>

      {/* Modal de Detalles */}
      {selectedMedication && (
        <div className="modal-overlay" onClick={() => setSelectedMedication(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <button onClick={() => setSelectedMedication(null)} className="btn-close">×</button>
            
            <div className="modal-header">
              <div className="modal-title-section">
                <div className="header-top">
                  <h2 className="medication-name">{selectedMedication.name}</h2>
                  {selectedMedication.quantity && (
                    <span className="medication-quantity">{selectedMedication.quantity}</span>
                  )}
                </div>
                {selectedMedication.manufacturer && (
                  <p className="medication-brand">{selectedMedication.manufacturer}</p>
                )}
              </div>
            </div>

            <div className="modal-body">
              <div className="detail-section">
                <h4>{t('medications.medicationDetails')}</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="label">{t('medications.genericName')}:</span>
                    <span className="value">{selectedMedication.genericName}</span>
                  </div>
                  <div className="detail-item">
                    <span className="label">{t('medications.dosage')}:</span>
                    <span className="value dosage-highlight">{selectedMedication.dosageForm}</span>
                  </div>
                  {selectedMedication.estado && (
                    <div className="detail-item">
                      <span className="label">Estado ISP:</span>
                      <span className="value status-badge">{selectedMedication.estado}</span>
                    </div>
                  )}
                </div>
              </div>

              <div className="detail-section">
                <h4>{t('medications.activeIngredients')}</h4>
                {selectedMedication.activeIngredients.length > 0 ? (
                  <ul className="ingredients-list">
                    {(Array.isArray(selectedMedication.activeIngredients[0]) 
                      ? selectedMedication.activeIngredients[0] 
                      : selectedMedication.activeIngredients
                    ).map((ing, idx) => (
                      <li key={idx}>{typeof ing === 'string' ? ing : JSON.stringify(ing)}</li>
                    ))}
                  </ul>
                ) : (
                  <p>N/A</p>
                )}
              </div>

              {selectedMedication.excipients && selectedMedication.excipients.length > 0 && (
                <div className="detail-section">
                  <h4>{t('medications.excipients')}</h4>
                  <ul className="ingredients-list">
                    {selectedMedication.excipients.map((excip, idx) => (
                      <li key={idx}>{excip}</li>
                    ))}
                  </ul>
                </div>
              )}

              <div className="detail-section">
                <h4>{t('medications.indications')}</h4>
                <p>{selectedMedication.indications}</p>
              </div>

              {selectedMedication.contraindications && selectedMedication.contraindications.length > 0 && (
                <div className="detail-section warning">
                  <h4>{t('medications.contraindications')}</h4>
                  <ul className="warnings-list">
                    {selectedMedication.contraindications.map((contra, idx) => (
                      <li key={idx}>{contra}</li>
                    ))}
                  </ul>
                </div>
              )}

              {selectedMedication.precautions && selectedMedication.precautions.length > 0 && (
                <div className="detail-section">
                  <h4>{t('medications.precautions')}</h4>
                  <ul className="warnings-list">
                    {selectedMedication.precautions.map((precaution, idx) => (
                      <li key={idx}>{precaution}</li>
                    ))}
                  </ul>
                </div>
              )}

              {selectedMedication.pregnancyLactation && (
                <div className="detail-section">
                  <h4>{t('medications.pregnancyLactation')}</h4>
                  <p>{selectedMedication.pregnancyLactation}</p>
                </div>
              )}

              {selectedMedication.warnings.length > 0 && (
                <div className="detail-section warning">
                  <h4>{t('medications.warnings')}</h4>
                  <ul className="warnings-list">
                    {selectedMedication.warnings.slice(0, 3).map((warning, idx) => (
                      <li key={idx}>{warning}</li>
                    ))}
                  </ul>
                </div>
              )}

              <div className="modal-actions">
                <button
                  onClick={() => {
                    const isAdded = myMedications.some(m => m.name === selectedMedication.name);
                    if (isAdded) {
                      removeMedication(myMedications.find(m => m.name === selectedMedication.name).id);
                    } else {
                      addToMyMedications(selectedMedication);
                    }
                    setSelectedMedication(null);
                  }}
                  className={`btn-action ${myMedications.some(m => m.name === selectedMedication.name) ? 'btn-remove' : 'btn-add'}`}
                >
                  {myMedications.some(m => m.name === selectedMedication.name) ? t('medications.removeFromMyMedications') : t('medications.addToMyMedications')}
                </button>
                <button
                  onClick={() => setSelectedMedication(null)}
                  className="btn-action btn-close-modal"
                >
                  {t('medications.close')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
