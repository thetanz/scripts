import json
import argparse
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

parser = argparse.ArgumentParser(description='bulk url fetcher')
parser.add_argument('-f','--file', help="line delimited file of url's to download", required=True)
args = vars(parser.parse_args())

with open(args['file']) as temp_file:
  url_list = [line.rstrip('\n') for line in temp_file]

def download_file(url):
    html = requests.get(url, stream=True)
    return html

processes = []
with ThreadPoolExecutor(max_workers=50) as executor:
    for url in url_list:
        processes.append(executor.submit(download_file, url))

findings_obj = []

for task in as_completed(processes):
    if task.result().status_code != 409:
        findings = {}
        findings['url'] = task.result().url
        findings['response_text'] = task.result().text
        findings['response_status'] = task.result().status_code
        findings_obj.append(findings)

if findings_obj != []:
    print(json.dumps(findings_obj))
