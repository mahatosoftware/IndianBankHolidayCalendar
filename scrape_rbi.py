import urllib.request
from bs4 import BeautifulSoup
url = "https://website.rbi.org.in/web/rbi/bank-holidays"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as response:
        html = response.read()
        soup = BeautifulSoup(html, 'html.parser')
        years = soup.find_all('option')
        for y in years:
            print(y.text)
except Exception as e:
    print(e)
