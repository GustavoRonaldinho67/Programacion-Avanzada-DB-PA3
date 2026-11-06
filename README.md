# 🛒 Proyecto NovaMarket - Evaluación Aplicada (PA3)

![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)
![ISIL](https://img.shields.io/badge/ISIL-Curso_30627-00529B?style=for-the-badge)

**Curso:** 30627 - Programación Avanzada de Base de Datos  
**Institución:** ISIL - Educación Superior  
**Docente:** Wilder Julio Espinoza Bravo  
**Evaluación:** Proceso de Aprendizaje 3 (PA3)  
**Enlace al Repositorio en GitHub:** [GitHUB GRUPO 3](https://github.com/GustavoRonaldinho67/Programacion-Avanzada-DB-PA3)

---

## 👥 Integrantes y Roles del Equipo

| Integrante                      | Usuario GitHub                                                 | Rol y Participación en PA3                                                                                       |
| :------------------------------ | :------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------- |
| **Gustavo Muñoz Izquierdo**     | [@GustavoRonaldinho67](https://github.com/GustavoRonaldinho67) | **Dev Backend:** Análisis, diseño, requerimientos y pseudocódigo del proceso de validación de pedidos (Act. 1).  |
| **Mauricio Rojas Arias**        | [@chunchope](https://github.com/chunchope)                     | **Dev Backend:** Desarrollo de Procedimiento Almacenado, control de parámetros OUTPUT y valores RETURN (Act. 2). |
| **Leandro Henostroza Minaya**   | [@Lenvisual](https://github.com/Lenvisual)                     | _(Rol y Actividad Pendiente de definir)_                                                                         |
| **Fernando Alcantara Valencia** | [@totomanxd321](https://github.com/totomanxd321)               | _(Rol y Actividad Pendiente de definir)_                                                                         |
| **Victor Aguilar de la Cruz**   | [@victordaniel2032](https://github.com/victordaniel2032)       | _(Rol y Actividad Pendiente de definir)_                                                                         |

---

## 🏢 Descripción del Problema Organizacional (Actividad 1)

**Contexto:** En NovaMarket, los clientes realizan pedidos de diferentes productos. Antes de registrar una venta, los usuarios de la aplicación cliente ejecutan validaciones repetitivas para comprobar que el cliente y el producto existan, y que haya suficiente stock en inventario.

**Problema:** Validar todas estas reglas de negocio desde la capa de la aplicación (Frontend) genera un tráfico excesivo hacia la base de datos (múltiples consultas select antes de un insert) y crea un riesgo de inconsistencia si diferentes aplicaciones implementan lógicas de validación distintas.

**Objetivo:** Se debe trasladar la lógica de registro de pedidos y validación de stock directamente al servidor de base de datos mediante Procedimientos Almacenados, evitando redundancias en la aplicación cliente.

### 📌 Flujo del Proceso y Arquitectura Cliente/Servidor

```text
[ ARQUITECTURA CLIENTE / SERVIDOR ]

 1. APLICACIÓN CLIENTE (Frontend)
    - Recibe: ClienteID, ProductoID, Cantidad, Canal, FechaPedido.
    - Envía los datos al Servidor a través de la red.
           │
           ▼ (Petición de Red)
 2. SERVIDOR DE BASE DE DATOS (SQL Server)
    - Ejecuta validaciones (Lógica de Negocio):
       ├─ ¿Cliente Existe? (No -> Mensaje Error)
       ├─ ¿Producto Existe? (No -> Mensaje Error)
       ├─ ¿Cantidad > 0? (No -> Mensaje Error)
       ├─ ¿Hay Stock Suficiente? (No -> Mensaje Error)
       └─ SÍ: Registra Pedido -> Registra Detalle -> Descuenta Stock.
    - Captura el ID de pedido generado y el stock sobrante.
           │
           ▼ (Respuesta de Red)
 3. APLICACIÓN CLIENTE (Frontend)
    - Lee las variables de SALIDA.
    - Muestra al usuario: "Pedido registrado correctamente" o el Mensaje de Error.
```

- **Justificación de la automatización:** Conveniene implementar esta lógica en el servidor porque asegura que todas las reglas se cumplan atómicamente. Se encapsulan las consultas en un solo viaje de red, mejorando enormemente el rendimiento y centralizando las políticas de negocio de la empresa.

---

## 💻 Desarrollo y Solución Propuesta (Actividad 2)

**Estrategia y Decisiones Adoptadas:**
En base al pseudocódigo de la Actividad 1, el equipo de QA implementó un **Procedimiento Almacenado de Mantenimiento (`usp_RegistrarPedido`)**. Se tomó la decisión de utilizar parámetros de distintos tipos para asegurar una correcta comunicación con el cliente, tal como dicta la sesión 9 del sílabo.

- **Parámetros de Entrada (`INPUT`):** `@ClienteID, @ProductoID, @Cantidad, @Canal, @FechaPedido`. Permiten que la aplicación cliente envíe los datos de la transacción.
- **Parámetros de Salida (`OUTPUT`):** `@NuevoPedidoID, @StockRestante, @Mensaje`. En lugar de retornar tablas completas, se devuelve únicamente la confirmación y los IDs requeridos. Esto ahorra memoria RAM en el servidor y ancho de banda en la red.
- **Valor de Retorno (`RETURN`):** Se devuelve `1` si el proceso finaliza con éxito. Si ocurre un fallo en alguna regla de negocio (ej. falta de stock), se devuelve código de error negativo (`-1, -2, -3, -4`). Esto permite que la aplicación cliente evalúe si la operación falló o no con un simple condicional lógico sin leer cadenas de texto.

---

## ⚙️ Cómo ejecutar o revisar el proyecto

Para reproducir las evidencias técnicas requeridas en la rúbrica, ejecute los scripts en el siguiente orden estricto dentro de SQL Server Management Studio (SSMS):

1.  Ejecutar el esquema base (`00_esquema_y_datos_base.sql`).
2.  Ejecutar el script de procedimientos y pruebas (`02_Actividad2_Procedimientos.sql`).
3.  Revisar en la consola de SSMS la pestaña "Resultados", donde se mostrarán tres cuadrículas de validación (Prueba 1, Prueba 2 y Prueba 3).

---

## 📸 Evidencias (Actividad 2)

> **📝 INSTRUCCIÓN PARA REVISIÓN DOCENTE:**
> Las siguientes evidencias demuestran la ejecución de casos exitosos y fallidos controlados mediante los parámetros de SALIDA y RETURN explicados previamente.

_Espacio reservado para Captura de Pantalla: Resultados de las 3 pruebas ejecutadas desde el script 01._
_(Insertar imagen aquí: `evidencias/02_Actividad2_Procedimientos.png`)_

---

## 📌 Conclusiones (Corte Parcial)

1.  **Validaciones Centralizadas:** Trasladar la lógica del cliente al servidor mediante un Procedimiento Almacenado elimina la posibilidad de que se registren pedidos con stock negativo o IDs huérfanos.
2.  **Optimización:** El uso de parámetros `OUTPUT` y valores de `RETURN` permite procesar transacciones rápidamente sin enviar _RecordSets_ pesados a través de la red, mejorando la interacción Cliente/Servidor de NovaMarket.

---

_Documentación elaborada para la evaluación PA3 - ISIL._
