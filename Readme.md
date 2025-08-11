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

## Pasos de diagnóstico de fallo en deploy:
1. Revisar logs del pipeline Azure DevOps (Build / Deploy) — ver si imagen se subió al ACR y tag usado.
2. Verificar que la imagen exista en ACR: az acr repository show --name <ACR_NAME> --repository myapp --query "tags"
3. Obtener credenciales AKS y revisar pods:
   - az aks get-credentials -g my-aks-rg -n my-aks-cluster
   - kubectl get pods -n default
   - kubectl describe pod <pod-name> -n default
   - kubectl logs <pod-name> -n default --previous
   - kubectl get events -n default
4. Si kubectl describe muestra error de imagen (ImagePullBackOff): comprobar nombre/tag y permisos ACR/AKS (Aks needs pull permission).
   - Verificar imagePullSecrets o que ACR esté ligado al AKS (AKS ACR integration / role assignment to SP): az role assignment list --assignee <aks-sp-id> --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/<acr>
5. Si CrashLoopBackOff por error de aplicación (e.g., configuración, falta de env var, DB unreachable): ver kubectl logs para la excepción y ajustar config/secret/env.
6. Comprobar recursos (OOMKilled): kubectl describe pod → ver State / Last State / Reason.
7. Prueba local: ejecutar la imagen localmente para reproducir error: docker run --rm -e ENVIRONMENT=production myregistry.azurecr.io/myapp:<tag>
8. Corregir: rebuild de la imagen con fix → push → rerun pipeline → kubectl rollout restart deployment/myapp o kubectl set image.
