const adminMiddleware = (req, res, next) => {
    if(req.user.type != 'admin') return res.status(400).json({
        error: {
            message: "You can't do this action"
        }
    })
    next()
}

export default adminMiddleware;