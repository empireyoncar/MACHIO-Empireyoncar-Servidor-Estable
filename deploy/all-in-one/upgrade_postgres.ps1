# ==========================================
# Script: upgrade_postgres.ps1
# Autor: ChatGPT (para empir)
# Función: Actualiza el contenedor PostgreSQL a una nueva versión
# ==========================================

# Configuración general
$containerName = "database"
$dbUser = "postgres"
$dbPassword = "admin"
$dbName = "openmu"
$newVersion = "18"   # puedes cambiarlo fácilmente más adelante
$backupFile = "backup.sql"

Write-Host "==> Creando respaldo de la base de datos actual..." -ForegroundColor Cyan
docker exec -t $containerName pg_dumpall -U $dbUser > $backupFile

if (!(Test-Path $backupFile)) {
    Write-Host "❌ No se creó el backup. Abortando." -ForegroundColor Red
    exit 1
}

Write-Host "==> Backup creado correctamente: $backupFile" -ForegroundColor Green

# Detener y eliminar contenedor viejo
Write-Host "==> Deteniendo y eliminando contenedor viejo..." -ForegroundColor Cyan
docker stop $containerName
docker rm $containerName

# Crear contenedor nuevo con PostgreSQL actualizado
Write-Host "==> Iniciando nuevo contenedor con PostgreSQL $newVersion..." -ForegroundColor Cyan
docker run -d `
  --name $containerName `
  -e POSTGRES_PASSWORD=$dbPassword `
  -e POSTGRES_USER=$dbUser `
  -e POSTGRES_DB=$dbName `
  -p 5433:5432 `
  -v dbdata:- dbdata18:/var/lib/postgresql
 `
  postgres:$newVersion

# Esperar unos segundos a que arranque
Start-Sleep -Seconds 10

# Restaurar el backup en la nueva base
Write-Host "==> Restaurando backup en el nuevo contenedor..." -ForegroundColor Cyan
Get-Content .\$backupFile | docker exec -i $containerName psql -U $dbUser -d $dbName

Write-Host "✅ Migración completada con éxito a PostgreSQL $newVersion" -ForegroundColor Green
Write-Host "---------------------------------------------"
Write-Host "Tu contenedor '$containerName' ahora usa PostgreSQL versión $newVersion"
Write-Host "---------------------------------------------"
