#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#


# Cargamos los paquetes necesarios 
library(shiny)
library(tidyverse)
library(rjson)
library(DT)
library(readODS)
library(bslib) # Hace que se vea mejor, permite una UI moderna

# --- CARGA DE DATOS ---
  # Cargar CSV
  tabla_csv_orientacion <- read_csv("DATA/VIH_orientaciónSexual.csv", show_col_types = FALSE)
  
  # Cargar ODS
  Modotransmisioncompleto <- read_ods("DATA/Modotranscompleto.ods")
  motivosVIH <- read_ods("DATA/motivosVIH.ods")
  
  # Cargar JSON
  REG_Vih <- fromJSON(file = "DATA/registro-nuevas-infecciones-por-vih.json")
  REG_Vih_df <- map_dfr(REG_Vih, ~ .x$fields) #Esto es necesario a la hora de importar un JSON
  



# Pasamos a numérico todo lo que había en rmd para evitar problemas
REG_Vih_df$ano_num <- as.numeric(REG_Vih_df$ano)
REG_Vih_df$edad <- as.numeric(REG_Vih_df$edad)

# Creación tabla unida y otras tablas necesarias
tabla_unida <- left_join(REG_Vih_df, tabla_csv_orientacion, by = c("edad" = "Edad", "sexo" = "Sexo"), `relationship = "many to many"`)
tabla_unida$edad <- as.numeric(tabla_unida$edad)
tabla_unida$`Parejas ultimo año` <- as.numeric(tabla_unida$`Parejas ultimo año`)

tabla_para_grafico <- motivosVIH %>%
  filter(Motivo != "Total") %>% 
  filter(Edad != "Total") %>%   
  filter(`Comunidades y Ciudades Autónomas` != "Total Nacional")%>%
  mutate(
    Edad = recode(Edad,
                  "Menos de 40 años" = "<40 Años",
                  "40 y más años"    = ">=40 Años"
    )
  )



#Aquí empieza la interfaz de usuario. Sería lo que verá el profe
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bg = "#FFF0F5",      # Color de FONDO (Este es un rosa muy suave, tipo Lavanda)
    fg = "#333333",      # Color del TEXTO (Gris oscuro para que se lea bien)
    primary = "#D81B60",# Color de los BOTONES y enlaces (Un rosa más fuerte)
    base_font = font_google("Poppins")
  
  ),

  
  titlePanel("Visualización del estudio VIH y los factores de Riesgo"),
  
  tags$head(
    tags$style(HTML("
      .img-galeria {
        border-radius: 15px;
        box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
        transition: 0.5s;
        width: 100%;
        height: 250px; /* Un poco más altas para que luzcan bien */
        object-fit: cover;
        margin-bottom: 15px;
        border: 3px solid #D81B60; /* Borde rosa elegante */
      }
      .img-galeria:hover {
        transform: scale(1.03);
        box-shadow: 0 10px 20px 0 rgba(0,0,0,0.3);
      }
      .titulo-seminario {
        text-align: center; color: #D81B60; font-weight: 800; margin-top: 40px; margin-bottom: 10px;
      }
      .subtitulo {
        text-align: center; color: #555; margin-bottom: 40px; font-size: 18px;
      }
      .texto-imagen {
        text-align: center; font-weight: bold; color: #D81B60; font-size: 16px;
      }
    "))
  ),

  navbarPage("Seminario A",
             
             tabPanel("Inicio", icon = icon("cat"),
                      
                      div(class = "titulo-seminario",
                          h1("Análisis del Impacto del VIH y Factores de Riesgo")
                      ),
                      div(class = "subtitulo",
                          p("Seminario de Investigación 2025 -  Estudio  sobre la evolución y prevención en el VIH.")
                      ),
                      

                      layout_column_wrap(
                        width = 1/3, 
                        
  
                        div(
                          img(src = "corazon.jpg", class = "img-galeria"), 
                          div(class = "texto-imagen", "Crónico")
                        ),
                        
                        div(
                          img(src = "perfecto.png", class = "img-galeria"),
                          div(class = "texto-imagen", "Prevenible")
                        ),
                        
                        div(
                          img(src = "preservativo.jpg", class = "img-galeria"),
                          div(class = "texto-imagen", "Controlable")
                        )
                      ),
                      
                      hr(),
                      
                      div(style="text-align: center; color: #777; margin-top: 30px; margin-bottom: 20px;",
                          p(em("Autoras: Amina Khantimirova, Wiam Messari y Emma Arrieta"))
                      )
             ),
             
            
             tabPanel("Evolución Temporal",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput("rango_anos", "Selecciona rango de años:",
                                      min = 2013, max = 2023, value = c(2013, 2023), sep = "")
                        ),
                        mainPanel(
                          plotOutput("plot_evolucion"),
                          h4("Datos detallados por año"),
                          dataTableOutput("tabla_evolucion")
                        )
                      )
             ),
             
  
             tabPanel("Conducta Sexual",
                      fluidRow(
                        column(6, 
                               h3("Prevalencia por Hábito Sexual"),
                               plotOutput("plot_prevalencia")
                        ),
                        column(6,
                               h3("Uso de Preservativo"),
                               helpText("Comparativa del uso 'Siempre' vs otros"),
                               plotOutput("plot_preservativos")
                        )
                      ),
                      hr(), #
                      fluidRow(
                        column(12,
                               h4("Tabla de Prevalencia"),
                               dataTableOutput("dt_prevalencia")
                        )
                      )
             ),
             
             tabPanel("Correlaciones y Riesgo",
                      sidebarLayout(
                        sidebarPanel(
                          h4("Filtros de Regresión"),
                          checkboxGroupInput("estados_clinicos", "Seleccionar Estado Clínico:",
                                             choices = c("Asintom", "SIDA"),
                                             selected = c("Asintom", "SIDA")),
                          helpText("Observa cómo cambia la línea de tendencia según el grupo.")
                        ),
                        mainPanel(
                          plotOutput("plot_regresion_parejas"),
                          p("Nota: Este gráfico muestra la relación entre la edad y el número de parejas en el último año.")
                        )
                      )
             ),
             
             tabPanel("Análisis por Provincia",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput("top_n_prov", "Mostrar Top N provincias con más casos:",
                                      min = 3, max = 9, value = 15)
                        ),
                        mainPanel(
                          plotOutput("plot_provincias", height = "600px")
                        )
                      )
             ),
             tabPanel("Edad y grupo de riesgo",
                      h3("Análisis de Grupo de Riesgo (Sífilis)"),
                      p("Visualización de casos según estado de sífilis."),
                      plotOutput("grupo_de_riesgo_edad")
                      ),
             tabPanel("Distribución de los Factores de riesgo",
                      sidebarLayout(
                        sidebarPanel(
                          h4("Filtros"),
                          
                          checkboxGroupInput("filtro_motivos", 
                                             "Selecciona los factores de riesgo:",
                                      
                                             choices = unique(tabla_para_grafico$Motivo), 
                                             
                                             selected = unique(tabla_para_grafico$Motivo)
                          ),
                          helpText("Desmarca las casillas para ocultar ciertos grupos del gráfico.")
                        ),
                        
                        mainPanel(
                          plotOutput("correlacion40", height = "800px")
                        )
                      )
             ),
             tabPanel("Parejas Sexuales y VIH",
                      sidebarLayout(
                        sidebarPanel(
                          h4("Filtros de Población"),
                          
                          # Filtro de Años (Slider)
                          sliderInput("filtro_ano_parejas", 
                                      "Selecciona el periodo:",
                                      min = 2013, max = 2023, 
                                      value = c(2013, 2023), 
                                      sep = ""), # sep="" quita la coma de los miles (2,013 -> 2013)
                          
                          # Filtro de Estado VIH (Checkbox)
                          checkboxGroupInput("filtro_estado_vih",
                                             "Estado Serológico:",
                                             choices = unique(tabla_unida$VIH[!is.na(tabla_unida$VIH)]), # Evitamos NA en las opciones
                                             selected = unique(tabla_unida$VIH[!is.na(tabla_unida$VIH)])
                          ),
                          
                          helpText("Nota: El tamaño de la burbuja representa la cantidad de personas que coinciden en ese año y número de parejas.")
                        ),
                        
                        mainPanel(
                          # Le damos buena altura para ver los detalles
                          plotOutput("plot_tendencia_parejas", height = "600px")
                        )
                      )
             )
  )
)


server <- function(input, output) {
  
  datos_evolucion <- reactive({
    REG_Vih_df %>%
      filter(ano_num >= input$rango_anos[1] & ano_num <= input$rango_anos[2]) %>%
      count(ano_num, name = "Casos_Nuevos")
  })
  
  output$plot_evolucion <- renderPlot({
    ggplot(data = datos_evolucion(), aes(x = ano_num, y = Casos_Nuevos)) +
      geom_point(color = "green", size = 3) +
      geom_line(color = "red", size = 1.5) +
      geom_text(aes(label = Casos_Nuevos), vjust = -1, size = 5) +
      labs(title = paste("Evolución de casos (", input$rango_anos[1], "-", input$rango_anos[2], ")"),
           x = "Año", y = "Nuevos Casos") +
      theme_minimal(base_size = 14)
  })
  
  output$tabla_evolucion <- renderDataTable({
    datos_evolucion()
  })
  
  
  # AQuí ponemos los códigos que ya tenemos en el RMD de la lógica de las tablas
  data_prevalencia <- reactive({
    tabla_csv_orientacion %>%
      filter(`Hábito sexual` %in% c("HSH", "Heterosexual")) %>%
      group_by(`Hábito sexual`) %>%
      summarise(
        Casos = n(),
        VIH_Positivo = sum(VIH == "SÍ"), 
      ) %>%
      mutate(`Tasa de Prevalencia (%)` = round((VIH_Positivo / Casos) * 100, 2))
  })
  output$grupo_de_riesgo_edad <- renderPlot({
    ggplot(data = tabla_unida, aes(x= `edad`, y = `d_grupo_riesgo`, coulor = `d_grupo_riesgo`))+
      geom_boxplot(size = 1.5)+
      labs(
        title = "Distribucion de la edad por grupo de riesgo",
        x = "Edad",
        y = "Grupo de Riesgo",
      )
  })
  
  output$correlacion40 <- renderPlot({
    req(input$filtro_motivos) 
    
    datos_filtrados <- tabla_para_grafico %>%
      filter(Motivo %in% input$filtro_motivos)
    ggplot(datos_filtrados, 
           aes(x = Total, 
               y = `Comunidades y Ciudades Autónomas`, 
               color = Motivo)) + 
      
      geom_point(size = 1.5, alpha = 0.8) +
      facet_wrap(~Edad, scales = "free_x") + 
      
      labs(
        title = "Distribución de Edad por CCAA",
        x = "Cantidad",
        y = "Comunidad Autónoma",
        color = "Motivo de Infección" 
      ) +
      theme_minimal() 
  })
  
  output$plot_prevalencia <- renderPlot({
    ggplot(data = data_prevalencia(), 
           aes(x = `Hábito sexual`, y = `Tasa de Prevalencia (%)`, fill = `Hábito sexual`)) +
      geom_col(colour = "black", width = 0.6) +
      geom_text(aes(label = paste0(`Tasa de Prevalencia (%)`, "%")), vjust = -0.6, size = 4) +
      theme_minimal() +
      labs(y = "Tasa (%)")
  })
  
  output$plot_preservativos <- renderPlot({
    uso_preservativo <- tabla_csv_orientacion %>%
      filter(`Hábito sexual` %in% c("HSH", "Heterosexual")) %>%
      group_by(`Hábito sexual`) %>%
      count(`preservativo siempre`, name = "Frecuencia") %>%
      mutate(Total = sum(Frecuencia), Porcentaje = round((Frecuencia/Total)*100, 2))
    
    ggplot(uso_preservativo, aes(x=`Hábito sexual`, y = Porcentaje, color = `preservativo siempre`)) +
      geom_point(size = 8, shape = 18) + 
      geom_line(aes(group = `preservativo siempre`), linetype = "dashed") +
      geom_text(aes(label = paste0(Porcentaje, "%")), vjust = -1.5) +
      theme_minimal() +
      labs(y = "Porcentaje de Uso (%)")
  })
  
  output$dt_prevalencia <- renderDataTable({ data_prevalencia() })
  
  
  output$plot_regresion_parejas <- renderPlot({
    req(input$estados_clinicos)
    
    data_dispersion <- tabla_unida %>%
      filter(estado_clinico %in% input$estados_clinicos) %>%
      drop_na(edad, `Parejas ultimo año`, estado_clinico)
    
    ggplot(data = data_dispersion, aes(x = edad, y = `Parejas ultimo año`, color = estado_clinico)) +
      geom_point(alpha = 0.6, size = 2) +
      geom_smooth(method = "lm", se = TRUE, size = 1.2) + 
      labs(title = "Relación Edad vs Parejas", x = "Edad", y = "Parejas último año") +
      scale_color_manual(values = c("Asintom" = "blue", "SIDA" = "red")) +
      theme_minimal(base_size = 14)
  })
  
  
  output$plot_provincias <- renderPlot({
    casos_por_provincia <- REG_Vih_df %>%
      count(provincia_residencia, name = "Total_Casos") %>%
      arrange(desc(Total_Casos)) %>%
      slice(1:input$top_n_prov) # Interactividad: Muestra solo el top N seleccionado
    
    ggplot(casos_por_provincia, aes(x = Total_Casos, y = reorder(provincia_residencia, Total_Casos))) +
      geom_point(size = 4, color = "deeppink") +
      geom_text(aes(label = Total_Casos), hjust = -0.5, size = 3.5) +
      labs(title = paste("Top", input$top_n_prov, "Provincias con más casos"), 
           x = "Total Casos", y = "Provincia") +
      theme_minimal(base_size = 14)
  })
  
  output$plot_tendencia_parejas <- renderPlot({
    # 1. Validaciones para evitar errores
    req(input$filtro_estado_vih)
    
    # 2. Preparación de datos (Reactiva dentro del render)
    parejas_vih_filtrado <- tabla_unida %>%
      # Filtramos por los inputs del usuario
      filter(ano >= input$filtro_ano_parejas[1] & ano <= input$filtro_ano_parejas[2]) %>%
      filter(VIH %in% input$filtro_estado_vih) %>%
      filter(!is.na(VIH)) %>% # Quitamos NAs si quedan
      
      # --- PASO CLAVE: CONTAR ---
      # Agrupamos y contamos para que el tamaño ("size") funcione
      count(ano, VIH, `Parejas ultimo año`, name = "Cantidad_Personas")
    
    # 3. Gráfico
    ggplot(data = parejas_vih_filtrado, 
           aes(x = ano, 
               y = `Parejas ultimo año`, 
               color = VIH, 
               size = Cantidad_Personas)) + # Ahora 'size' usa el conteo real
      
      geom_point(alpha = 0.7) +
      
      # Ajustamos la escala de tamaño para que las burbujas se vean bien
      scale_size_continuous(range = c(2, 10)) + 
      
      labs(
        title = "Frecuencia de Parejas Sexuales por Año y Estado de VIH",
        subtitle = paste("Periodo:", input$filtro_ano_parejas[1], "-", input$filtro_ano_parejas[2]),
        x = "Año de la Encuesta",          # Corregido (antes estaba cambiado)
        y = "Parejas Sexuales (Último Año)", # Corregido
        color = "Estado VIH",
        size = "Nº Personas"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(size = 12),
        legend.position = "bottom"
      )
  })
  
}

shinyApp(ui, server)
