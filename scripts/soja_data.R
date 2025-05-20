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
      filter(produto == "Soja (em grão)", area_plantada > 5000) %>%
      select(ano, id_municipio, valor_producao, quantidade_produzida) %>% 
      mutate(p_medio = log(valor_producao / quantidade_produzida)) 
      
        
    mun_prio_aux <- 
      municipios_formatados %>% 
      rename(nome = NOME) %>%
      select(nome, entrada, saida) 
    
      mun_prio <- 
        left_join(expand_grid(nome = mun_prio_aux$nome, ano = seq(2008,2022, 1)), mun_prio_aux) %>% 
        mutate(
          across(
            ends_with("a"),
            as.double),
          Prio = case_when(
            ano < entrada ~ 0,
            ano >= saida ~ 0,
            TRUE ~ 1)) %>% 
        select(nome, ano, Prio)
    
    mun_bioma <- 
      Bioma_Predominante_por_Municipio_2024 %>%
      rename(bioma = `Bioma predominante`, id_municipio = Geocódigo) %>%
      select(id_municipio, bioma) %>%
      mutate(id_municipio = as.character(id_municipio)) 
    
    left_join(soja_data, mun_bioma) %>%
      filter(bioma == "Amazônia") %>% 
      group_by(id_municipio)
    
    mun_aux <- 
      left_join(mun_bioamazonia, mun_prio) %>% 
      mutate(
        Prio = if_else(is.na(Prio), 0, Prio),
        amazonia = 1) %>%
      select(-nome)
    
    left_join(mun_bioamazonia, soja_data) %>%
      filter(!is.na(ano)) %>%
      group_by(id_municipio)
    
    df_out<-
      left_join(soja_data, mun_aux) %>% 
      mutate(
        Prio = if_else(is.na(Prio), 0, Prio),
        amazonia = if_else(is.na(amazonia), 0, amazonia)) 
    
    save(df_out, file = "data/rdata/df_parecer_0.RData")      

 