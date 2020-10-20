#instalando e carregando os pacotes
#install.packages("ANN2")
library(ANN2)

#conexao
db_inova_dm <- dbConnect(RSQLite::SQLite(), 'inova_dm.sdb')

#Prepara modelo
dat <-  dbGetQuery(db_inova_dm, "SELECT * FROM BASE_MODELO")

colnames(dat)[27] = 'maxCodPai'

verifica <-  with(dat, !is.na(tmp_julg) & !is.na(classeProcessual) &
                    !is.na(codigoOrgao) & !is.na(grau) & !is.na(dscSistema) &
                    !is.na(procEl) & !is.na(tipo) & !is.na(esfera) &
                    !is.na(maxCodPai))

dat <-  dat[verifica,]
rm(verifica)
dat <-  subset(dat, tmp_julg > 0)

dat <-  transform(dat, classeProcessual = as.factor(classeProcessual),
                  codigoOrgao = as.factor(codigoOrgao),
                  grau = as.factor(grau),
                  dscSistema = as.factor(dscSistema),
                  procEl = as.factor(procEl),
                  tipo = as.factor(tipo),
                  esfera = as.factor(esfera),
                  maxCodPai = as.factor(maxCodPai))

dat <-  subset(dat, select = c('tmp_julg', 'classeProcessual', 'codigoOrgao',
                               'grau', 'dscSistema', 'procEl', 'tipo',
                               'esfera', 'maxCodPai'))


#preparacao dos dados para a rede:
for(i in 2:ncol(dat)) dat[,i] <-  as.factor(dat[,i])
for(i in 1:ncol(dat)) dat[,i] <-  as.numeric(dat[,i])

#train neuralnet:
modNN <-  neuralnetwork(X = dat[,-1],
                      y = dat[,1],
                      hidden.layers = c(5, 2),
                      optim.type = 'adam',
                      learn.rates = 0.01,
                      regression = T,
                      loss.type = 'squared',
                      activ.functions = 'relu',
                      verbose = T)

write_ANN(modNN, 'nn.ann')
