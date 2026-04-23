let notFoundMiddleware = (req, res) => {
    return res.status(404).send({
        error: 'Not found',
    });
};

export default notFoundMiddleware;