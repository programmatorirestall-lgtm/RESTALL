const techMiddleware = (req, res, next) => {
    if(req.user.type != 'tech') return res.status(400).json({
        error: {
            message: "You can't do this action"
        }
    })
    next()
}

export default techMiddleware;