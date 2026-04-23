import multer, { memoryStorage } from "multer"

const upload = multer({
    Storage: memoryStorage
})

export {upload};

// fileFilter: function (req, file, callback) {
//     var ext = path.extname(file.originalname);
//     if(ext !== '.png' && ext !== '.jpg' && ext !== '.gif' && ext !== '.jpeg') {
//         return callback(new Error('Only images are allowed'))
//     }
//     callback(null, true)
// }