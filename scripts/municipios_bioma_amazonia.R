# <<<<<<<<<<<<>>>>>>>>>>>><<<<<<<<<<<<>>>>>>>>>>>><<<<<<<<<<<<>>>>>>>>>>>>
#
# Project: MS
#
# Script purpose: tentativa de listagem dos municípios no bioma amazônia
# 
# Autor: Luiz Eduardo Medeiros da Rocha
#
# Date: 2025-05-19
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
 install.load::install_load("tidyverse") 
 
 
 
 unzip("data/municipalities_amazon_biome.zip", exdir = "data/shp")
 
 municipios <- sf::st_read("data/shp/municipalities_amazon_biome.shp")
 
 municipios <- municipios[,-1]
 
 mun_bioamazonia <- 
   municipios %>%
   tibble() %>%
   select(nome, geocodigo) %>%
   rename(id_municipio = geocodigo)
 
 save(mun_bioamazonia, file = "data/rdata/br_municipalities_bioma_amazonia.RData")