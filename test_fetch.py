import asyncio
import json
from playwright.async_api import async_playwright

async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(viewport={'width':1920, 'height':1080})
        page = await context.new_page()

        async def on_response(response):
            if "get-bank-holidays" in response.url:
                try:
                    text = await response.text()
                    print("API RESPONSE (first 500 chars):", text[:500])
                    data = json.loads(text)
                    print(f"Number of items in response: {len(data)}")
                except Exception as e:
                    print("Error parsing JSON:", e)

        page.on("response", on_response)

        print("Navigating to RBI...", flush=True)
        await page.goto('https://website.rbi.org.in/web/rbi/bank-holidays', wait_until='networkidle')
        await page.wait_for_timeout(2000)

        # Force fetch and log
        await page.evaluate("""async () => {
             let token = Liferay.authToken;
             let url = 'https://website.rbi.org.in/o/rbi/bank-holidays/get-bank-holidays?languageCode=en&p_auth=' + token;
             let formData = new FormData();
             formData.append('_com_liferay_rbi_bank_holiday_web_RbiBankHolidayWebPortlet_year', '2026');
             formData.append('_com_liferay_rbi_bank_holiday_web_RbiBankHolidayWebPortlet_month', 'all');
             formData.append('_com_liferay_rbi_bank_holiday_web_RbiBankHolidayWebPortlet_state', 'all');
             formData.append('_com_liferay_rbi_bank_holiday_web_RbiBankHolidayWebPortlet_legend', 'all');
             
             await fetch(url, { method: 'POST', body: formData });
        }""")
        
        await page.wait_for_timeout(2000)
        await browser.close()

if __name__ == '__main__':
    asyncio.run(run())
