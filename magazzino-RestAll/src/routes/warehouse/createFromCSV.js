import Router from 'express';
import fs from 'fs';
import path from 'path';
import multer from 'multer';
import csv from 'csv-parser';
import pool from '../../helpers/mysql.js';
import Products from '../../models/products.js';

const router = new Router();
const upload = multer({ dest: 'uploads/' });

const REQUIRED_COLUMNS = [
  'CODART', 'DESART', 'UNMIS', 'ALIVA', 'PREZZO1', 'PREZZO2',
  'COSTOST', 'PROVV', 'VENDI', 'COSTO', 'SCONTO', 'SCONTO2',
  'SCONTO3', 'CODEAN', 'DESART2', 'ALIAS'
];

// ✅ Funzione principale: parsing + pulizia duplicati
async function parseAndCleanCSV(filepath) {
  return new Promise((resolve, reject) => {
    const cleanedData = [];
    const seen = new Set();
    let headersValidated = false;

    fs.createReadStream(filepath)
      .pipe(csv({ separator: ';' }))
      .on('headers', (headers) => {
        const missing = REQUIRED_COLUMNS.filter(col => !headers.includes(col));
        if (missing.length > 0) {
          return reject(new Error(`Colonne mancanti: ${missing.join(', ')}`));
        }
        headersValidated = true;
      })
      .on('data', (row) => {
        if (!headersValidated) return;

        const key = `${row['CODART']?.trim()}|${row['DESART']?.trim()}`;
        if (!seen.has(key)) {
          seen.add(key);
          const rowValues = REQUIRED_COLUMNS.map((col) => row[col]?.trim() ?? null);
          cleanedData.push(rowValues);
        }
      })
      .on('end', () => {
        resolve(cleanedData);
      })
      .on('error', (err) => {
        reject(new Error('Errore nella lettura del CSV: ' + err.message));
      });
  });
}

// ✅ Funzione per l'inserimento nel DB
async function importCleanedData(dataRows) {
  return new Promise((resolve, reject) => {
    const query = `INSERT INTO magazzino (${REQUIRED_COLUMNS.map(col => `\`${col}\``).join(', ')}) VALUES ?`;
    pool.query(query, [dataRows], (err, result) => {
      if (err) return reject(err);
      resolve(result);
    });
  });
}

// ✅ Route POST completa
router.post('/', upload.single('warehouse'), async (req, res) => {
  const filePath = req.file?.path;

  if (!req.file) {
    return res.status(400).send("File non caricato! Assicurati di inviare un file nel campo 'warehouse'.");
  }

  try {
    // 1. Leggi e valida il file
    const cleanedData = await parseAndCleanCSV(filePath);

    if (cleanedData.length === 0) {
      return res.status(400).send("Il file non contiene dati validi dopo la rimozione dei duplicati.");
    }

    // 2. Svuota il DB solo dopo la validazione
    await new Products({}).then((p) => p.deleteAll());

    // 3. Importa i dati puliti
    await importCleanedData(cleanedData);

    res.status(200).send("Dati importati con successo nel database!");
  } catch (error) {
    console.error("Errore:", error);
    res.status(400).send("Errore durante l'importazione: " + error.message);
  } finally {
    // 4. Elimina il file CSV temporaneo
    fs.unlink(filePath, (err) => {
      if (err) console.error("Errore nella rimozione del file temporaneo:", err);
    });
  }
});

export default router;
