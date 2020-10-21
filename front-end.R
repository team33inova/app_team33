library(shiny)
library(dplyr)
library(dbplyr)
library(shinydashboard)
library(plotly)
library(readr)
library(ggplot2)
library(ANN2)

#tema ggplot2
theme_set(theme_minimal())



#carregando o dicionário
load("presp.RData")

#carregando o modelo
nn <- read_ANN("nn.ann")

estoque <- read_csv("estoque.csv",
                    col_types = cols(data = col_date(format = "%Y-%m-%d")))[,-1]

ui <- dashboardPage(
  dashboardHeader(
    title = "Tempo e Produtividade #33",
    titleWidth = 300
  ),
  dashboardSidebar(
    width=300,
    sidebarMenu(
      menuItem("Previsão Processamento", tabName = "tempo",
               icon = icon("hourglass-half")),
      menuItem("Estoque", tabName = "estoque", icon = icon("chart-bar"))
    )
  ),
  dashboardBody(
    tabItems(
      
      tabItem(tabName = "tempo",
              fluidRow(
                
                box(
                  title="Informação", status = "primary",
                  solidHeader = TRUE,
                  helpText("Entre com os seguintes dados para", 
                           "prever o tempo de processamento do",
                           "processo."),
                  
                  selectInput("classeProcessual", "Classe Processual",
                              p.resp$classeProcessual$descricao),
                  
                  selectInput("codigoOrgao", "Serventia",
                              p.resp$codigoOrgao$descricao),
                  
                  selectInput("grau", "Grau", p.resp$grau$descricao),
                  
                  selectInput("dscSistema", "Sistema Eletrônico",
                              p.resp$dscSistema$descricao),
                  
                  selectInput("procEl", "Processo Eletrônico",
                              p.resp$procEl$descricao),
                  
                  selectInput("tipo", "Tipo", p.resp$tipo$descricao),
                  
                  selectInput("esfera", "Esfera",
                              p.resp$esfera$descricao),
                  
                  selectInput("maxCodPai", "Assunto",
                              p.resp$maxCodPai$descricao),
                  
                  column(12, align="center", 
                         submitButton("Confirmar"))
                ),
                
                box(
                  title="Previsão", status = "warning",
                  solidHeader = TRUE,
                  htmlOutput("previsao")
                )
                
              )
      ),
      
      tabItem(tabName = "estoque",
              fluidRow(
                box(
                  title="Filtro", status = "primary", 
                  solidHeader = TRUE, width = 4,
                  selectInput("codigoOrgao.estoque", "Serventia", 
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
              
      )
    )
  )
)

server <- function(input, output) {
  
  selections <- reactive({
    data.frame(
      "classeProcessual" = 
        as.numeric(p.resp$classeProcessual[which(
          p.resp$classeProcessual$descricao == 
            input$classeProcessual),]$cod),
      "codigoOrgao" = 
        as.numeric(p.resp$codigoOrgao[which(
          p.resp$codigoOrgao$descricao == 
            input$codigoOrgao),]$cod),
      "grau" = 
        as.numeric(p.resp$grau[which(
          p.resp$grau$descricao == input$grau),]$sigla),
      "dscSistema" = 
        as.numeric(p.resp$dscSistema[which(
          p.resp$dscSistema$descricao == 
            input$dscSistema),]$cod),
      "procEl" = 
        as.numeric(p.resp$procEl[which(
          p.resp$procEl$descricao == input$procEl),]$cod),
      "tipo" = 
        as.numeric(p.resp$tipo[which(
          p.resp$tipo$descricao == input$tipo),]$cod),
      "esfera" = 
        as.numeric(p.resp$esfera[which(
          p.resp$esfera$descricao == input$esfera),]$cod),
      "maxCodPai" = 
        as.numeric(p.resp$maxCodPai[which(
          p.resp$maxCodPai$descricao == input$maxCodPai),]$cod)
    )
  })
  
  teste <- reactive({
    estoque %>% filter(codigoOrgao==p.resp$codigoOrgao[which(
      p.resp$codigoOrgao$descricao==
        input$codigoOrgao.estoque),]$cod.estoque)
  })
  
  output$plot.estoque <- renderPlotly({
    plot_ly(teste(), x=~data, y=~contagem, type='scatter',mode="lines",
            fill="tozeroy") %>% layout(xaxis = list(title="Data"),
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
    predict(nn,selections())
  })
  
  output$previsao <- renderText({
    paste0("<h1 style=\"text-align: center;font-size:40px;\">",
           round(as.numeric(pred()),2)," dias. <h1>")
  })
  
}

shinyApp(ui, server)
