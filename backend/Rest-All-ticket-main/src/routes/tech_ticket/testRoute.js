import Router from 'express';

const router = new Router();

router.get('/', (req, res) => {
    console.log("test ok!")
    res.status(201).json({
        message: "test ok!"
    })
})

export default router