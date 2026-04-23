const multer = require('multer');
const {memoryStorage} = require('multer');
//import multer, { memoryStorage } from "multer"

const upload = multer({
    Storage: memoryStorage
})

module.exports = {upload}