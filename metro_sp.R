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


data_ok = ymd_hms(glue("{dmy(metro_data[[1]][1])} {hm(metro_data[[1]][2])}"))


# Definindo as linhas do metro --------------------------------------------


# Definindo o data frame --------------------------------------------------


# Destaque da linha amarela ------------------------------------------------



 df_final = tibble(
     linha=  metro_html %>%
         rvest::html_nodes('h2') %>%
         rvest::html_text() ,
     status = metro_html %>%
         rvest::html_nodes('span.status') %>%
         rvest::html_text() %>%  
         str_remove_all('Operação') %>% 
         str_remove("\\p{WHITE_SPACE}") %>% 
         str_to_lower(),
     datetime   = data_ok
 )



# Pegando informacoes das linhas restante ---------------------------------


info = metro_html %>%
  rvest::html_nodes('div.info') %>%
        html_text()


linha = metro_html %>%
  html_nodes('div.linhas ul li div.info span.title')%>%
        html_text()

status = metro_html %>%
  html_nodes('div.linhas ul li div.info span')%>%
        html_text()



status = status[!(status %in% linha)] 

df_linha = tibble(
  linha =  linha,
  status = status,
  datetime = data_ok
)

conn =  tryCatch({
        dbConnect(RMySQL::MySQL(), 
                  db = 'nome do banco', 
                  user = 'usuario', 
                  password = 'senha', 
                  host = 'endpoint', 
                  port = 3306)
        },
        error = function(e){
                cat(e)
                'ERROR'
        })


if(conn =! 'ERROR'){
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
                dados = rbind(dados,df_linha)
                write.csv2(dados, file = 'metro_data.csv', row.names = FALSE)
        }else{
                message('Criando o arquivo de dados!')
                write.csv2(df_linha, file = 'metro_data.csv', row.names = FALSE)
        }
}
message(glue('{Sys.time()} - Done!! (Metro SP - Viaquatro)'))
