const checkIfAuth = (req, res, next) => {
    if (!req.isAuthenticated()) {return res.status(400).json({"message": "Forbidden: not logged in"})}
    return next()
}

module.exports = checkIfAuth;