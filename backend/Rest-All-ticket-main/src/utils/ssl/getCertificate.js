import fs from 'fs';

const getCertificate = () => {
    try {
        return {
            key: fs.readFileSync('./src/config/ssl/restall-it-privateKey.key', 'utf8'),
            cert: fs.readFileSync('./src/config/ssl/restall-it.cert', 'utf8'),
        }
    } catch (error) {
        console.error('Could not find SSL Certificate files, https is disabled. ' + error);
        return null;
    }
};

export default getCertificate;
