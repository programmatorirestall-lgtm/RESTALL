import puppeteer from 'puppeteer';
import { PUPPETEER } from '../config/config.js';

const pup = {
    pdfFromHtmlCode: async (html, format) => {
        try{
            const browser = await puppeteer.connect({ browserWSEndpoint: `wss://chrome.browserless.io?token=${PUPPETEER.BROWSERLESS_TOKEN}`, });

            // Create a new page
            const page = await browser.newPage();

            // Open URL in current page
            await page.setContent(html, { waitUntil: ['domcontentloaded', 'load', 'networkidle2'] }); 

            // Downlaod the PDF
            const pdf = await page.pdf({
                path: 'result.pdf',
                margin: { top: '0px', right: '0px', bottom: '0px', left: '0px' },
                printBackground: true,
                format: format,
            });

            // Close the browser instance
            await browser.close();
            return pdf
        }catch(err){
            console.log(err)
            return err
        }
    }
}

export default pup