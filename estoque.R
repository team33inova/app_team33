# restart
rm(list =  ls())

#librarys
#install.packages("chron")
#install.packages("dplyr")
library(chron)
library(dplyr)

#preparando o estoque
estoque <- tbl(DBI::dbConnect(RSQLite::SQLite(), "inova_dm.sdb"), 
               sql("SELECT * FROM VAR_PDT_TOT")) %>%  dplyr::as_tibble()

estoque$data <- as.Date(chron::chron(dates=paste(01,"/",
                                                 substr(estoque$anomes,5,6),
                                                 "/",
                                                 substr(estoque$anomes,1,4)),
                                                 format="d/m/y"))

colnames(estoque)[1] <- "contagem"

write.csv(estoque, "estoque.csv")

DBI::dbDisconnect(DBI::dbConnect(RSQLite::SQLite(), "inova_dm.sdb"))
