#INTRODUCCION A LA ESTADISTICA Y ANALISIS DE DATOS
# 1.CALCULOS ESTADISTICOS BASICOS.

#  a.***Almacenar los datos en el vector solicitado***
carga_cpu <- c(82, 85, 89, 84, 30, 88, 91, 86, 95, 25)

#  b.***calculos estadisticos de forma individual***

# 1. calculo de la media aritmetica.
media_resultado <- mean(carga_cpu)
print(media_resultado)

# 2. calculo de la mediana.
mediana_resultado <- median(carga_cpu)
print(mediana_resultado)

# 3. calculo de la varianza muestral.
varianza_resultado <- var(carga_cpu)
print(varianza_resultado)

# 4. calculo del rango intercuartilio.
iqr_resultado <- IQR(carga_cpu)
print(iqr_resultado)


#EVIDENCIAS EXTRAS
# resumen estadistico completo de la variable
summary(carga_cpu)
#generacion del grafico de caja (boxplot) para ver los varibles bajos(atipicos)
boxplot(carga_cpu,
        main = "analisis de carga de cpu en contenedores",
        ylab = "porcentaje de uso (%)",
        col = "lightblue",
        border = "darkblue")


# P2. aplicacion de funciones estadisticas predefinidas.

# 1. Configurar la semilla aleatoria para reproducibilidad
set.seed(456)

# 2. Generar simulacion de 100 tiempos de despliegue (distribucion normal)
tiempos_simulados <- rnorm(n = 100, mean = 12, sd = 2.5)

# 3. calcular la probabilidad exacta de tomar MAS de 15 minutos
# usamos lower.tail = FALSE porque buscamos el area a la derecha (mas de...)
prob_mas_15 <- pnorm(q = 15, mean = 12, sd = 2.5, lower.tail = FALSE)
prob_mas_15

# 4. calcular la probabilidad de tomar entre 10 y 14 minutos
# restamos la probabilidad acumulada hasta 14 menos la acumulada hasta 10
prob_entre_10_14 <- pnorm(q = 14, mean = 12, sd = 2.5) - pnorm(q = 10, mean = 12, sd = 2.5)
prob_entre_10_14

# 5. determinar el tiempo limite del 10% de los despliegues mas rapidos (percentil 10)
# usamos qnorm para buscar el tiempo exacto que acumula el 10% (0.10) a la izquierda
tiempo_limite_10 <- qnorm(p = 0.10, mean = 12, sd = 2.5)
tiempo_limite_10


# P3. Analisis exploratoria de datos utilizados en R.
# crear el vector con los datos de los incidentes de ciberseguridad
intentos_fallidos <- c(14, 18, 22, 15, 12, 45, 19, 21, 16, 50, 13, 17, 24, 20, 11)

# 1. comando para obtener el resumen estadistico rapido (summary)
summary(intentos_fallidos)

# 2. codigo para generar el diagrama de caja (boxplot)
boxplot(intentos_fallidos,
        main = "diagrama de caja de intentos fallidos",
        ylab = "intentos por hora",
        col = "lightblue")

# 3. indexacion logica para identificar las horas con ataque critico (> 30)
horas_criticas <- intentos_fallidos[intentos_fallidos > 30]

# contar cuantas horas fueron criticas
cantidad_horas_criticas <- length(horas_criticas)
cantidad_horas_criticas

# calcular que porcentaje representan del total analizando (15 horas)
porcentaje_critico <- (cantidad_horas_criticas / length(intentos_fallidos)) * 100
porcentaje_critico



# P4. Calculos estadisticos en conjuntos de datos reales.

# 1. comando para importar el archivo y limpiar datos omitidos
datos_redes <- read.csv("redes.csv")
datos_limpios <- na.omit(datos_redes)

# 2. comando para calcular la correlacion de pearson
correlacion <- cor(datos_limpios$anchobanda, datos_limpios$latencia, method = "pearson")

# 3. comando para ajustar el modelo de regresion lineal y revisarintercepto y pendiente
modelo_redes <- lm(Latencia ~ AnchoBanda, data = datos_limpios)
summary(modelo_redes)


# P5----RETO DE INTEGRACION AVANZADA-----
volumen_X <- c(2, 4, 6, 8, 10, 12)
tiempo_Y <- c(15, 28, 42, 53, 68, 81)
datos_ia <- data.frame(Dataset = volumen_X, Tiempo = tiempo_Y)

# paso 1: correlacion
correlacion_ia <- cor(datos_ia$Dataset, datos_ia$Tiempo, method = "pearson")
correlacion_ia

# paso 2: regresion
modelo_ia <- lm(Tiempo ~ Dataset, data = datos_ia)
summary(modelo_ia)

# paso 3: prediccion
nuevo_caso <- data.frame(Dataset = 18)
prediccion_18 <- predict(modelo_ia, newdata = nuevo_caso)
prediccion_18

# paso 4: probabilidad
media_mu <- as.numeric(prediccion_18)
probabilidad_falla <- pnorm(130, mean = media_mu, sd = 3.5, lower.tail = FALSE)
probabilidad_falla


        
