export class customError extends Error {
    constructor(message){
        super(message)
        this.name = this.constructor.name
        Error.captureStackTrace(this, this.constructor)
    }
}

export class ResourceNotFound extends customError {
    constructor(resource, status) {
        super(`Resource ${resource} was not found.`);
        this.data = { resource, status };
    }
}

export class InternalError extends customError {
    constructor(resource, status = 500){
        super(`Server Internal Error`);
        this.data = { resource, status };
    }
}

export class ParamsMissing extends customError {
    constructor(param, status = 400) {
        super(`Parameter ${param} is missing.`);
        this.data = { param, status };
    }
}