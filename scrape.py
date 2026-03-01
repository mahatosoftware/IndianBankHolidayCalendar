import asyncio
import json
import datetime
from playwright.async_api import async_playwright
import calendar

TARGET_YEAR = "2026"
TARGET_MONTHS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  # Liferay UI Month Dropdown Options: January is value="1", ..., December is "12"

TARGET_FILE_PATH = f"/Users/debasish/Developer/MobileApps/IndianBankHolidayCalendar/assets/{TARGET_YEAR}.json"

async def run():
    all_holidays = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(viewport={'width':1920, 'height':1080})
        page = await context.new_page()

        print("Navigating to RBI...", flush=True)
        await page.goto('https://website.rbi.org.in/web/rbi/bank-holidays', wait_until='networkidle')
        await page.wait_for_timeout(3000)

        # Handle cookies
        try:
            await page.evaluate("""() => {
                let b = document.getElementById('allow-all-cookies');
                if(b) b.click();
            }""")
        except:
            pass
        
        for m in TARGET_MONTHS:
            print(f"Extracting for Year: {TARGET_YEAR}, Month: {m}", flush=True)
            
            # Select target year
            await page.evaluate(f"""() => {{
                let options = document.querySelectorAll('li.option');
                options.forEach(opt => {{
                    if (opt.getAttribute('data-value') === '{TARGET_YEAR}') {{ opt.click(); }}
                }});
            }}""")
            await page.wait_for_timeout(200)

            # Select Month (1-12)
            await page.evaluate(f"""() => {{
                let options = document.querySelectorAll('li.option');
                options.forEach(opt => {{
                    if (opt.getAttribute('data-value') === '{m}' && !opt.closest('ul.listState') && !opt.closest('ul.listLegend') && parseInt(opt.getAttribute('data-value')) <= 12) {{
                        opt.click();
                    }}
                }});
            }}""")
            await page.wait_for_timeout(200)

            # Set Legend to 'All'
            await page.evaluate(f"""() => {{
                let options = document.querySelectorAll('ul.listLegend li.option');
                options.forEach(opt => {{
                    if (opt.getAttribute('data-value') === 'all') {{ opt.click(); }}
                }});
            }}""")
            await page.wait_for_timeout(200)

            # Set State to 'All States'
            await page.evaluate(f"""() => {{
                let options = document.querySelectorAll('ul.listState li.option');
                options.forEach(opt => {{
                    if (opt.getAttribute('data-value') === 'all') {{ opt.click(); }}
                }});
            }}""")
            await page.wait_for_timeout(200)

            # Click Apply
            await page.evaluate("""() => {
               let btns = document.querySelectorAll('.apply-filter, .overlay-apply-filter');
               for(let b of btns) {
                   b.removeAttribute('disabled');
                   b.classList.remove('disabled');
                   b.click();
               }
            }""")
            
            print("Waiting for portlet to reload HTML...", flush=True)
            await page.wait_for_timeout(5000)

            # Click VIEW TABLE
            try:
                await page.evaluate("""() => {
                    let btn = document.querySelector('.view-table-text');
                    if(btn && btn.style.display !== 'none') {
                        btn.click();
                    }
                }""")
                await page.wait_for_timeout(1500)
            except:
                pass

            # Extract from the HTML Table!
            extract_js = r"""
            () => {
                let table = document.querySelector('.table-parent table') || document.querySelector('.tablebg');
                if (!table) return {error: "No table found on page."};
                
                let data = [];
                let rows = Array.from(table.querySelectorAll('tr'));
                if (rows.length < 2) return {error: "Table has no data rows."};
                
                let headers = [];
                let headerRow = rows[0].querySelectorAll('th, td');
                if (headerRow.length === 0) return {error: "No headers found."};
                
                for(let th of headerRow) {
                    let hText = th.innerText.trim();
                    // Clean up newline in headers like 'Andhra \n Pradesh'
                    hText = hText.replace(/\\n/g, ' ').replace(/\\s+/g, ' ');
                    headers.push(hText);
                }
                
                for(let i = 1; i < rows.length; i++) {
                    let cells = rows[i].querySelectorAll('td, th');
                    if (cells.length === 0) continue;
                    
                    let rowHeader = cells[0].innerText.trim();
                    if (!rowHeader) continue;
                    
                    for (let j = 1; j < cells.length; j++) {
                        let cellText = cells[j].innerText.trim();
                        if (cellText && cellText.length > 0 && cellText !== '-') {
                            data.push({
                                region: rowHeader,
                                date_str: headers[j],
                                holiday_name: cellText
                            });
                        }
                    }
                }
                return {data: data};
            }
            """
            result = await page.evaluate(extract_js)
            if "error" in result:
                print(f"Error parsing table for month {m}:", result["error"])
                html = await page.content()
                with open(f"error_month_{m}.html", "w") as f:
                    f.write(html)
            else:
                raw_data = result.get("data", [])
                all_holidays.extend(raw_data)
                print(f"Extracted {len(raw_data)} holidays for month {m}")

        await browser.close()
        
        # Post-process
        if len(all_holidays) > 0:
            print(f"Total extracted globally: {len(all_holidays)}")
            unique_holidays = []
            seen = set()
            
            # Helper to generate general weekends (2nd/4th Saturdays and all Sundays)
            year_int = int(TARGET_YEAR)
            # Find all unique states/regions
            all_regions = set()
            for h in all_holidays:
                h_reg = h['region']
                s_name = h_reg.split('(')[0].strip()
                if '(' in h_reg and ')' in h_reg:
                    rgs = [r.strip() for r in h_reg.split('(')[1].split(')')[0].split(',')]
                    for r in rgs:
                        all_regions.add((s_name, r))
                else:
                    all_regions.add((s_name, s_name))
            
            weekend_holidays = []
            for month in range(1, 13):
                cal = calendar.monthcalendar(year_int, month)
                # cal is a list of weeks, where each week is a list of 7 days (Monday is 0, Sunday is 6)
                
                saturdays = [week[5] for week in cal if week[5] != 0]
                sundays = [week[6] for week in cal if week[6] != 0]
                
                for r_tuple in all_regions:
                    s_name, r_name = r_tuple
                    
                    # Add all Sundays
                    for d in sundays:
                        dt_str = f"{year_int}-{month:02d}-{d:02d}"
                        weekend_holidays.append({
                            "state": s_name,
                            "region": r_name,
                            "date": dt_str,
                            "holiday_name": "Sunday"
                        })
                    
                    # Add 2nd and 4th Saturdays
                    if len(saturdays) >= 2:
                        dt_str = f"{year_int}-{month:02d}-{saturdays[1]:02d}"
                        weekend_holidays.append({
                            "state": s_name,
                            "region": r_name,
                            "date": dt_str,
                            "holiday_name": "Second Saturday"
                        })
                    if len(saturdays) >= 4:
                        dt_str = f"{year_int}-{month:02d}-{saturdays[3]:02d}"
                        weekend_holidays.append({
                            "state": s_name,
                            "region": r_name,
                            "date": dt_str,
                            "holiday_name": "Fourth Saturday"
                        })
            
            for h in weekend_holidays:
                k = f"{h['state']}_{h['region']}_{h['date']}_{h['holiday_name']}"
                if k not in seen:
                    seen.add(k)
                    unique_holidays.append(h)
                    
            for h in all_holidays:
                # Add year
                raw_date = h['date_str'] + f" {TARGET_YEAR}"
                if str(TARGET_YEAR) in h['date_str']:
                    raw_date = h['date_str']
                
                # Parse
                date_obj = None
                formats = ['%d %b %Y', '%b %d, %Y', '%b %d %Y', '%d %b', '%b %d', '%Y-%m-%d', '%d/%m/%Y', '%d-%b-%Y']
                for fmt in formats:
                    try:
                        date_obj = datetime.datetime.strptime(raw_date, fmt)
                        if date_obj.year == 1900: 
                            date_obj = date_obj.replace(year=int(TARGET_YEAR))
                        break
                    except:
                        pass
                
                final_date_str = raw_date
                if date_obj:
                    final_date_str = date_obj.strftime('%Y-%m-%d')
                    
                holiday_name = h['holiday_name'].replace('\\n', ' ')
                
                raw_region_str = h['region']
                state_name = raw_region_str.split('(')[0].strip()
                regions = []
                if '(' in raw_region_str and ')' in raw_region_str:
                    rg_str = raw_region_str.split('(')[1].split(')')[0]
                    regions = [r.strip() for r in rg_str.split(',')]
                else:
                    regions = [state_name]
                
                for r in regions:
                    final_h = {
                        "state": state_name,
                        "region": r,
                        "date": final_date_str,
                        "holiday_name": holiday_name
                    }
                    
                    k = f"{state_name}_{r}_{final_date_str}_{holiday_name}"
                    if k not in seen:
                        seen.add(k)
                        unique_holidays.append(final_h)
            
            unique_holidays.sort(key=lambda x: x['date'])
            output_data = {
                "year": int(TARGET_YEAR),
                "total_records": len(unique_holidays),
                "data": unique_holidays
            }
            with open(TARGET_FILE_PATH, "w", encoding='utf-8') as f:
                json.dump(output_data, f, indent=2, ensure_ascii=False)
            print(f"Saved {len(unique_holidays)} holidays to {TARGET_FILE_PATH}")
        else:
            print("No holidays captured.")

if __name__ == '__main__':
    asyncio.run(run())
