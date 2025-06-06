#install.packages(c("arrow", "dplyr", "ggplot2"))
# Instalar librerías si hace falta
install.packages(c("arrow","dplyr","ggplot2","readr","sf", "tidyr", "RColorBrewer","kableExtra","scales","knitr","lubridate","viridis"))  # si no se tienen
# Cargar librerías importantes
library(arrow)
library(dplyr) #Util para eliminar columnas
library(ggplot2) # para graficar
library(readr)
library(sf) 
library(tidyr)    
library(RColorBrewer)  # para paletas extra
library(kableExtra)
library(scales)
library(viridis)
library(knitr)
library(lubridate)
library(stringr)


##################################Carga de Datos#########################################################

datos <- read_parquet("C:/Datos_limpios/datos_filtrados_reclutamiento.parquet") 


##################################Pregunta 1#########################################################
#Análisis del número de afectados entre los años 1985 a 2018 (reclutamientos)
#Gráfica : Histograma.


# 1. Filtrar el rango de años de interés y contar víctimas por año
df_por_ano <- datos %>%
  filter(yy_hecho >= 1985, yy_hecho <= 2018) %>%
  group_by(yy_hecho) %>%
  summarise(n_victimas = n(), .groups = "drop")


# datos %>%:
# Inicia una secuencia de comandos usando el operador pipe (%>%),
# que permite leer y aplicar comandos en orden.

# filter(yy_hecho >= 1985, yy_hecho <= 2018):
# Filtra los registros del DataFrame datos.
# 
# - Condición: Solo mantiene las filas donde el año (yy_hecho) 
#   está entre 1985 y 2018.
# - Esto asegura que solo analizamos los datos del periodo de interés.

# group_by(yy_hecho):
# Agrupa los datos por año (yy_hecho).

# summarise(n_victimas = n(), .groups = "drop"):
# Para cada año (yy_hecho), cuenta el número de filas (número de víctimas).
# 
# - El resultado es una tabla con dos columnas:
#   - yy_hecho: El año.
#   - n_victimas: El número total de víctimas en ese año.
# - .groups = "drop" evita que el resultado sea un objeto agrupado 


# 2. Crear el histograma (barras por año)
ggplot(df_por_ano, aes(x = yy_hecho, y = n_victimas)) +
  geom_col(width = 0.8) +
  scale_x_continuous(breaks = seq(1985, 2018, by = 1)) +
  labs(
    title    = "Número de víctimas de reclutamiento por año (1985–2018)",
    x        = "Año",
    y        = "Número de víctimas"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
    panel.grid.minor = element_blank()
  )
##################################Pregunta 2#########################################################
#Mapa de calor: Referencias de los departamentos afectados por  la problemática. ¿Qué departamento es el más afectado?¿En qué año se pudo ver más activa la violencia en los departamentos

# MAPA DE CALOR Reclutamientos 


# 1. Leer datos de Reclutamiento
casos_dept <- datos %>%
  mutate(dept_code_hecho = sprintf("%02d", as.integer(dept_code_hecho))) %>%
  group_by(dept_code_hecho) %>%
  summarise(n_victimas = n(), .groups = "drop")

# 2. Leer el GeoPackage
gdf_dept <- st_read("C:/Datos_limpios/gadm41_COL.gpkg", layer = "ADM_ADM_1") %>%
  st_transform(4326)

# 3. Diccionario nombre → código DANE
nombre_codigos <- c(
  "Amazonas" = "91", "Antioquia" = "05", "Arauca" = "81", "Atlántico" = "08",
  "Bogotá D.C." = "11", "Bolívar" = "13", "Boyacá" = "15", "Caldas" = "17",
  "Caquetá" = "18", "Casanare" = "85", "Cauca" = "19", "Cesar" = "20",
  "Chocó" = "27", "Córdoba" = "23", "Cundinamarca" = "25", "Guainía" = "94",
  "Guaviare" = "95", "Huila" = "41", "La Guajira" = "44", "Magdalena" = "47",
  "Meta" = "50", "Nariño" = "52", "Norte de Santander" = "54", "Putumayo" = "86",
  "Quindío" = "63", "Risaralda" = "66", "San Andrés y Providencia" = "88",
  "Santander" = "68", "Sucre" = "70", "Tolima" = "73", "Valle del Cauca" = "76",
  "Vaupés" = "97", "Vichada" = "99"
)

# 4. Asignar códigos
gdf_dept <- gdf_dept %>%
  mutate(dept_code_hecho = nombre_codigos[as.character(NAME_1)])

# 5. Unir y completar NA
map_data <- gdf_dept %>%
  left_join(casos_dept, by = "dept_code_hecho") %>%
  replace_na(list(n_victimas = 0))

# 6. Dibujar mapa
ggplot(map_data) +
  geom_sf(aes(fill = n_victimas), color = "gray80", size = 0.2) +
  
  scale_fill_gradientn(
    name = "N° víctimas",
    colours = rev(rainbow(10)),  # 10 colores del arcoíris
    na.value = "white"
  ) +
  
  # Nombres de departamentos (excepto San Andrés y Providencia)
  geom_sf_text(
    data = map_data %>% filter(NAME_1 != "San Andrés y Providencia"),
    aes(label = NAME_1),
    size = 2.5,
    color = "black",
    fontface = "bold",
    fun.geometry = function(x) st_centroid(x, of_largest = TRUE)
  ) +
  
  # Nombre de San Andrés y Providencia (ajustado hacia arriba)
  geom_sf_text(
    data = map_data %>% filter(NAME_1 == "San Andrés y Providencia"),
    aes(label = NAME_1),
    size = 2.5,
    color = "black",
    fontface = "bold",
    nudge_y = 0.3
  ) +
  
  labs(
    title = "Mapa de calor víctimas de Reclutamiento por departamento (1985–2018)"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    legend.position = "right"
  )




##################################Pregunta 3#########################################################
#¿Qué tal está la situación de Bucaramanga? (mapa de calor de los municipios de santander, enfocándonos en la región de santander)


casos_mun <- datos %>%
  mutate(muni_code_hecho = sprintf("%05d", as.integer(muni_code_hecho))) %>%
  group_by(muni_code_hecho) %>%
  summarise(n_victimas = n(), .groups = "drop")

# 2. Leer municipios y filtrar Santander
gdf_mun <- st_read("C:/Datos_limpios/gadm41_COL.gpkg", layer = "ADM_ADM_2") %>%
  st_transform(4326)

gdf_santander <- gdf_mun %>%
  filter(NAME_1 == "Santander")

# 3. Diccionario nombre → código DANE
nombre_codigos <- c(
  "Bucaramanga" = "68001", "Aguada" = "68013", "Albania" = "68020", "Aratoca" = "68051",
  "Barbosa" = "68077", "Barichara" = "68079", "Barrancabermeja" = "68081", "Betulia" = "68092",
  "Bolívar" = "68101", "Cabrera" = "68121", "California" = "68132", "Capitanejo" = "68147",
  "Carcasí" = "68152", "Cepitá" = "68160", "Cerrito" = "68162", "Charalá" = "68167",
  "Charta" = "68169", "Chima" = "68176", "Chipatá" = "68179", "Cimitarra" = "68190",
  "Concepción" = "68207", "Confines" = "68209", "Contratación" = "68211", "Coromoro" = "68217",
  "Curití" = "68229", "El Carmen de Chucurí" = "68235", "El Guacamayo" = "68245", "El Peñón" = "68250",
  "El Playón" = "68255", "Encino" = "68264", "Enciso" = "68266", "Florián" = "68271",
  "Floridablanca" = "68276", "Galán" = "68296", "Gámbita" = "68298", "Girón" = "68307",
  "Guaca" = "68318", "Guadalupe" = "68320", "Guapotá" = "68322", "Guavatá" = "68324",
  "Güepsa" = "68327", "Hato" = "68344", "Jesús María" = "68368", "Jordán" = "68370",
  "La Belleza" = "68377", "Landázuri" = "68385", "La Paz" = "68397", "Lebrija" = "68406",
  "Los Santos" = "68418", "Macaravita" = "68425", "Málaga" = "68432", "Matanza" = "68444",
  "Mogotes" = "68464", "Molagavita" = "68468", "Ocamonte" = "68498", "Oiba" = "68500",
  "Onzaga" = "68502", "Palmar" = "68522", "Palmas del Socorro" = "68524", "Páramo" = "68533",
  "Piedecuesta" = "68547", "Pinchote" = "68549", "Puente Nacional" = "68572", "Puerto Parra" = "68573",
  "Puerto Wilches" = "68575", "Rionegro" = "68615", "Sabana de Torres" = "68655", "San Andrés" = "68669",
  "San Benito" = "68673", "San Gil" = "68679", "San Joaquín" = "68682", "San José de Miranda" = "68684",
  "San Miguel" = "68686", "San Vicente de Chucurí" = "68689", "Santa Bárbara" = "68705",
  "Santa Helena del Opón" = "68720", "Simacota" = "68745", "Socorro" = "68755", "Suaita" = "68770",
  "Sucre" = "68773", "Surata" = "68780", "Tona" = "68820", "Valle de San José" = "68855",
  "Vélez" = "68861", "Vetas" = "68867", "Villanueva" = "68872", "Zapatoca" = "68895"
)

# 4. Agrega los códigos DANE
gdf_santander <- gdf_santander %>%
  mutate(muni_code_hecho = nombre_codigos[as.character(NAME_2)])

# 5. Une con datos de víctimas
map_data <- gdf_santander %>%
  left_join(casos_mun, by = "muni_code_hecho") %>%
  replace_na(list(n_victimas = 0))

# 6. Mapa con nombres de municipios
ggplot(map_data) +
  geom_sf(aes(fill = n_victimas), color = "gray80", size = 0.2) +
  scale_fill_gradientn(
    name     = "N° víctimas",
    colours  = rev(rainbow(10)),
    na.value = "white"
  ) +
  
  # Nombres de municipios centrados
  geom_sf_text(
    aes(label = NAME_2),
    size = 2.2,
    color = "black",
    fontface = "bold",
    fun.geometry = function(x) st_centroid(x, of_largest = TRUE)
  ) +
  
  labs(
    title = "Mapa de calor de Reclutamientos en municipios de Santander\n(1985–2018)"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    legend.position = "right"
  )


##################################Pregunta 4#########################################################
#¿Qué registros de municipios (en Colombia ) principalmente están afectados  (mínimo 5)?

datos <- datos %>%
  mutate(muni_code_hecho = as.numeric(muni_code_hecho))

# 1. Top 5 municipios con más reclutamientos
top_municipios <- datos %>%
  group_by(muni_code_hecho) %>%
  summarise(total_reclutamientos = n()) %>%
  arrange(desc(total_reclutamientos)) %>%
  slice_head(n = 5)

# 2. Leer archivo CSV de municipios
municipios_dane <- read_delim("C:/Datos_limpios/CodigosDaneDepartamentoMunicipio/Departamentos_Municipios.csv",
                              delim = ";", show_col_types = FALSE)

# 3. Limpiar código DANE del municipio
municipios_dane <- municipios_dane %>%
  mutate(`CÓDIGO DANE DEL MUNICIPIO` = gsub("\\.", "", `CÓDIGO DANE DEL MUNICIPIO`),
         `CÓDIGO DANE DEL MUNICIPIO` = trimws(`CÓDIGO DANE DEL MUNICIPIO`),
         `CÓDIGO DANE DEL MUNICIPIO` = as.numeric(`CÓDIGO DANE DEL MUNICIPIO`))

# 4. Join para obtener nombres de municipios
top_municipios_nombres <- top_municipios %>%
  left_join(municipios_dane, by = c("muni_code_hecho" = "CÓDIGO DANE DEL MUNICIPIO"))

# 5. Graficar resultados
ggplot(top_municipios_nombres, aes(x = reorder(MUNICIPIO, -total_reclutamientos), y = total_reclutamientos, fill = DEPARTAMENTO)) +
  geom_bar(stat = "identity") +
  labs(
    title = "Top 5 municipios con más reclutamientos  (1985–2018)",
    x = "Municipio",
    y = "Cantidad de reclutamientos"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
##################################Pregunta 5#########################################################
#De que edad a que edad han estado las personas mas afectadas (mayor frecuencia absoluta del intervalo)
  #a. la infancia van de 0 a 14, los adolescentes de 15 a 19,  adultez desde los 20 en adelante


# Contar la frecuencia absoluta de cada categoría de edad
conteo_edades <- datos %>%
  count(edad_categoria, sort = TRUE)

# Ver las primeras filas para encontrar la categoría con más reclutamientos
print(conteo_edades)

# Si deseas mostrar solo la categoría más frecuente (el modo)
edad_mas_afectada <- conteo_edades %>%
  slice_max(n, n = 1)

print(edad_mas_afectada)

ggplot(conteo_edades, aes(x = reorder(edad_categoria, -n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Frecuencia de reclutamientos por categoría de edad",
       x = "Rango de Edad",
       y = "Cantidad dereclutamientos") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

##################################Pregunta 6#########################################################
#Que tipo de etnias existen y cuales han sido las más afectadas

# 1. Agrupar por etnia y calcular porcentaje preciso
conteo_etnias <- datos %>%
  filter(!is.na(etnia) & etnia != "") %>%
  count(etnia, sort = TRUE) %>%
  mutate(
    porcentaje = n / sum(n),
    etiqueta = paste0(etnia, " (", percent(porcentaje, accuracy = 0.001), ")")  # Precisión de 0.001%
  )

# 2. Tabla de resumen con porcentaje con 3 decimales
tabla_etnias <- conteo_etnias %>%
  mutate(porcentaje = round(porcentaje * 100, 3)) %>%
  rename(
    "Grupo Étnico" = etnia,
    "Número de reclutamientos" = n,
    "Porcentaje (%)" = porcentaje
  )

# Mostrar tabla en consola
kable(tabla_etnias, format = "markdown", align = "c")

# 3. Diagrama de pastel con etiquetas precisas
ggplot(conteo_etnias, aes(x = "", y = n, fill = etnia)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  geom_text(aes(label = etiqueta), position = position_stack(vjust = 0.5), size = 3) +
  labs(
    title = "Distribución de reclutamientos por grupo étnico (Pastel)",
    fill = "Etnia"
  ) +
  theme_void() +
  theme(legend.position = "none")

# 4. Diagrama de barras con porcentaje más exacto
ggplot(conteo_etnias, aes(x = reorder(etnia, -n), y = n, fill = etnia)) +
  geom_col() +
  geom_text(aes(label = percent(porcentaje, accuracy = 0.001)), vjust = -0.5) +
  labs(
    title = "Número de reclutamientos por grupo étnico (Barras)",
    x = "Grupo Étnico",
    y = "Número de reclutamientos"
  ) +
  theme_minimal() +
  theme(legend.position = "none") +
  ylim(0, max(conteo_etnias$n) * 1.1)
  #a. Cuantos casos estan asociados con desplazamiento forzado (relacion de la columna is_forced_dis)
##################################Pregunta 7#########################################################
#¿Qué guerrilla es la que está afectando más a estos ciudadanos?

# 1. Contar casos por guerrilla (columna p_str)
conteo_guerrilla <- datos %>%
  filter(!is.na(p_str) & p_str != "") %>%
  count(p_str, sort = TRUE)

# 2. Mostrar tabla con conteo total por guerrilla
print(conteo_guerrilla)

# 3. Graficar top 10 guerrillas que más afectan (por número de casos)
top10_guerrilla <- head(conteo_guerrilla, 10)

ggplot(top10_guerrilla, aes(x = reorder(p_str, n), y = n, fill = p_str)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(
    title = "Guerrillas que más afectan a los ciudadanos (reclutamiento) ",
    x = "Guerrilla",
    y = "Número de casos"
  ) +
  theme_minimal()
##################################Pregunta 8#########################################################
#En un promedio general, que se ven mas afectados, los hombres o las mujeres?

#Contar reclutamientos por sexo
conteo_sexo <- datos %>%
  count(sexo)

#Calcular porcentaje para cada grupo
conteo_sexo <- conteo_sexo %>%
  mutate(porcentaje = round(100 * n / sum(n), 1),
         etiqueta = paste0(sexo, " (", porcentaje, "%)"))

#Crear gráfico de pastel con ggplot2
ggplot(conteo_sexo, aes(x = "", y = n, fill = sexo)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y") +
  labs(title = "Proporción de reclutamientos por sexo") +
  theme_void() +  # Elimina ejes y fondo
  geom_text(aes(label = etiqueta), position = position_stack(vjust = 0.5)) +
  scale_fill_manual(values = c("HOMBRE" = "steelblue", "MUJER" = "salmon"))


##################################Pregunta 9#########################################################
#¿Existen meses del año con picos recurrentes de víctimas? (osea hacer el analisis de los meses desde el 85 al 2018 donde se han presentado mas delitos (los meses mas movidos )

# 1. Extraer año y mes desde la variable yymm_hecho
datos <- datos %>%
  mutate(
    anio = as.integer(substr(yymm_hecho, 1, 4)),
    mes = as.integer(substr(yymm_hecho, 5, 6))
  ) %>%
  filter(anio >= 1985, anio <= 2018, mes >= 1, mes <= 12)

# 2. Contar víctimas por año y mes
conteo_mes_anio <- datos %>%
  group_by(anio, mes) %>%
  summarise(casos = n(), .groups = "drop")

# 3. Convertir número de mes a nombre del mes
conteo_mes_anio <- conteo_mes_anio %>%
  mutate(mes_nombre = factor(month.abb[mes], levels = rev(month.abb)))

# 4. Crear heatmap
ggplot(conteo_mes_anio, aes(x = anio, y = mes_nombre, fill = casos)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c(option = "inferno") +
  labs(
    title = "Mapa de calor de víctimas de reclutamiento por mes y año (1985–2018)",
    x = "Año",
    y = "Mes",
    fill = "Número de víctimas"
  ) +
  theme_minimal()
##################################Pregunta 10#########################################################
 #¿En cuales departamentos se vieron   más afectados infancia/adolescencia//adultez de cada problematica?



# FILTROS Y ORGANIZACION
df_infancia <- datos %>%
  filter(edad_jep == "INFANCIA") %>%
  mutate(
    dept_code_hecho = sprintf("%02d", as.integer(dept_code_hecho))
  )

df_adolecencia <- datos %>%
  filter(edad_jep == "ADOLESCENCIA") %>%
  mutate(
    dept_code_hecho = sprintf("%02d", as.integer(dept_code_hecho))
  )

df_adultez <- datos %>%
  filter(edad_jep == "ADULTEZ") %>%
  mutate(
    dept_code_hecho = sprintf("%02d", as.integer(dept_code_hecho))
  )

# Mapa código → nombre de departamento
dept_lookup <- c(
  "91" = "Amazonas",       "05" = "Antioquia",    "81" = "Arauca",
  "08" = "Atlántico",      "11" = "Bogotá D.C.",   "13" = "Bolívar",
  "15" = "Boyacá",         "17" = "Caldas",        "18" = "Caquetá",
  "85" = "Casanare",       "19" = "Cauca",         "20" = "Cesar",
  "27" = "Chocó",          "23" = "Córdoba",       "25" = "Cundinamarca",
  "94" = "Guainía",        "95" = "Guaviare",      "41" = "Huila",
  "44" = "La Guajira",     "47" = "Magdalena",     "50" = "Meta",
  "52" = "Nariño",         "54" = "Norte de Santander",
  "86" = "Putumayo",       "63" = "Quindío",       "66" = "Risaralda",
  "88" = "San Andrés y Providencia",
  "68" = "Santander",      "70" = "Sucre",         "73" = "Tolima",
  "76" = "Valle del Cauca","97" = "Vaupés",        "99" = "Vichada"
)


df_infancia <- df_infancia %>%
  mutate(dept_nombre = dept_lookup[dept_code_hecho])


resumen_infancia <- df_infancia %>%
  group_by(dept_nombre) %>%
  summarise(n_victimas = n(), .groups = "drop")

ggplot(resumen_infancia, aes(x = dept_nombre, y = n_victimas)) +
  geom_col(fill = "#D53E4F") +
  labs(
    title = "Victimas (reclutamiento) de reclutamiento en la categoria de INFANCIA por departamento",
    x     = "Departamento",
    y     = "Número de víctimas (INFANCIA)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )


df_adolecencia <- df_adolecencia %>%
  mutate(dept_nombre = dept_lookup[dept_code_hecho])


resumen_adolecencia <- df_adolecencia %>%
  group_by(dept_nombre) %>%
  summarise(n_victimas = n(), .groups = "drop")

ggplot(resumen_adolecencia, aes(x = dept_nombre, y = n_victimas)) +
  geom_col(fill = "#D53E4F") +
  labs(
    title = "Victimas (reclutamiento) en la categoria de ADOLESCENCIA por departamento",
    x     = "Departamento",
    y     = "Número de víctimas (ADOLESCENCIA)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )


df_adultez <- df_adultez %>%
  mutate(dept_nombre = dept_lookup[dept_code_hecho])


resumen_adultez <- df_adultez %>%
  group_by(dept_nombre) %>%
  summarise(n_victimas = n(), .groups = "drop")

ggplot(resumen_adultez, aes(x = dept_nombre, y = n_victimas)) +
  geom_col(fill = "#D53E4F") +
  labs(
    title = "Victimas (reclutamiento) de reclutamiento en la categoria de ADULTEZ por departamento",
    x     = "Departamento",
    y     = "Número de víctimas (Adultez)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )





##################################Pregunta 11#########################################################
#¿La distribución de las edades esta sesgada mas a la parte de Infacncia o adultos?

datos <- datos %>%
  filter(!is.na(edad_categoria)) %>%
  mutate(edad_media = case_when(
    str_detect(edad_categoria, "\\d+-\\d+") ~ {
      as.numeric(str_extract(edad_categoria, "^\\d+")) +
        (as.numeric(str_extract(edad_categoria, "\\d+$")) -
           as.numeric(str_extract(edad_categoria, "^\\d+"))) / 2
    },
    edad_categoria == "5-sep" ~ 7,       # Aprox 5-9 años
    edad_categoria == "oct-14" ~ 11,     # Aprox 8-14 años
    edad_categoria == "95\\+" ~ 97.5,    # Valor estimado para 95+
    TRUE ~ NA_real_
  ))

ggplot(datos, aes(x = edad_media)) +
  geom_histogram(aes(y = ..density..), bins = 20, fill = "steelblue", alpha = 0.6) +
  geom_density(color = "red", size = 1.2, adjust = 4) +  # ¡Más suave todavía!
  labs(title = "Distribución de edades de víctimas de reclutamiento",
       x = "Edad (estimada)",
       y = "Densidad") +
  theme_minimal()

##################################Pregunta 12#########################################################
#Si conviertes edad categoría a numérica, ¿cuál es la edad promedio de las víctimas?
  #a. en promedio, que edades han sido afectadas
  #c. varianza y desviacion estandar
  #d. Aplicando los cuartiles, ¿que podemos deducir?
  #e. y su sesgo?
  #f. que hay de su kurtosis?

# Tabla de frecuencias a partir de 'edad_categoria'
# Corregir la categoría "95+" para que sea tratada como "95-100"
datos <- datos %>%
  mutate(edad_categoria = ifelse(edad_categoria == "95+", "95-100", edad_categoria))

# Tabla de frecuencias
tabla <- datos %>%
  count(edad_categoria) %>%
  rename(Frecuencia = n) %>%
  mutate(
    Limites = strsplit(as.character(edad_categoria), "-"),
    Lim_inf = as.numeric(sapply(Limites, `[`, 1)),
    Lim_sup = as.numeric(sapply(Limites, `[`, 2)),
    Marca_clase = (Lim_inf + Lim_sup) / 2
  ) %>%
  arrange(Lim_inf) %>%
  mutate(
    Frec_acum = cumsum(Frecuencia),
    Frec_rel = Frecuencia / sum(Frecuencia),
    Frec_rel_acum = cumsum(Frec_rel)
  )

# Mostrar tabla resultante
print(tabla)

# Media
media <- sum(tabla$Marca_clase * tabla$Frecuencia) / sum(tabla$Frecuencia)
cat("Media:", round(media, 2), "\n")

# Moda
moda <- tabla$Marca_clase[which.max(tabla$Frecuencia)]
cat("Moda:", moda, "\n")

# Mediana
N <- sum(tabla$Frecuencia)
N_mitad <- N / 2
fila_mediana <- which(tabla$Frec_acum >= N_mitad)[1]
L_i <- tabla$Lim_inf[fila_mediana]
F_a <- ifelse(fila_mediana == 1, 0, tabla$Frec_acum[fila_mediana - 1])
f_i <- tabla$Frecuencia[fila_mediana]
h <- tabla$Lim_sup[fila_mediana] - tabla$Lim_inf[fila_mediana]
mediana <- L_i + ((N_mitad - F_a) / f_i) * h
cat("Mediana:", round(mediana, 2), "\n")

# Varianza y desviación estándar
varianza <- sum(tabla$Frecuencia * (tabla$Marca_clase - media)^2) / (N - 1)
desviacion <- sqrt(varianza)
cat("Varianza:", round(varianza, 2), "\n")
cat("Desviación estándar:", round(desviacion, 2), "\n")

# Cuartiles
# Q1
pos_Q1 <- N / 4
fila_Q1 <- which(tabla$Frec_acum >= pos_Q1)[1]
L_Q1 <- tabla$Lim_inf[fila_Q1]
F_Q1 <- ifelse(fila_Q1 == 1, 0, tabla$Frec_acum[fila_Q1 - 1])
f_Q1 <- tabla$Frecuencia[fila_Q1]
h_Q1 <- tabla$Lim_sup[fila_Q1] - tabla$Lim_inf[fila_Q1]
Q1 <- L_Q1 + ((pos_Q1 - F_Q1) / f_Q1) * h_Q1

# Q3
pos_Q3 <- 3 * N / 4
fila_Q3 <- which(tabla$Frec_acum >= pos_Q3)[1]
L_Q3 <- tabla$Lim_inf[fila_Q3]
F_Q3 <- ifelse(fila_Q3 == 1, 0, tabla$Frec_acum[fila_Q3 - 1])
f_Q3 <- tabla$Frecuencia[fila_Q3]
h_Q3 <- tabla$Lim_sup[fila_Q3] - tabla$Lim_inf[fila_Q3]
Q3 <- L_Q3 + ((pos_Q3 - F_Q3) / f_Q3) * h_Q3

IQR <- Q3 - Q1
cat("Q1:", round(Q1, 2), "\n")
cat("Q3:", round(Q3, 2), "\n")
cat("IQR:", round(IQR, 2), "\n")

# Asimetría
asimetria <- sum(tabla$Frecuencia * (tabla$Marca_clase - media)^3) / (N * desviacion^3)
cat("Asimetría:", round(asimetria, 4), "\n")

# Curtosis
curtosis <- (sum(tabla$Frecuencia * (tabla$Marca_clase - media)^4) / (N * desviacion^4)) - 3
cat("Curtosis:", round(curtosis, 4), "\n")

# Histograma basado en frecuencias por categoría de edad
ggplot(tabla, aes(x = factor(edad_categoria, levels = tabla$edad_categoria), y = Frecuencia)) +
  geom_bar(stat = "identity", fill = "skyblue", color = "black") +
  labs(
    title = "Histograma de reclutamientos por categoría de edad",
    x = "Categoría de edad",
    y = "Frecuencia"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



# Boxplot de bigotes
vector_edades <- rep(tabla$Marca_clase, times = tabla$Frecuencia)
df_box <- data.frame(age = vector_edades)
ggplot(df_box, aes(x = factor(1), y = age)) +
  geom_boxplot(fill = "#69b3a2", color = "black", outlier.colour = "red") +
  labs(
    title = "Boxplot de edades reclutamiento (punto medio de intervalos)",
    y     = "Edad aproximada",
    x     = NULL
  ) +
  scale_x_discrete(name = NULL) +      # fuerza un eje discreto con un solo nivel
  theme_minimal() +
  theme(
    axis.text.x  = element_blank(),    # quita las etiquetas del eje X
    axis.ticks.x = element_blank()     # quita los ticks del eje X
  )

