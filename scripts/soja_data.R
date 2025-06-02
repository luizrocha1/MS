# <<<<<<<<<<<<>>>>>>>>>>>><<<<<<<<<<<<>>>>>>>>>>>><<<<<<<<<<<<>>>>>>>>>>>>
#
# Project: MS
#
# Script purpose: Collect and treat PAM data
# 
# Autor: Luiz Eduardo Medeiros da Rocha
#
# Date: 2025-05-18
#
# Copyright: 
#
# Repository: https://github.com/luizrocha1/MS.git
#
# E-mail: luiz.rocha9900@gmail.com / luizrocha99@usp.br
#
# <<<<<<<<<<<<>>>>>>>>>>>>
#
# Session
#
# Platform: Windows 10 x64 (build 26100)
#
# Version: R version 4.2.2 (2022-10-31 ucrt)
#
# Memory: 
#
# <<<<<<<<<<<<>>>>>>>>>>>>
#
# Notes:
#
# <<<<<<<<<<<<>>>>>>>>>>>>
 
 # Install and load packages ----
 
 if (!require(install.load)) install.packages(install.load)
 install.load::install_load("sf", "DBI", "tidyverse", "dplyr",
                            "bigrquery", "basedosdados","data.table", "sf") 
 
 # Path to json file ----
 
 bq_auth(path = "C:/Users/luizr/Documentos/resonant-tube-325021-393978457bc6.json")
 
 
 # Conecting with BigQuery ----
 
 con <- dbConnect(
   bigrquery::bigquery(),
   billing = "resonant-tube-325021",
   project = "basedosdados")
 
 # Defining project on Google Cloud ----
 
 basedosdados::set_billing_id("resonant-tube-325021")
 
 
 # Loading data from basedosdados ----
 
 query <- "SELECT * FROM `basedosdados.br_ibge_pam.lavoura_temporaria`"
 df <- basedosdados::read_sql(query)
 
 biomas <- 
   Bioma_Predominante_por_Municipio_2024 %>%
   rename(id_municipio = Geocódigo, bioma = `Bioma predominante`) %>%
   select(id_municipio, bioma) %>%
   mutate(id_municipio = as.character(id_municipio))
   
  # Treating data -----
 
    soja_data <- 
      df %>%
      filter(produto == "Soja (em grão)", !is.na(area_plantada)) %>%
      select(ano, id_municipio, valor_producao, quantidade_produzida, area_plantada) %>%
      left_join(., biomas) %>% 
      mutate(p_medio = valor_producao / quantidade_produzida,
             amazonia = case_when(
               bioma == "Amazônia" ~ 1,
               TRUE ~ 0)) 

 # Saving final data -----
    
      write.csv(soja_data, file = "data/csv/dados_PAM_soja.csv")      

 