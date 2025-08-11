# Test DevOps
---
## Conexión segura a un servidor remoto mediante SSH con clave privada

### 1. Generar un par de claves SSH en tu máquina local
   ssh-keygen -t rsa -b 4096 -C "infra@XYZ.com"
   - Presionar Enter para aceptar ruta por defecto (~/.ssh/id_rsa)

### 2. Copiar la clave pública al servidor
   - Método rápido:
     ssh-copy-id user@ip_server:puerto
   - Método manual:
     a) En tu máquina local, mostrar tu clave pública:
        cat ~/.ssh/id_rsa.pub
     b) Copiar todo el contenido mostrado.
     c) Conectarte al servidor:
        ssh user@ip_server:puerto
     d) Abrir el archivo authorized_keys:
        vi ~/.ssh/authorized_keys
     e) Pegar el contenido de la clave pública en el archivo, guardar y salir (`Esc`, escribir `:wq` y presionar `Enter`).
        - Modo rapido -> echo "clave_publica" >> ~/.ssh/authorized_keys
     f) Ajustar permisos:
        chmod 600 ~/.ssh/authorized_keys

### 3. Probar conexión con clave
   ssh user@ip_server:puerto
   - No debe pedir contraseña

---

## Configuración del Pipeline
1. Crear un Service Connection en Azure DevOps:
   - **Azure Container Registry** (Docker@2).
   - **Azure Resource Manager** para AKS.
2. Configurar variables en el pipeline:
   - `containerRegistryServiceConnection`
   - `azureServiceConnection`
3. Guardar los secretos en **Library > Variable Groups**.

## Flujo CI/CD
- **Build:** Construye y sube la imagen al ACR.
- **Test:** Ejecuta las pruebas unitarias.
- **Deploy:** Aplica los manifests en AKS.

## Scripts
- `rotate_logs.sh`: Elimina logs antiguos manteniendo los últimos N.
- `check_pods.sh`: Verifica si hay pods en CrashLoopBackOff o no Running.

## Despliegue en AKS
```bash
az aks get-credentials --resource-group my-aks-rg --name my-aks-cluster
kubectl apply -f k8s/
