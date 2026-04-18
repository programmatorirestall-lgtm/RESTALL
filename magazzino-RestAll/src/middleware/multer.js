import multer, { memoryStorage } from "multer"
import path from 'path'

const upload = multer({
    Storage: memoryStorage,
    fileFilter: function (req, file, callback) {
        var ext = path.extname(file.originalname);
        // if(ext !== '.xlsx') {
        //     return callback(new Error('Solo file xlsx sono consentiti'))
        // }
        callback(null, true)
    }
})

export {upload};