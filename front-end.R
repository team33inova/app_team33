#front end :: testegit

rm(list = ls())
#install.packages(c("shiny","dbplyr","shinydashboard","plotly","readr",
#                   "ggcorrplot"))
library(shiny)
library(dplyr)
library(dbplyr)
library(shinydashboard)
library(plotly)
library(readr)
library(ggcorrplot)
library(RSQLite)
library(ANN2)


#tema
theme_set(theme_minimal())


#conexoes
db_inova_dm <- dbConnect(RSQLite::SQLite(), 'inova_dm.sdb')

#tabela estoque
estoque <-  read_csv("estoque.csv",
                   col_types = cols(data = col_date(format = "%Y-%m-%d")))[,-1]


#pegando codigos das variaveis
cod.orgao <-  sort(unique(dat$codigoOrgao))
cod.pai <-  sort(unique(dat$maxCodPai))
cod.tipo <-  sort(unique(dat$tipo))


#preparando a lista de parametros ==============================================
p.resp = list(
  classeProcessual = sgt_classe[with(sgt_classe, order(descricao)),1:2],
  codigoOrgao = data.frame(cod = cod.orgao, descricao = cod.orgao),
  grau = data.frame(sigla = as.numeric(as.factor(unique(dat$grau))),
                    descricao = c("1º Grau", "2º Grau", "Juizados Especiais",
                                  "Turma Recursal")),
  dscSistema = data.frame(cod = c(1:4, 8),
                          descricao = c("Pje", "Projudi", "SAJ", "EPROC",
                                        "Outros")),
  procEl = data.frame(cod = unique(dat$procEl),
                      descricao = c("Sistema Eletrônico", "0" ,
                                    "Sistema Físico")),
  tipo = data.frame(cod = as.numeric(as.factor(unique(dat$tipo))),
                    descricao = cod.tipo),
  esfera = data.frame(cod = as.numeric(as.factor(unique(dat$esfera))),
                      descricao = c("Eleitoral", "Militar", "Trabalhista")),
  maxCodPai = data.frame(cod = sort(unique(dat$maxCodPai)),
                         descricao = cod.pai)
)
#===============================================================================

#lendo o modelo ================================================================
modNN = read_ANN('03 modelos/nn.ann')
#===============================================================================

#funcao para normalizar os dados ===============================================
normalize = function(x) return ((x - min(x)) / (max(x) - min(x)))
k = with(dat, abs(diff(range(tmp_julg))) + min(tmp_julg))
#===============================================================================

#pagina ui =====================================================================
ui <- dashboardPage(
  dashboardHeader(
    title = "Tempo e Produtividade #33",
    titleWidth = 300
  ),
  dashboardSidebar(
    width=300,
    sidebarMenu(
      menuItem("Previsão Processamento",
               tabName = "tempo", icon = icon("hourglass-half")),
      menuItem("Estoque", tabName = "estoque", icon = icon("chart-bar")),
      menuItem("Correlação das Variáveis",
               tabName = "correlacao", icon = icon("project-diagram"))
    )
  ),
  dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "tempo",
              fluidRow(
                box(
                  title="Informação",
                  status = "primary",
                  solidHeader = TRUE,
                  helpText("Entre com os seguintes dados para", 
                           "prever o tempo de processamento do",
                           "processo."),
                  selectInput("classeProcessual", "Classe Processual",
                              p.resp$classeProcessual$descricao),
                  selectInput("codigoOrgao", "Código Orgão",
                              p.resp$codigoOrgao$descricao),
                  selectInput("grau", "Grau", p.resp$grau$descricao),
                  selectInput("dscSistema", "Sistema Eletrônico",
                              p.resp$dscSistema$descricao),
                  selectInput("procEl", "Processo Eletrônico",
                              p.resp$procEl$descricao),
                  selectInput("tipo", "Tipo",
                              p.resp$tipo$descricao),
                  selectInput("esfera", "Esfera",
                              p.resp$esfera$descricao),
                  selectInput("maxCodPai", "Código Pai",
                              p.resp$maxCodPai$descricao),
                  column(12, align="center", 
                         submitButton("Confirmar"))
                ),
                box(
                  title="Previsão",
                  status = "warning",
                  solidHeader = TRUE,
                  htmlOutput("previsao")
                ),
                box(
                  title="Seleções",
                  status = "primary",
                  solidHeader = TRUE,
                  tableOutput("selecao")
                )
              )
      ),
      tabItem(tabName = "estoque",
              fluidRow(
                box(
                  title="Filtro", status = "primary",
                  solidHeader = TRUE, width = 4,
                  selectInput("codigoOrgao.estoque", "Código Orgão",
                              p.resp$codigoOrgao$descricao),
                  column(12, align="center", 
                         submitButton("Confirmar"))
                ),
                infoBoxOutput("total.estoque"),
                infoBoxOutput("total.estoque.fixo"),
                box(title="Histórico do Estoque de Processos",
                    status = "primary", solidHeader = TRUE,
                    width = 8, plotlyOutput("plot.estoque")
                )
              )
              
      ),
      tabItem(tabName = "correlacao",
              fluidRow(
                box(title="Variáveis",
                    status = "primary",
                    solidHeader = TRUE,
                    background = "light-blue",
                    strong("tmp_julg"),
                    " = Tempo de julgamento em dias.", br(),
                    strong("classeProcessual"),
                    " = Classe processual.", br(),
                    strong("codigoOrgao"),
                    " = Código do órgão.", br(),
                    strong("grau"),
                    " = Grau do processo.", br(),
                    strong("dscSistema"),
                    " = Indica o tipo de sistema eletrônico.", br(),
                    strong("procEl"),
                    " = Processo eletrônico ou não.", br(),
                    strong("tipo"),
                    " = Tipo de processo.", br(),
                    strong("esfera"),
                    " = Esfera.", br(),
                    strong("maxCodPai"),
                    " = Código pai."
                ),
                box(
                  title="Correlação das Variáveis",
                  status = "primary",
                  solidHeader = TRUE,
                  plotOutput("plot.correlacao")
                )
              )
      )
      
    )
  )
)

server <- function(input, output) {
  selections <- reactive({
    data.frame(
      classeProcessual = as.numeric(p.resp$classeProcessual[
        which(p.resp$classeProcessual$descricao ==
                input$classeProcessual),]$cod_classe),
      codigoOrgao = as.numeric(p.resp$codigoOrgao[
        which(p.resp$codigoOrgao$descricao ==
                input$codigoOrgao),]$cod),
      grau = as.numeric(p.resp$grau[
        which(p.resp$grau$descricao ==
                input$grau),]$sigla),
      dscSistema = as.numeric(p.resp$dscSistema[
        which(p.resp$dscSistema$descricao ==
                input$dscSistema),]$cod),
      procEl = as.numeric(p.resp$procEl[
        which(p.resp$procEl$descricao ==
                input$procEl),]$cod),
      tipo = as.numeric(p.resp$tipo[
        which(p.resp$tipo$descricao ==
                input$tipo),]$cod),
      esfera = as.numeric(p.resp$esfera[
        which(p.resp$esfera$descricao ==
                input$esfera),]$cod),
      maxCodPai = as.numeric(p.resp$maxCodPai[
        which(p.resp$maxCodPai$descricao ==
                input$maxCodPai),]$cod)
    )
  })
  teste <- reactive({
    estoque %>% filter(codigoOrgao==input$codigoOrgao.estoque)
  })
  output$plot.estoque <- renderPlotly({
    plot_ly(teste(),
            x = ~ data,
            y = ~ contagem,
            type = 'scatter',
            mode = "lines",
            fill="tozeroy") %>% 
      layout(xaxis = list(title="Data"),
             yaxis = list(title="Quantidade"))
  })
  output$total.estoque <- renderInfoBox({
    infoBox(
      "Estoque Total do Órgão",
      sum(teste()$contagem),
      icon = icon("file")
    )
  })
  output$total.estoque.fixo <- renderInfoBox({
    infoBox(
      "Estoque Total",
      sum(estoque$contagem),
      icon = icon("copy")
    )
  })
  output$plot.correlacao <- renderPlot({
    ggcorrplot(cor(dat[,-c(10)]), method = "circle")
  })
  output$selecao <- renderTable({
    selections()
  })
  pred <- reactive({
    predict(modNN, selections())$predictions
  })
  output$previsao <- renderText({
    paste0("<h1 style=\"text-align: center;font-size:40px;\">",
           round(as.numeric(pred()),2)," dias <h1>")
  })
}

shinyApp(ui, server)
#===============================================================================
