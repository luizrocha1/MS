# <<<<<<<<<<<<>>>>>>>>>>>><<<<<<<<<<<<>>>>>>>>>>>><<<<<<<<<<<<>>>>>>>>>>>>
#
# Project: MS
#
# Script purpose: collect and adjust BSTS data
# 
# Autor: Luiz Eduardo Medeiros da Rocha
#
# Date: 2025-05-26
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
 install.load::install_load("tidyverse", "fredr", "readxl", "seasonal") 
 
 
 # Fred data ------
 
 soja_ipca <- 
   read_excel("data/oleo_sojabr_ipca.xlsx", 
            col_types = c("date", "numeric")) %>% 
   mutate(date = ymd(date)) %>%
   rename(soja_ipca = `Variável - IPCA dessazonalizado - Variação mensal (%) - Óleo de soja`)
   
 # Fred data ------
 
 fredr_set_key('0cc0d6006e07a9b33b84ff6b3908953f')
 
 
 soja_grão <- 
   fredr(
     series_id = "PSOYBUSDM",
     observation_start = as.Date("2010-01-01"),
     observation_end = as.Date("2020-03-01")) %>%
   rename(p_grão = value) %>%
   select(date, p_grão)
 
 soja_óleo <- 
   fredr(
     series_id = "PSOILUSDM",
     observation_start = as.Date("2010-01-01"),
     observation_end = as.Date("2020-03-01")) %>%
   rename(p_óleo = value) %>%
   select(date, p_óleo)
 
 soja_farelo <- 
   fredr(
     series_id = "PSMEAUSDM",
     observation_start = as.Date("2010-01-01"),
     observation_end = as.Date("2020-03-01")) %>%
   rename(p_farelo = value) %>%
   select(date, p_farelo)

 # RNB data ------
 
 RNDBF <- 
   read_delim("data/csv/STI-20250526152636937.csv", 
                     delim = ";", escape_double = FALSE, col_types = cols(`29027 - Households gross disposable national income (deflated by IPCA, seasonally adjusted, 3-months moving average) - R$ (million)` = col_number()), 
                     trim_ws = TRUE) %>%
   slice(-266) %>%
   rename(RNB = `29027 - Households gross disposable national income (deflated by IPCA, seasonally adjusted, 3-months moving average) - R$ (million)`) %>%
   mutate(date = seq(as.Date("2003-03-01"), 
                     as.Date("2025-03-01"), by = "months")) %>%
   select(date, RNB)
 
 # Fertilizer index data ------
 
 fertilizantes <-
   read_excel("data/fertilizantes.xlsx", 
                             col_types = c("date", "numeric")) %>%
   mutate(date = ymd(date)) %>%
   rename(fert_index = `Fertilizers index`)

 
 # ABIOVE data ------
 
  biodiesel <- 
    read_excel("data/biodiesel.xlsx", 
                          col_types = c("date", "numeric")) %>%
    mutate(date = ymd(date))
  
  # IPCA data ------
    
  IPCA_alimentos <-
    read_csv("data/csv/ipeadata[26-05-2025-03-45].csv") %>%
    filter(Data >=2010 & Data <=2020.03) %>%
    rename(ipca_alimentos = `IPCA - alimentos e bebidas - taxa de variação - (% a.m.) - Instituto Brasileiro de Geografia e Estatística- Sistema Nacional de Índices de Preços ao Consumidor (IBGE/SNIPC) - PRECOS12_IPCAAB12`) %>%
    mutate(date = seq(as.Date("2010-01-01"), 
                      as.Date("2020-03-01"), by = "months")) %>%
    select(date, ipca_alimentos)
    
  IPCA_livre <- 
    read_csv("data/csv/ipeadata[26-05-2025-03-44].csv") %>%
    filter(Data >=2010 & Data <=2020.03) %>%
    rename(ipca_livre = `IPCA - preços livres - taxa de variação - (% a.m.) - Banco Central do Brasil- Boletim- Seção Atividade Econômica (Bacen / Boletim / Ativ. Ec.) - BM12_IPCAPL12`) %>%
    mutate(date = seq(as.Date("2010-01-01"), 
                      as.Date("2020-03-01"), by = "months")) %>%
    select(date, ipca_livre) 
  
  # Merging data ------
  
  cambio <- STI_20250527183135520$`3698 - Exchange rate - Free - United States dollar (sale) - period average - 3698 - c.m.u./US$`[1:123]
  
  df_BSTS <- 
    left_join(soja_ipca, soja_grão) %>%
    left_join(., soja_óleo) %>%
    left_join(., soja_farelo) %>%
    left_join(., RNDBF) %>%
    left_join(., biodiesel) %>%
    left_join(., IPCA_alimentos) %>%
    left_join(., IPCA_livre) %>%
    left_join(., fertilizantes) %>%
    mutate(
      across(
        starts_with("p_"),
        ~ .x * cambio
      )
    )
    
  # Seasonal Adjustment -----
  
  df_adjs <-
    df_BSTS %>%
    pivot_longer(
      cols = -date,
      names_to = "série",
      values_to = "values") %>%
    group_by(série) %>%
    nest() %>%
    mutate(
      ts_format = map(data, ~ ts(.x$values, 
                                 start = c(year(min(.x$date)), month(min(.x$date))), frequency = 12)),
      model = map(ts_format, ~ seas(.x)),
      adjs = map(model, ~ final(.x))) %>%
    unnest(data) %>%
    group_by(série) %>%
    mutate(
      adjs = rep(adjs[[1]])) %>%
    select(date, série, values, adjs)
    
  # ------
  
    df_adjs  %>% # Plot orginal and adjusted series
    pivot_longer(cols = c(values, adjs), names_to = "tipo", values_to = "valor_plot") %>%
    ggplot(aes(x = date, y = valor_plot, color = tipo)) +
    geom_line() +
    facet_wrap(~série, scales = "free_y") +
    theme_minimal() +
    labs(title = "Séries Originais vs Dessazonalizadas", x = "Data", y = "Valor")
  
  # Final data frame ------
    
    df_BSTS_out <- 
      df_adjs %>%
      select(date, série, adjs) %>%
      pivot_wider(
        names_from = série,
        values_from = adjs) %>%
      mutate(
        across(
          soja_ipca:fert_index,
          ~ (.x/.x[1]) * 100))
  
  # ------
  
    df_BSTS_out %>% # Plot indexed series
      pivot_longer(cols = !date, names_to = "tipo", values_to = "valor_plot") %>%
      ggplot(aes(x = date, y = valor_plot, color = tipo)) +
      geom_line() +
      facet_wrap(~tipo, scales = "free_y") +
      theme_minimal() +
      labs(title = "Séries", x = "Data", y = "Valor")
  
  
  # Saving ------
  
  write.csv(df_BSTS_out, file = "data/csv/dados_BSTS.csv")      
  
  
  
  
  