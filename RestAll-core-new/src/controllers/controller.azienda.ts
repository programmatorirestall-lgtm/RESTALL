import Azienda from '../entities/entity.azienda';
import xlsx from 'node-xlsx'

export const uploadAziendaFromXLSX = (anagrafica: Buffer) => {
    const xlsxBuffer = xlsx.parse(anagrafica)
    // let values = []
    // let sql = "INSERT INTO azienda (clfr, codCf, ragSoc, ragSoc1, indir, cap, local, prov, codFisc, partiva, tel, tel2, fax, email, codNaz, codsdi, pec_fe) VALUES ?"

    // xlsxBuffer.map((sheet) => {
    //     sheet.data.slice(1).map((row) => {
    //         if(row[16] == undefined) row[16] = ''
    //         values.push(row)
    //     })
    // })

    // if(!values.length) return res.status(200).json({
    //     message: "Nessun elemento da aggiungere alla warehouse"
    // })

    // pool.query(sql, [values], (err, data) => {
    //     if(err){
    //         return res.status(500).json({err})
    //     }

    //     return res.status(200).json(data)
    // })
}