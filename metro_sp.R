options(
        stringsAsfactors = F,
        repos = 'https://cran-fiocruz.br/'   
)


library(dplyr,quietly = TRUE)
library(rvest, quietly = TRUE)
library(httr, quietly = TRUE)
library(xml2, quietly = TRUE)
library(stringr, quietly = TRUE)
library(glue, quietly = TRUE)
library(DBI, quietly = TRUE)
library(RMySQL, quietly = TRUE)


#Alternativa: utilizando o pacman
if(require(pacman)){
      pacman::p_load(dplyr,rvest,httr,xml2,stringr,glue,DBI,RMySQL) 
}else{
      install.packages('pacman') 
      pacman::p_load(dplyr,rvest,httr,xml2,stringr,glue,DBI,RMySQL) 
}

# URL de requisicao -------------------------------------------------------
#setwd('~')

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

conn = dbConnect(MySQL(), db = 'nome do banco', user = 'usuario', password = 'senha', host = 'endpoint', port = 3306)

if(!is.null(conn)){
        message('Conexao estabelicda!')
        queries = glue("insert into metro.metroSP(linha,status,data,hora) value('{linha_df$linha}','{linha_df$status}','{linha_df$data}','{linha_df$time}')")
        for(i in 1:length(queries)){try(dbSendQuery(conn = conn, statement = queries[i]),silent = TRUE)}
        message('Dados inseridos com sucesso!')
        dbDisconnect(conn)
}else{
        message('Conexao nao estabelecida. Plano de contigencia: arquivo cvs\n')
# Agregando tudo ----------------------------------------------------------
        if(file.exists('metro_data.csv')){
                message('Atualiazando os dados!')
                dados = read.csv2('metro_data.csv')
                dados = rbind(dados,linha_df)
                write.csv2(dados, file = 'metro_data.csv', row.names = FALSE)
        }else{
                message('Criando o arquivo de dados!')
                write.csv2(linha_df, file = 'metro_data.csv', row.names = FALSE)
        }
}
message(glue('{Sys.time()} - Done!! (Metro SP - Viaquatro)'))
