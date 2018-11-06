require(dplyr)
require(rvest)
library(httr)
library(xml2)
library(stringr)

# URL de requisicao -------------------------------------------------------


url_base = 'http://www.viaquatro.com.br'


# Requisicao  -------------------------------------------------------------

metro_html <- url_base %>% 
  httr::GET() %>% 
  httr::content('text', encoding = 'latin1') %>% 
  xml2::read_html() %>% 
  rvest::html_nodes('section.operacao')


# Requisicao data ---------------------------------------------------------

metro_data = metro_html %>% 
  rvest::html_nodes('time') %>% 
  rvest::html_text() %>% 
  stringr::str_split(pattern = ' ')

# Ajeitando formato data  -------------------------------------------------



metro_data = c(metro_data[[1]][1],metro_data[[1]][2])
metro_data[1] = as.character(as.Date(metro_data[1],format = '%d/%m/%Y'))


# Definindo as linhas do metro --------------------------------------------


# Definindo o data frame --------------------------------------------------


# Destaque da linha amarela ------------------------------------------------



df_final = tibble(
  linha=  metro_html %>% 
    rvest::html_nodes('h2') %>% 
    rvest::html_text() ,
  status = metro_html %>% 
    rvest::html_nodes('span.status') %>% 
    rvest::html_text(),
  data   = metro_data[1],
  time   = metro_data[2]
)


# Pegando informacoes das linhas restante ---------------------------------


info = metro_html %>% 
  rvest::html_nodes('div.info') 


linha = metro_html %>% 
  html_nodes('div.linhas ul li div.info span.title') 

status = metro_html %>% 
  html_nodes('div.linhas ul li div.info span') 
  


status = status[!(status %in% linha)] %>% 
  html_text()

linha_df = tibble(
  linha =  metro_html %>% 
    html_nodes('div.linhas ul li div.info span.title') %>% 
    html_text(),
  status = status,
  data   = rep(metro_data[1],12),
  time   = rep(metro_data[2],12)
)



# Agregando tudo ----------------------------------------------------------


df_final = rbind(df_final,linha_df)
View(df_final)
