import puppeteer from "puppeteer";
import * as cheerio from "cheerio";

export async function scrapePolymarket() {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    try {
        await page.goto('https://polymarket.com', { waitUntil: 'networkidle0' });

        // 동적 콘텐츠가 로드될 때까지 기다립니다
        await page.waitForSelector('.c-dhzjXW.c-dhzjXW-idNOCmT-css', { timeout: 10000 });

        const html = await page.content();
        const $ = cheerio.load(html);

        const items = [];

        $('.c-dhzjXW.c-dhzjXW-idNOCmT-css').each((index, element) => {
            const item = $(element);
            const title = item.find('.c-dqzIym-ihMZKul-css').text().trim();
            const icon = 'https://polymarket.com/' + item.find('.c-PJLV-igTCeuK-css img').attr('src');
            const chance = item.find('.c-dqzIym-igjdJOs-css').text().trim();
            const volume = item.find('.c-PJLV-ibGjNZs-css').text().trim();
            const comments = item.find('.c-PJLV-ijqjYnj-css').text().trim();

            if (title) {
                items.push({ title, icon, chance, volume, comments });
            }
        });

        return items;
    } catch (error) {
        console.error('Scraping failed:', error);
        return [];
    } finally {
        await browser.close();
    }
}

scrapePolymarket().then(items => {
    console.log(JSON.stringify(items, null, 2));
}).catch(error => {
    console.error('Error:', error);
});
