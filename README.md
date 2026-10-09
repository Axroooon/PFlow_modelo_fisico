# PFlow - Modelo Físico de Base de Datos

Este directorio contiene el modelo físico de la base de datos de PFlow. Su objetivo es definir la estructura técnica final para el flujo de atención en emergencias hospitalarias, detallando tipos de datos, restricciones y relaciones físicas preparadas para su implementación en un motor de base de datos relacional.

## Estructura del Diagrama

*   **Tablas:** 11 entidades principales implementadas como tablas relacionales (EstablecimientoSalud, Paciente, AtencionEmergencia, EventoAtencion, etc.).
*   **Columnas y Tipos de Datos:** Definición estricta de tipos de datos (`INT`, `VARCHAR`, `DATETIME`, `DATE`) optimizados para la naturaleza de cada atributo.
*   **Llaves y Restricciones:** Identificación explícita de Llaves Primarias (PK) autoincrementales, Llaves Foráneas (FK) relacionales, y restricciones de obligatoriedad (`Not Null`) y unicidad (`Unique`).
*   **Cardinalidad (Pata de Gallo):** Definida a través de las conexiones de llaves foráneas. El modelo detalla relaciones de 1 a N estrictas y relaciones opcionales de 0 a N (permitiendo valores `NULL` en llaves foráneas específicas como en `EventoAtencion` para áreas y camas no obligatorias).

## Archivos Incluidos

*   `modelo_fisico.erd`: Archivo fuente editable del diagrama que contiene el esquema JSON de las tablas y configuraciones.
*   `modelo_fisico.png`: Exportación gráfica del esquema físico para incluir en la documentación y el informe del proyecto final.

## Herramientas de Edición

Para visualizar, modificar o generar el código SQL a partir del archivo `.erd`, puedes utilizar:
*   **Visual Studio Code** instalando la extensión **ERD Editor** (por dineug).
*   La plataforma web compatible con el motor gráfico de ERD Editor.