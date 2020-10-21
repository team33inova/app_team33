<img src="imagens/cnjInova.webp" style="display: block; margin-left: auto; margin-right: auto; width: 70%; padding-bottom: 50px">

# RaioX

## 1. **Na visão de vocês e referente ao desafio que escolheram qual é o problema que querem solucionar?**
Bem como explicitado no Relato 03 do material de apoio: Relatos de Apoio - Personas, onde a persona especificada “gostaria de ter uma previsão de quanto tempo seu processo irá levar para ter uma decisão,”, e ainda, a baixa informação disponível pelo Judiciário quanto à informações de previsão em geral, o time 33 se propôs, como objetivo principal, desenvolver um método que seja capaz de estimar o tempo médio de julgamento de um processo, dado alguns parâmetros conhecidos da base do Datajud.
E ainda, como forma de complementar e trazer mais informações à Sociedade, o segundo objetivo do time 33 foi de, a partir do Datajud, reconstruir toda a série histórica de Estoque Processual por serventia, permitindo assim, uma análise temporal do fato, tanto para o passado, quanto para futuras predições futuras.

## 2. **O que a solução promete gerar de resultados?**
Assim, com o tempo médio de julgamento do processo dado certos parâmetros e o estoque, entendemos que isso poderá contribuir para: a) planejamento interno e externo entre as partes interessadas a partir da informação do tempo médio de julgamento previsto; b) identificar possíveis gargalos na base avaliando os maiores estoques entre as serventias e os maiores tempos médios de tramitação; c) suportar o processo decisório do Poder Judiciário e das serventias.
A solução gera dois resultados: O primeiro é o tempo médio de julgamento dado parâmetros conhecidos de um processo; e o segundo é a série histórica do Acervo Processual de cada serventia.

## 3. **Quais principais métricas do modelo?**
Portanto o modelo possui duas métricas: O primeiro é um estimador via rede neural do tempo médio do processo até o julgamento, e o segundo, é o estoque processual.
Para tempo de julgamento, foi considerado o tempo entre o primeiro movimento do processo até o primeiro movimento da árvore 193 (SGT-CNJ) - Julgamento. Foi usado primeiro movimento como data de início para a contagem pois: a) a tag dataAjuizamento está claramente inutilizada pela inconsistências da base; b) o movimento 26 - Distribuição não está presente em quantidade suficiente de processos. 
Para medição do Estoque, foi considerado o primeiro movimento (mais antigo) como início do processo, e para a baixa foi considerado os movimentos 22, 246 e 488. Sendo assim, a partir da tag “dataHora” foi reconstruída a série histórica do Estoque processual para cada serventia a partir de 2015. 

## 4. **Desenho da arquitetura do sistema e Fluxo de dados**
<img src="imagens/fluxoAplicacao2.png" style="display: block; margin-left: auto; margin-right: auto; width: 50%;">

## 6. **Instruções de Uso**
* Na aba de previsão do tempo médio dos processos, o usuário imputa os parâmetros e a aplicação retorna o tempo médio de julgamento para o determinado processo.
* Na aba de estoque processual, o usuário seleciona a serventia desejada e a aplicação retorna o estoque atual da serventia, e ainda um gráfico da série histórica da serventia.

**Instalação**


* PASSO 1: ETL
Plataforma: TALEND OPEN STUDIO FOR DATA INTEGRATION
  1. IMPORTAR O JOB json2sqlite3 dentro do TALEND
    1.1 criar um novo projeto
    1.2 na aba Repository, clicar com o botão direito em” job Designs” e selecionar “Import itens”
    1.3 Select Archieve File
    1.4 Browse: selecionar o arquivo no repositório gitHub json2sqlite3
    1.5 Selecionar inova
    1.6 Finalizar
* PASSO 2: RODAR O JOB
Plataforma: TALEND OPEN STUDIO FOR DATA INTEGRATION
  2.1 selecionar a pasta de origem dos json no componente tFileList_1
  2.2 selecionar o destino da base de dados .sdb nos componentes tdbOutput

Observação: Para esse projeto, a base de dados relacional em formato .sdb se encontra já dentro do projeto R. Sendo assim, não há necessidade de rodar o ETL para instalar a aplicação nessa base atual. Caso queira expandir a base de dados, será necessário, obviamente, rodar esse formato de ETL para compor a base de dados referência da aplicação.

* PASSO 3: DATA MINING
Plataforma: RStudio
  3.1 abrir o projeto R “team33” no Rstudio
  3.2 executar primeiramente o arquivo data_mining.R
  Passo a passo do data_mining
    3.2.1 conexão na base exportada do talend: db_inova
    3.2.2 criar base .sdb de apoio: db_inova_dm
    3.3.3 baixar as tabelas dimensão disponíveis na pasta /dim do projeto para o R
    3.3.4 gravar as tabelas nas bases
    3.3.5 executar querys para limpeza dos dados:
    3.3.6 dados basicos: excluir processos com classes fora da TPU e serventias fora do MPM
    3.3.7 excluir movimentos fora de 1980 e 2020
    3.3.8 excluir assuntos fora da TPU
    3.3.9 excluir orgao julgador fora do MPM
    3.3.10 sincronizar todos os registros das tabelas após a exclusão gerando uma chave unica em comum
    3.3.11 “join” da chave unica com as tabelas
    3.3.12 criar data.frame: primeira baixa de cada processo : VAR_BX
    3.3.13 criar data.frame: primeiro movimento de cada processo : VAR_NV
    3.3.14 criar data.frame: primeirro julgamento de cada processo: VAR_JULG
    3.3.15 criar data.frame: processos pendentes: VAR_PDT
    3.3.16 criar data.frame: processos pendentes totalizados: VAR_PDT_TOT
    3.3.17 unir numa tabela tempos de julgamento, baixas e novos
    3.3.18 criar função para calcular o tempo entre as datas: dif_dt
    3.3.19 criar variaveis computadas atraves da função
    3.3.20 criar data.frame VAR_TEMP
    3.3.21 identificar assunto prinicipal do processo: VAR_ASS
    3.3.22 criar data.frame pra rodar rede neural: VAR_BASE
    3.3.23 ajustar data.frame para modelo: BASE_MODELO
    3.3.24 VACUUM 
  3.4 executar o arquivo estoque.R
    3.4.1 criar tibble da VAR_PDT_TOT da base inova_dm
    3.4.2 ajustar coluna data
    3.4.3 criar aquivo estoque.csv dentro do projeto
  3.5 executar o arquivo modelo.R
    3.5.1 criar data.frame: dat da BASE_MODELO
    3.5.2 excluir NA
    3.5.3 excluir tempo de julgamento igual a zero
    3.5.4 transformar co-variáveis em fatores
    3.5.5 selecionar as variáveis do modelo de rede neural
    3.5.6 treinar o modelo
    3.5.7 gravar modelo no Projeto
  3.6 executar o arquivo front end

## 7. **Licenças utilizadas**
* Apache (versão 2.0)
* ETL Talend Open Data Integration
* PostgreSQL
* SQLite3
* R (versão 4.0.2)

## 8. **Áreas de conhecimento e técnicas envolvidas**
A aplicação abrange conhecimentos em **ETL**, especificamente o uso do *Talend Open DAta Integration*, software open source, com o objetivo de transformar os arquivos .JSON em uma base relacional SQLITE3 (.sdb).
Posteriomente, é exigido conhecimento em **SQL** no sentido de migrar a base .sdb para um banco de dados *PostgreSQL* a fim de servir a aplicação.
Seguindo, a aplicação é desenvolvida no ambiente *R*. É utilizado um banco .sdb para dar suporte ao **Process Mining** dentro do ambiente. Após a mineração de dados, o modelo de **Rede Neural** é treinado usando o pacote *ANN2*. E o front end é suportado pelo pacote *Shinny*, ainda em ambiente *R*. O deploy foi realizado no servidor do *RShinny*.

## Licença
[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
