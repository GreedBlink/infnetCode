# -*- coding: utf-8 -*-
"""
Created on Fri Sep 21 15:47:19 2018

@author: jonatha.costa
"""

import requests
from bs4 import BeautifulSoup
import gspread
from oauth2client.service_account import ServiceAccountCredentials


scope = ['https://spreadsheets.google.com/feeds','https://www.googleapis.com/auth/drive']
creds = ServiceAccountCredentials.from_json_keyfile_name(
           'client_secret.json',
           scope)

client = gspread.authorize(creds)

SPREADSHEET_ID = '1DSV7oVmloL47khdk-6QomHKPIuv8484l'

data_sheet = client.open_by_key(SPREADSHEET_ID).worksheet("data")



vq_home_sp_request = requests.get(url = 'http://www.viaquatro.com.br')
vq_home_sp_content = vq_home_sp_request.text
soup_sp = BeautifulSoup(vq_home_sp_content, 'html.parser')



operation_column_sp = soup_sp.find(class_="operacao")

lines_metro = ['azul','verde','vermelha','amarela', 'lilás', 'prata']
lines_cptm  = ['rubi', 'diamante', 'esmeralda', 'turquesa', 'coral', 'safira', 'jade']

all_lines = lines_metro + lines_cptm

extracted_status = {line:'' for line in all_lines}



status_amarela = operation_column_sp.find(class_="status").text
extracted_status['amarela'] = status_amarela
lines_containers = operation_column_sp.find_all(class_ = "linhas")
for container in lines_containers:
       line_info_divs = container.find_all(class_ = "info")
       for div in line_info_divs:
           line_title  = ''
           line_status = ''
           spans = div.find_all("span")
           line_title = spans[0].text.lower()
           line_status = spans[1].text.lower()
           extracted_status[line_title] = line_status
           
           
           
time_data = soup_sp.find('time').text

for line in all_lines:
    data_sheet.append_row([time_data, line, extracted_status[line]])

