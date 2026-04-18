import multer, {memoryStorage} from "multer";

export const Multer = multer({
    storage: memoryStorage()
})