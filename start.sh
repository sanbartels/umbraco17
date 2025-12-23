cat > start.sh << 'EOF'
#!/bin/bash
set -e

cd /app/project

if [ ! -f *.csproj ]; then
  echo "Creando nuevo proyecto Umbraco..."
  dotnet new umbraco -n UmbracoSite --force
  
  if [ -d "UmbracoSite" ]; then
    shopt -s dotglob
    mv UmbracoSite/* . 2>/dev/null || true
    rmdir UmbracoSite 2>/dev/null || true
  fi
fi

# Crear directorios necesarios para Umbraco
echo "Creando directorios necesarios..."
mkdir -p wwwroot/media
mkdir -p App_Data
mkdir -p umbraco/Data

echo "Restaurando dependencias..."
dotnet restore

echo "Iniciando Umbraco..."
dotnet watch run --no-restore
EOF

chmod +x start.sh