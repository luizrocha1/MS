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
# E-mail: luiz.rocha9900@gmail.com
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
  
  # Treating data -----
 
    soja_data <- 
      df %>%
      filter(ano > 2013 & ano < 2021, produto == "Soja (em grão)", area_plantada > 5000) %>%
      arrange(id_municipio)
      select(ano, id_municipio, valor_producao, quantidade_produzida) %>% 
      mutate(p_medio = log(valor_producao / quantidade_produzida)) 
        
    mun_prio <- 
      municipios_formatados %>% 
      rename(nome = NOME) %>%
      filter(is.na(saida)) %>%
      filter(entrada < 2017) %>%
      select(nome) %>%
      mutate(Prio = 1)
    
    mun_aux <- 
      left_join(mun_bioamazonia, mun_prio) %>% 
      mutate(
        Prio = if_else(is.na(Prio), 0, Prio),
        amazonia = 1) %>%
      select(-nome)
    
    df_out<-
      left_join(soja_data, mun_aux) %>% 
      mutate(
        Prio = if_else(is.na(Prio), 0, Prio),
        amazonia = if_else(is.na(amazonia), 0, amazonia)) 
    
    save(df_out, file = "data/rdata/df_parecer_0.RData")      

 