# restart
rm(list =  ls())

# librarys
#install.packages("RPostgreSQL")
#install.packages("RSQLite")
library(RPostgreSQL)
library(RSQLite)

#carregando driver
drv <- dbDriver("PostgreSQL")

#connect postgresql
db_con <- dbConnect(drv,
                    host   = "team33.ddns.net",
                    dbname = "team33",
                    user      = "team33",
                    password     = "team33",
                    port     = 5631)

#Criar Conexao com o banco DATAJUD SQLite3 e Criar database nova inovadataminig
db_inova_dm <- dbConnect(RSQLite::SQLite(), 'inova_dm.sdb')


#baixar tabelas dimensao no postgreSQL
#sgt classes
sgt_classe <- dbGetQuery(db_con, 'select * from sgt_classe')
sgt_assunto <- dbGetQuery(db_con, 'select * from sgt_assunto')
sgt_mov <- dbGetQuery(db_con, 'select * from sgt_mov')
serventias <- dbGetQuery(db_con, 'select * from serventias')
anomes <- dbGetQuery(db_con, 'select * from anomes')
tipo_assunto <- read.csv(file = 'tipo_assunto.csv', sep = ';', header = T, encoding = 'UTF-8')


#Testar tabela e gravar tabelas dimensao na base DATAJUD. apagar objeto R
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS sgt_classe')
dbWriteTable(db_inova_dm,"sgt_classe",sgt_classe)
rm(sgt_classe)

dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS sgt_assunto')
dbWriteTable(db_inova_dm,"sgt_assunto",sgt_assunto)
rm(sgt_assunto)

dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS sgt_mov')
dbWriteTable(db_inova_dm,"sgt_mov",sgt_mov)
rm(sgt_mov)

dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS serventias')
dbWriteTable(db_inova_dm,"serventias",serventias)
rm(serventias)

dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS anomes')
dbWriteTable(db_inova_dm,"anomes",anomes)
rm(anomes)

dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tipo_assunto')
dbWriteTable(db_inova_dm,"tipo_assunto",tipo_assunto)
rm(tipo_assunto)


#tmp dadosbasicos
tmp_df <-  dbGetQuery(db_con, 
                      "
                      select *
                      from dadosBasicos db
                      inner join sgt_classe
                      on db.classeProcessual = sgt_classe.cod_classe
                      inner join serventias
                      on db.codigoOrgao = serventias.cod_serventia
                      ")


# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_dadosBasicos')
dbWriteTable(db_inova_dm,"tmp_dadosBasicos",tmp_df)

#tmp movimentos
tmp_df <-  dbGetQuery(db_con, 
                      "
                      select *
                      from movimento mov
                      inner join sgt_mov sgt
                      on coalesce(mov.codigoNacional, mov.codigoPaiNacional) = sgt.cod_mov
                      where to_date(substr(dataHora,1,4) ||
                                    substr(dataHora,5,2) ||
                                    substr(dataHora,7,2), 'YYYYMMDD')
                            BETWEEN to_date('19800101','YYYYMMDD') AND to_date('20210101','YYYYMMDD')
                      ")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_movimento')
dbWriteTable(db_inova_dm,"tmp_movimento",tmp_df)

#tmp assunto
tmp_df <-  dbGetQuery(db_con, 
                      "
                      select *
                      from assunto ass
                      inner join sgt_assunto sgt
                      on coalesce(ass.codigoNacional, ass.codigoPaiNacional) = sgt.cod_assunto
                      ")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_assunto')
dbWriteTable(db_inova_dm,"tmp_assunto",tmp_df)

#tmp orgao julgador
tmp_df <-  dbGetQuery(db_con, 
                      "
                      select *
                      from orgaojulgador oj
                      inner join serventias
                      on oj.codigoOrgao = serventias.cod_serventia
                      ")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_orgaojulgador')
dbWriteTable(db_inova_dm,"tmp_orgaojulgador",tmp_df)


#join entre as tabelas para sincronizar os registros entre as tabelas
tmp_df <-  dbGetQuery(db_inova_dm, 
                      "
select distinct tmp_dadosBasicos.numero, 
                tmp_dadosBasicos.classeProcessual, 
                tmp_dadosBasicos.codigoOrgao,
                tmp_dadosBasicos.grau
from tmp_dadosBasicos

inner join tmp_assunto
on tmp_dadosBasicos.numero = tmp_assunto.numero
and tmp_dadosBasicos.classeProcessual = tmp_assunto.classeProcessual
and tmp_dadosBasicos.codigoOrgao = tmp_assunto.codigoOrgao
and tmp_dadosBasicos.grau = tmp_assunto.grau

inner join tmp_movimento
on tmp_dadosBasicos.numero = tmp_movimento.numero
and tmp_dadosBasicos.classeProcessual = tmp_movimento.classePRocessual
and tmp_dadosBasicos.codigoOrgao = tmp_movimento.codigoOrgao
and tmp_dadosBasicos.grau = tmp_movimento.grau

inner join tmp_orgaojulgador
on tmp_dadosBasicos.numero = tmp_orgaojulgador.numero
and tmp_dadosBasicos.classeProcessual = tmp_orgaojulgador.classeProcessual
and tmp_dadosBasicos.codigoOrgao = tmp_orgaojulgador.codigoOrgao
and tmp_dadosBasicos.grau = tmp_orgaojulgador.grau
;
")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_chave')
dbWriteTable(db_inova_dm,"tmp_chave",tmp_df)


#sincronia final
#tmp dadosbasicos
tmp_df <-  dbGetQuery(db_inova_dm, 
                      "
select db.*
from tmp_dadosBasicos db

inner join tmp_chave ch

on db.numero = ch.numero
and db.classeProcessual = ch.classePRocessual
and db.codigoOrgao = ch.codigoOrgao
and db.grau = ch.grau
;
")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS vl_dadosBasicos')
dbWriteTable(db_inova_dm,"vl_dadosBasicos",tmp_df)
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_dadosBasicos')


#tmp movimentos
tmp_df <-  dbGetQuery(db_inova_dm, 
                      "
select mov.*
from tmp_movimento mov

inner join tmp_chave ch

on mov.numero = ch.numero
and mov.classeProcessual = ch.classePRocessual
and mov.codigoOrgao = ch.codigoOrgao
and mov.grau = ch.grau
")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS vl_movimento')
dbWriteTable(db_inova_dm,"vl_movimento",tmp_df)
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_movimento')

#tmp assunto
tmp_df <-  dbGetQuery(db_inova_dm, 
                      "
select ass.*
from tmp_assunto ass

inner join tmp_chave ch

on ass.numero = ch.numero
and ass.classeProcessual = ch.classePRocessual
and ass.codigoOrgao = ch.codigoOrgao
and ass.grau = ch.grau
")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS vl_assunto')
dbWriteTable(db_inova_dm,"vl_assunto",tmp_df)
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_assunto')

#tmp orgao julgador
tmp_df <-  dbGetQuery(db_inova_dm, 
                      "
select oj.*
from tmp_orgaoJulgador oj

inner join tmp_chave ch

on oj.numero = ch.numero
and oj.classeProcessual = ch.classePRocessual
and oj.codigoOrgao = ch.codigoOrgao
and oj.grau =  ch.grau
")

# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS vl_orgaojulgador')
dbWriteTable(db_inova_dm,"vl_orgaojulgador",tmp_df)
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS tmp_orgaoJulgador')


#VAR Baixados
tmp_df <-  dbGetQuery(db_inova_dm, 
                      "
SELECT tmp.*, 
            min(tmp.dataHora) primeira_baixa
FROM 
(
select *
from vl_movimento mov
where IFNULL(mov.codigoNacional, mov.codigoPaiNacional) in ('22','246','488')
)tmp
GROUP BY tmp.numero, tmp.classeProcessual, tmp.codigoOrgao, tmp.grau
")
                      
                      # drop and write tb
                      dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_BX')
                      dbWriteTable(db_inova_dm,"VAR_BX",tmp_df)
                      
                      #VAR primeiro movimento
                      tmp_df <-  dbGetQuery(db_inova_dm, 
                                            "
select mov.*, 
           min(dataHora) primeiro_movimento
from vl_movimento mov
group by mov.numero, mov.classeProcessual, mov.codigoOrgao, mov.grau;
")
                      
                      # drop and write tb
                      dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_NV')
                      dbWriteTable(db_inova_dm,"VAR_NV",tmp_df)
                      
                      #VAR Julgamento
                      tmp_df <-  dbGetQuery(db_inova_dm, 
                                            "
SELECT tmp.*, 
min(tmp.dataHora) primeiro_julgamento
FROM 
(
  select *
    from vl_movimento mov
  where IFNULL(mov.codigoNacional, mov.codigoPaiNacional) in 
  ('385','11877','11876','198','871','12663','12662','12615','210','12032','443'
  ,'12475','444','445','12041','10965','442','214','451','452','453','450','242'
  ,'240','241','12433','12443','12442','12439','12440','12441','12438','12434',
  '12437','12436','12435','12326','12327','12328','12652','12654','12653',
  '12651','900','202','12660','12257','212','447','448','449','446','12258',
  '196','973','1043','1050','11411','12028','11879','12735','1042','1049',
  '1048','11878','1045','1046','11801','1047','1044','10964','466','12738',
  '12649','220','11409','11407','11408','12450','12453','12451','12452','12661',
  '12675','12676','12674','12667','12670','12672','12668','12669','12664',
  '12650','200','208','239','901','12321','12324','12322','12323','12331',
  '12329','12330','219','12665','11795','11403','11401','11402','221','11406',
  '11404','11405','471','237','972','238','12678','12696','12697','12695',
  '12698','12706','12707','12704','12705','12701','12702','12699','12700',
  '12691','12692','12690','12693','12682','12679','12680','12683','12685',
  '12688','455','12252','12253','12254','884')
)tmp
GROUP BY tmp.numero, tmp.classeProcessual, tmp.codigoOrgao, tmp.grau
")
                                            
                                            # drop and write tb
                                            dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_JULG')
                                            dbWriteTable(db_inova_dm,"VAR_JULG",tmp_df)
                                            
                                            #VAR Pendentes 1
                                            tmp_df <-  dbGetQuery(db_inova_dm, 
                                                                  "
SELECT *
FROM anomes

LEFT JOIN 
(
SELECT nv.*, bx.dt_baixa
FROM 
    (
    SELECT numero, classeProcessual, codigoOrgao, grau, primeiro_movimento as dt_novo
    FROM VAR_NV
    ) nv
    
LEFT JOIN
    
    (
    SELECT numero, classeProcessual, codigoOrgao, grau, primeira_baixa as dt_baixa
    FROM VAR_BX
    ) bx

on nv.numero = bx.numero
and nv.classeProcessual = bx.classeProcessual
and nv.codigoOrgao = bx.codigoOrgao
and nv.grau = bx.grau
) VAR_PDT
ON     (anomes.anomes >= substr(VAR_PDT.dt_novo, 1, 6) AND  anomes.anomes < substr(VAR_PDT.dt_baixa, 1, 6))
OR     (anomes.anomes >= substr(VAR_PDT.dt_novo, 1, 6) AND  VAR_PDT.dt_baixa is null)
;
")
                                                                  
                                                                  # drop and write tb
                                                                  dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_PDT')
                                                                  dbWriteTable(db_inova_dm,"VAR_PDT",tmp_df)
                                                                  
                                                                  #VAR Pendentes Totalizado
                                                                  tmp_df <-  dbGetQuery(db_inova_dm, 
                                                                                        "
select count(codigoOrgao), codigoOrgao, anomes
from VAR_PDT
group by codigoOrgao, anomes;
")
                                                                  
                                                                  # drop and write tb
                                                                  dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_PDT_TOT')
                                                                  dbWriteTable(db_inova_dm,"VAR_PDT_TOT",tmp_df)
                                                                  
                                                                  #VAR Tempos de Julgamento e Baixa
                                                                  tmp_df <-  dbGetQuery(db_inova_dm, 
                                                                                        "
SELECT nv.*, ju.primeiro_julgamento, bx.dt_baixa
FROM 
    (
    SELECT numero, classeProcessual, codigoOrgao, grau, primeiro_movimento as dt_novo
    FROM VAR_NV
    ) nv
    
LEFT JOIN
    
    (
    SELECT numero, classeProcessual, codigoOrgao, grau, primeira_baixa as dt_baixa
    FROM VAR_BX
    ) bx

on nv.numero = bx.numero
and nv.classeProcessual = bx.classeProcessual
and nv.codigoOrgao = bx.codigoOrgao
and nv.grau = bx.grau

LEFT JOIN VAR_JULG ju

ON nv.numero = ju.numero
and nv.classeProcessual = ju.classeProcessual
and nv.codigoOrgao = ju.codigoOrgao
and nv.grau = ju.grau
")
                                                                  
                                                                  #função para calcular diferença de tempo string AAAAMMDD
                                                                  dif_dt <- function(dt1, dt2){
                                                                    a <- as.numeric(substr(dt1, 1, 4))*365 + as.numeric(substr(dt1, 5, 6))*30 + as.numeric(substr(dt1, 7, 8))
                                                                    b <- as.numeric(substr(dt2, 1, 4))*365 + as.numeric(substr(dt2, 5, 6))*30 + as.numeric(substr(dt2, 7, 8))
                                                                    return(b-a)
                                                                  }
                                                                  
                                                                  #gravar novas colunas tempo
                                                                  tmp_df$tmp_julg <- dif_dt(tmp_df$dt_novo,tmp_df$primeiro_julgamento)
                                                                  tmp_df$tmp_bx <- dif_dt(tmp_df$dt_novo,tmp_df$dt_baixa)
                                                                  
                                                                  # drop and write tb
                                                                  dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_TEMP')
                                                                  dbWriteTable(db_inova_dm,"VAR_TEMP",tmp_df)
                                                                  
                                                                  #VAR Assunto Pai
                                                                  tmp_df <-  dbGetQuery(db_inova_dm, 
                                                                                        "
select ass.*, tp.assunto_pai
from vl_assunto ass

left join tipo_assunto tp

on ass.cod_assunto = tp.assunto
")
                                                                  
                                                                  # drop and write tb
                                                                  dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_ASS')
                                                                  dbWriteTable(db_inova_dm,"VAR_ASS",tmp_df)
                                                                  
                                                                  #Base inicial pra modelo 
                                                                  tmp_df <-  dbGetQuery(db_inova_dm, 
                                                                                        "
select db.*, ass.cod_assunto, max(assunto_pai)
from vl_dadosBasicos db

left join VAR_ASS ass

where db.numero = ass.numero 
and db.classeProcessual = ass.classeProcessual
and db.codigoOrgao = ass.codigoOrgao
and db.grau = ass.grau
group by db.numero, db.classeProcessual, db.codigoOrgao, db.grau
")
                                                                  
                                                                  # drop and write tb
                                                                  dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS VAR_BASE')
                                                                  dbWriteTable(db_inova_dm,"VAR_BASE",tmp_df)
                                                                  
                                                                  #Base final pra modelo
                                                                  tmp_df <-  dbGetQuery(db_inova_dm, 
                                                                                        "
select bs.*, tmp.dt_novo, tmp.primeiro_julgamento, tmp.dt_baixa, tmp.tmp_julg, tmp.tmp_bx
from VAR_BASE bs

left join VAR_TEMP tmp

on bs.numero = tmp.numero
and bs.classeProcessual = tmp.classeProcessual
and bs.codigoOrgao = tmp.codigoOrgao
and bs.grau = tmp.grau
")
                                                                  
# drop and write tb
dbExecute(db_inova_dm, 'DROP TABLE IF EXISTS BASE_MODELO')
dbWriteTable(db_inova_dm,"BASE_MODELO",tmp_df)
                                                                  
rm(tmp_df)
                                                                  
dbExecute(db_inova_dm, 'VACUUM')

# disconnect
dbDisconnect(db_inova_dm)                                                                 
                                                                  
