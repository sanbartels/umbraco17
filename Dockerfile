# Usar la imagen SDK de .NET 10 para desarrollo
FROM mcr.microsoft.com/dotnet/sdk:10.0

WORKDIR /app

# Instalar la plantilla de Umbraco
RUN dotnet new install Umbraco.Templates

# Instalar dependencias necesarias para Umbraco
RUN apt-get update && apt-get install -y \
    libgdiplus \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Crear el script de inicio directamente en el contenedor
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
cd /app/project\n\
\n\
if [ ! -f *.csproj ]; then\n\
  echo "Creando nuevo proyecto Umbraco..."\n\
  dotnet new umbraco -n UmbracoSite --force\n\
  \n\
  if [ -d "UmbracoSite" ]; then\n\
    shopt -s dotglob\n\
    mv UmbracoSite/* . 2>/dev/null || true\n\
    rmdir UmbracoSite 2>/dev/null || true\n\
  fi\n\
  \n\
  # Modificar appsettings.Development.json para deshabilitar HTTPS en desarrollo\n\
  echo "Configurando appsettings para desarrollo sin HTTPS..."\n\
  cat > appsettings.Development.json << "APPSETTINGS_EOF"\n\
{\n\
  "Umbraco": {\n\
    "CMS": {\n\
      "Global": {\n\
        "UseHttps": false\n\
      },\n\
      "Security": {\n\
        "AllowPasswordReset": true\n\
      }\n\
    }\n\
  },\n\
  "Logging": {\n\
    "LogLevel": {\n\
      "Default": "Information",\n\
      "Microsoft.AspNetCore": "Warning"\n\
    }\n\
  }\n\
}\n\
APPSETTINGS_EOF\n\
  \n\
  # Modificar launchSettings.json\n\
  if [ -f "Properties/launchSettings.json" ]; then\n\
    echo "Deshabilitando auto-launch del navegador..."\n\
    cat > Properties/launchSettings.json << "LAUNCH_EOF"\n\
{\n\
  "$schema": "http://json.schemastore.org/launchsettings.json",\n\
  "profiles": {\n\
    "http": {\n\
      "commandName": "Project",\n\
      "dotnetRunMessages": true,\n\
      "launchBrowser": false,\n\
      "applicationUrl": "http://localhost:5000",\n\
      "environmentVariables": {\n\
        "ASPNETCORE_ENVIRONMENT": "Development"\n\
      }\n\
    }\n\
  }\n\
}\n\
LAUNCH_EOF\n\
  fi\n\
fi\n\
\n\
echo "Creando directorios necesarios..."\n\
mkdir -p wwwroot/media\n\
mkdir -p App_Data\n\
mkdir -p umbraco/Data\n\
\n\
echo "Restaurando dependencias..."\n\
dotnet restore\n\
\n\
echo "Iniciando Umbraco..."\n\
dotnet watch run --no-restore --urls "http://+:5000"\n' > /app/start.sh \
    && chmod +x /app/start.sh

# Exponer el puerto
EXPOSE 5000

# Variables de entorno - Solo HTTP
ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Development

CMD ["/bin/bash", "/app/start.sh"]