import json

with open("rbi_page_after_click.html", "r") as f:
    html = f.read()

import re
matches = re.findall(r'get-bank-holidays.*?"(.*?)"', html)
print(matches)
