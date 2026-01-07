# Umbraco 17 CMS - Docker Development Environment

Este proyecto contiene una instalación de **Umbraco 17 CMS** configurada para ejecutarse en un entorno Docker **multiplataforma** (Linux, macOS, Windows) con **hot reload** y desarrollo en tiempo real.

Desarrollado por **IMERGI**.

## ✨ Características

-   ✅ **100% Multiplataforma**: Funciona en macOS (Intel/Apple Silicon), Linux y Windows
-   ✅ **Hot Reload**: `dotnet watch` configurado para recargar cambios automáticamente
-   ✅ **SQLite en Volúmenes Docker**: Base de datos aislada para evitar problemas de compatibilidad
-   ✅ **.NET 10**: Última versión del SDK de .NET
-   ✅ **Puerto 5001**: Evita conflictos con AirPlay Receiver en macOS
-   ✅ **Scripts helpers**: Verificación de requisitos, inicio automático y reset de BD

## 📋 Requisitos Previos

-   [Docker](https://www.docker.com/get-started) (versión 20.10 o superior)
-   [Docker Compose](https://docs.docker.com/compose/install/) (versión 2.0 o superior)

## 🚀 Inicio Rápido

### 1. Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd umbraco17
```

### 2. Verificar Requisitos (Opcional pero recomendado)

```bash
./check-requirements.sh
```

Este script verifica:

-   ✅ Docker instalado y corriendo
-   ✅ Docker Compose v2 disponible
-   ✅ Puerto 5001 libre

### 3. Iniciar el Contenedor

**Opción A: Script automático (Recomendado)**

```bash
./dev-start.sh
```

**Opción B: Manual**

```bash
docker compose up --build
```

El contenedor se iniciará y Umbraco estará disponible en:

**🌐 http://localhost:5001**

> **Nota sobre el puerto**: Se usa el puerto 5001 en lugar de 5000 porque macOS usa el 5000 para AirPlay Receiver por defecto.

### 4. Configuración Inicial de Umbraco

La **primera vez** que accedas a http://localhost:5001, verás el asistente de instalación:

1. **Crear usuario administrador**: Ingresa nombre, email y contraseña
2. **Base de datos**: Ya está configurada (SQLite), solo click en "Install"
3. **Completar**: Una vez instalado, accedé al backoffice en **http://localhost:5001/umbraco**

> **Tiempo de espera**: El primer arranque puede tardar 30-60 segundos mientras compila el proyecto y arranca Umbraco. Los siguientes arranques serán más rápidos.

### 5. Resetear Base de Datos (Cuando sea necesario)

Si necesitás empezar de cero o tuviste problemas con la BD:

```bash
./reset-db.sh
```

Este script limpiará:

-   Volúmenes de Docker (base de datos y archivos media)
-   Archivos SQLite locales si existen

Luego podés volver a ejecutar `./dev-start.sh` o `docker compose up --build`

## 📁 Estructura del Proyecto

```
umbraco17/
├── Dockerfile              # Imagen Docker con .NET 10 SDK y Umbraco
├── docker-compose.yml      # Configuración de servicios Docker
├── .dockerignore          # Archivos a ignorar en build (evita conflictos multiplataforma)
├── check-requirements.sh  # Script para verificar requisitos (Docker, Compose, etc.)
├── dev-start.sh           # Script helper para iniciar (con verificación de puertos)
├── reset-db.sh            # Script para resetear BD y volúmenes
├── start.sh               # Script interno del contenedor
├── Umbraco.sln            # Solución de Visual Studio
└── src/                   # Código fuente de la aplicación (montado como volumen)
    ├── UmbracoSite.csproj # Proyecto .NET
    ├── Program.cs         # Punto de entrada de la aplicación
    ├── appsettings.json   # Configuración principal
    ├── appsettings.Development.json
    ├── App_Data/          # ⚠️ MONTADO COMO VOLUMEN DOCKER (no en filesystem host)
    ├── Models/            # Modelos generados
    ├── Views/             # Vistas Razor
    ├── wwwroot/media/     # ⚠️ MONTADO COMO VOLUMEN DOCKER (no en filesystem host)
    └── umbraco/           # Archivos del CMS
```

> **Importante**: `App_Data` y `wwwroot/media` están montados como **volúmenes Docker** y NO como directorios del host. Esto evita problemas de permisos y compatibilidad entre Linux/macOS/Windows.

## ⚙️ Configuración

### Base de Datos

El proyecto utiliza **SQLite** como base de datos, configurada en `src/appsettings.json`:

```json
"ConnectionStrings": {
  "umbracoDbDSN": "Data Source=App_Data/Umbraco.sqlite.db;Cache=Shared;Foreign Keys=True;Pooling=True",
  "umbracoDbDSN_ProviderName": "Microsoft.Data.Sqlite"
}
```

**Arquitectura de almacenamiento multiplataforma:**

-   La base de datos vive en un **volumen Docker** (`umbraco-data`) montado en `/app/project/App_Data/`
-   Los archivos media viven en otro **volumen Docker** (`umbraco-media`) montado en `/app/project/wwwroot/media/`
-   Tu código fuente en `src/` se monta como volumen con flag `:delegated` para mejor performance en macOS
-   Los directorios `bin/` y `obj/` NO se montan en volúmenes separados para evitar conflictos de compilación

**¿Por qué volúmenes Docker y no filesystem local?**

Esto evita problemas críticos de:

-   **Permisos**: Linux (contenedor) vs macOS/Windows (host) usan diferentes sistemas de permisos
-   **Compatibilidad binaria**: SQLite creado en Linux x86_64 puede no funcionar en macOS ARM64 (Apple Silicon)
-   **File locking**: SQLite usa locks que funcionan diferente en cada filesystem
-   **Performance**: Volúmenes Docker son mucho más rápidos que compartir archivos con el host en macOS

> **Nota**: No podrás abrir el archivo SQLite directamente con herramientas en tu Mac (DB Browser, etc.). Para inspeccionar la BD, usá comandos dentro del contenedor o exportá/importá datos.

### Variables de Entorno

El contenedor está configurado con las siguientes variables de entorno:

-   `ASPNETCORE_ENVIRONMENT=Development`
-   `ASPNETCORE_URLS=http://+:5001`
-   `Umbraco__CMS__Global__UseHttps=false`

### Puertos

-   **Puerto 5001**: Aplicación Umbraco (HTTP)
    -   Cambio de 5000 → 5001 para evitar conflicto con AirPlay Receiver en macOS

### Hot Reload y Desarrollo

El proyecto usa `dotnet watch` que detecta cambios en:

-   Archivos `.cs` (C#)
-   Archivos `.cshtml` (Razor Views)
-   Archivos `.css` y `.js`

Los cambios se aplican **automáticamente sin reiniciar** el contenedor (hot reload).

> **Nota**: Cambios en `appsettings.json` o `.csproj` requieren reiniciar el contenedor: `docker compose restart umbraco`

## 🔧 Problemas Comunes y Soluciones

### Error 500 al abrir http://localhost:5001

Si ves un error 500, puede haber varias causas:

**Causa 1: Base de datos no se creó correctamente**

1. **Verificar logs**:

    ```bash
    docker compose logs umbraco | grep -i "unable to open database"
    ```

2. **Si ves "unable to open database file"**: Significa que SQLite no puede crear la BD

3. **Solución**: Asegurar que el Dockerfile tiene las dependencias SQLite:
    ```bash
    docker compose down
    docker compose up --build
    ```

**Causa 2: Volúmenes corruptos**

Si ya funcionaba antes pero ahora no:

```bash
./reset-db.sh
docker compose up --build
```

### El contenedor se reinicia constantemente

Si el contenedor entra en un loop de reinicios:

1. **Ver logs completos**:

    ```bash
    docker compose logs --tail=100 umbraco
    ```

2. **Buscar errores de compilación**: Si hay errores de build (MSBxxxx), probablemente hay archivos corruptos en `bin/obj`

3. **Solución**: Limpiar y reconstruir
    ```bash
    docker compose down
    rm -rf src/bin src/obj
    docker compose up --build
    ```

### Error "AssemblyName" o problemas con UmbracoSite

Este proyecto usa `AssemblyName=UmbracoApp` en el `.csproj` para evitar conflictos con directorios. **No cambies este valor**.

Si ves errores relacionados con `UmbracoSite` vs `UmbracoApp`:

```bash
docker compose down
rm -rf src/bin src/obj
docker compose up --build
```

### El puerto 5001 está ocupado

Si ves un error de puerto ocupado:

```bash
# Opción 1: Usar el script automático (detecta y mata el proceso)
./dev-start.sh

# Opción 2: Manual - Ver qué está usando el puerto
lsof -i :5001

# Opción 3: Manual - Matar el proceso
lsof -ti :5001 | xargs kill -9
```

### La base de datos está corrupta o tiene errores

Si tuviste problemas al migrar desde Linux o querés empezar de cero:

```bash
# Resetear TODO (BD + media)
./reset-db.sh

# Luego volver a iniciar
./dev-start.sh
```

### Problemas de permisos en macOS

Si ves errores relacionados con permisos en `App_Data` o `wwwroot/media`, asegurate de que los volúmenes Docker existan:

```bash
docker volume ls | grep umbraco
```

Deberías ver:

-   `umbraco17_umbraco-data`
-   `umbraco17_umbraco-media`
-   `umbraco17_umbraco-packages`

Si no existen, Docker los creará automáticamente al hacer `docker-compose up`.

### Ver logs del contenedor

```bash
# Ver logs en vivo
docker compose logs -f

# Ver logs del servicio umbraco específicamente
docker compose logs -f umbraco
```

### Ejecutar comandos dentro del contenedor

```bash
# Abrir bash dentro del contenedor
docker compose exec umbraco bash

# Ejecutar comandos .NET
docker compose exec umbraco dotnet --version
docker compose exec umbraco dotnet build
```

### Limpiar todo y empezar de cero

Si querés destruir TODO (contenedores, volúmenes, imágenes):

```bash
# ADVERTENCIA: Esto borra TODO
docker compose down -v --rmi all

# Luego reconstruir
docker compose up --build
```

### Hot reload no está funcionando

Si hacés cambios en archivos `.cs` o `.cshtml` pero no se reflejan:

1. **Verificar que dotnet watch esté corriendo**:

    ```bash
    docker compose logs umbraco | grep "dotnet watch"
    ```

    Deberías ver: `dotnet watch 🔥 Hot reload enabled`

2. **Ver si detectó el cambio**:

    ```bash
    docker compose logs -f umbraco
    ```

    Cuando guardás un archivo, deberías ver logs de rebuild

3. **Si no funciona**: Reiniciar el contenedor
    ```bash
    docker compose restart umbraco
    ```

### Cambié appsettings.json pero no se aplica

Los cambios en archivos de configuración NO se detectan con hot reload. Necesitás:

```bash
docker compose restart umbraco
```

### El build es muy lento en macOS

Esto es normal en la primera compilación. Para mejorar performance:

1. **Asegurate de tener suficiente memoria asignada a Docker** (al menos 4GB)

    - Docker Desktop → Settings → Resources → Memory

2. **Los builds subsiguientes serán mucho más rápidos** gracias a la caché

3. **El volumen usa flag `:delegated`** que mejora performance en macOS

## 🏗️ Notas Técnicas de la Implementación

### Estructura de Volúmenes

```
Docker Volumes:
├── umbraco-data        → /app/project/App_Data/        (Base de datos SQLite)
├── umbraco-media       → /app/project/wwwroot/media/   (Archivos media)
└── umbraco-packages    → /root/.nuget/packages/        (Caché de NuGet)

Bind Mounts:
└── ./src               → /app/project                  (Código fuente - editable)
```

Los directorios `bin/` y `obj/` se generan dentro del contenedor y **NO se montan** desde el host para evitar conflictos de compilación.

## 📚 Recursos

-   [Documentación oficial de Umbraco](https://docs.umbraco.com/)
-   [Umbraco en Docker - Mejores prácticas](https://umbraco.com/blog/running-umbraco-in-docker/)
-   [.NET Hot Reload](https://aka.ms/dotnet/hot-reload)
-   [Docker Compose v2 Documentation](https://docs.docker.com/compose/)

**Desarrollado por IMERGI** | 2026
