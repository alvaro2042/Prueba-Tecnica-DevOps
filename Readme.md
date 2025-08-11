# Test DevOps
---
## 1. Configurar un pipeline CI/CD en Azure DevOps (build, test y deploy a AKS)
   - Crear en Azure DevOps el proyecto y conectar el repositorio.
   - Crear Service Connections:
      a) ACR (para push/pull de imágenes).
      b) Azure Resource Manager (para ejecutar az aks / kubectl).
   - Definir variables y variable groups (registry, image name, aksResourceGroup, aksClusterName, namespace, cred IDs).
   - Añadir azure-pipelines.yml en la raíz que orqueste stages (Build → Test → Deploy) y que use los templates en pipelines/templates/.
   - Build stage: Docker build y push (task Docker@2), tag con $(Build.BuildId) o commit SHA.
   - Test stage: ejecutar pruebas unitarias (ej. npm ci && npm test) y fallar si no pasan.
   - Deploy stage: usar AzureCLI@2 para az aks get-credentials y kubectl set image o kubectl apply contra los manifiestos en k8s/, luego kubectl rollout status.
   - Asegurar permisos: asignar rol Pull al identity de AKS contra ACR o usar imagePullSecrets.
   - Probar pipeline en rama main y validar despliegue en AKS; ajustar timeouts/rollout strategy.
   - Documentar variables y cómo crear los service connections (en README).
---
## 2. Crear un script Bash para rotación de logs en Linux
   - Identificar directorio y patrón de logs (ej. /var/log/myapp/*.log).
   - Escribir scripts/rotate_logs.sh que:
      a) Cree el directorio si falta,
      b) Liste archivos por fecha y borre/archiva los más antiguos manteniendo N copias,
      c) Opcionalmente comprima los archivos rotados.
   - Dar permisos ejecutables (chmod +x).
   - Probar manualmente en entorno de test.
   - Programar ejecución automática (cron o systemd timer) con salida a log de la tarea.
   - Añadir alerta o monitorización si la rotación falla (revisión de espacio en disco).
   - Documentar ubicación y configuración en README.
---
## 3. Implementar workflow en GitHub Actions para desplegar en AWS (contenedores)
   - Crear IAM user en AWS con permisos para ECR y ECS/EKS según destino; almacenar credenciales en Secrets de GitHub (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, etc.).
   - Crear repositorio ECR (o usar existente).
   - Añadir workflow .github/workflows/deploy-aws.yml que:
      a) Haga actions/checkout,
      b) Configure credenciales con aws-actions/configure-aws-credentials,
      c) Login a ECR (amazon-ecr-login),
      d) Build, tag y docker push a ECR,
      e) Actualice el servicio objetivo (ECS update-service o EKS kubectl con kubeconfig).
   - Versionado de imagen usando SHA o tag semántico.
   - Probar push y despliegue automático en la rama main.
   - Añadir pasos de rollback o verificación (health check) después del despliegue.
   - Documentar secrets y cómo probar el workflow.
---  
## 4. Conexión segura a un servidor remoto mediante SSH con clave privada

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
## 5. Crear manifiesto YAML para AKS con recursos y variables de entorno
   - Crear k8s/deployment.yml con:
      a) metadata.name coherente (ej. myapp),
      b) spec.replicas, selector y labels,
      c) contenedor con image placeholder (pipeline reemplaza tag),
      d) env desde ConfigMap/Secret o valores directos,
      e) resources.requests y limits.
   - Añadir probes: livenessProbe y readinessProbe.
   - Crear k8s/service.yml (ClusterIP/LoadBalancer) según necesidad.
   - Si se requieren secretos, incluir manifest Secret o indicar uso de Azure Key Vault + CSI Driver.
   - En pipeline: usar kubectl set image para actualizar imagen o kubectl apply -f k8s/.
   - Verificar con kubectl get pods, kubectl logs y kubectl rollout status.
   - Documentar variables de entorno esperadas, y cómo inyectarlas (ConfigMap/Secret).
---
## 6. Diseñar pipeline en Bitbucket Pipelines (tests unitarios + deploy a staging) — Solución / pasos
   - Crear bitbucket-pipelines.yml en la raíz.
   - Definir pipeline para rama develop (build & test):
      a) Instalar dependencias (npm ci),
      b) Ejecutar npm test,
      c) Construir imagen Docker si corresponde.
   - Configurar variables/secure env en Bitbucket (DOCKER_USER, DOCKER_PASS, AWS keys, etc.).
   - Autenticar contra registro y docker push.
   - Definir paso de deploy a staging (puede usar pipe de Atlassian para ECS, o kubectl si es K8s).
   - Marcar el paso como deployment: staging para trazabilidad.
   - Probar flujo con commits en develop y validar entornos de staging.
   - Documentar variables y permisos necesarios.
---
## 7. Script Bash/Python para verificar pods y notificar CrashLoopBackOff
   - Asegurar que kubectl tiene el contexto correcto (az aks get-credentials en CI si aplica).
   - Script scripts/check_pods.sh que:
      a) Lista pods (kubectl get pods -n <ns> -o jsonpath/...),
      b) Filtra por estado CrashLoopBackOff o status.phase!=Running,
      c) Para cada pod afectado recolecta kubectl describe pod y kubectl logs --previous,
      d) Prepara un resumen y devuelve código de salida 1 si hay fallos o 0 si todo OK.
   - Añadir opción de notificación: webhook (Slack/Teams), email o API de incidentes.
   - Probar manualmente y luego programar (cron) o integrarlo como step en pipeline (monitor post-deploy).
   - Asegurar manejo de credenciales y permisos en CI.
   - Documentar uso y ejemplos de webhook.
---
## 8. Plantilla básica en Terraform (o Bicep) para desplegar VM en Azure
- Elegir herramienta (Terraform recomendado para portabilidad).
- Crear infra/azure-vm/main.tf, variables.tf, outputs.tf:
   a) provider "azurerm" configurado,
   b) azurerm_resource_group, azurerm_virtual_network, azurerm_subnet,
   c) azurerm_public_ip, azurerm_network_interface,
   d) azurerm_linux_virtual_machine con admin_ssh_key apuntando a ~/.ssh/id_*.pub.
- Configurar variables resource_group_name, location, admin_username, public_key_path.
- Inicializar y probar: terraform init, terraform plan, terraform apply.
- Configurar backend remoto (Azure Storage) para el state si es producción.
- Añadir outputs relevantes (IP pública).
- Documentar cómo pasar la ruta de la clave pública y cómo eliminar los recursos (terraform destroy).
---
## 9. Pasos de diagnóstico de fallo en deploy:
   - Revisar logs del pipeline Azure DevOps (Build / Deploy) — ver si imagen se subió al ACR y tag usado.
   - Verificar que la imagen exista en ACR: az acr repository show --name <ACR_NAME> --repository myapp --query "tags"
   - Obtener credenciales AKS y revisar pods:
      a) az aks get-credentials -g my-aks-rg -n my-aks-cluster
      b) kubectl get pods -n default
      c) kubectl describe pod <pod-name> -n default
      d) kubectl logs <pod-name> -n default --previous
      e) kubectl get events -n default
   - Si kubectl describe muestra error de imagen (ImagePullBackOff): comprobar nombre/tag y permisos ACR/AKS (Aks needs pull permission).
      a) Verificar imagePullSecrets o que ACR esté ligado al AKS (AKS ACR integration / role assignment to SP): az role assignment list --assignee <aks-sp-id> --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/<acr>
   - Si CrashLoopBackOff por error de aplicación (e.g., configuración, falta de env var, DB unreachable): ver kubectl logs para la excepción y ajustar config/secret/env.
   - Comprobar recursos (OOMKilled): kubectl describe pod → ver State / Last State / Reason.
   - Prueba local: ejecutar la imagen localmente para reproducir error: docker run --rm -e ENVIRONMENT=production myregistry.azurecr.io/myapp:<tag>
   - Corregir: rebuild de la imagen con fix → push → rerun pipeline → kubectl rollout restart deployment/myapp o kubectl set image.
---
## 10. Configurar job en Jenkins que integre con GitHub y despliegue al merge en main
   - Añadir Jenkinsfile en la raíz del repo (pipeline-as-code).
   - En Jenkins, crear Multibranch Pipeline o usar plugin GitHub Branch Source apuntando al repo.
   - Configurar credenciales en Jenkins:
      a) Credenciales para el registro de contenedores (acr-credentials),
      b) Archivo kubeconfig o credenciales para acceder a AKS (kubeconfig-cred).
   - Configurar webhook en GitHub (o conectar Jenkins GitHub App) para notificar pushes/merges.
   - Pipeline (etapas):
      a) Checkout (scm),
      b) Build (docker build),
      c) Push (login -> docker push),
      d) Test (unit/integration),
      e) Deploy (usar KUBECONFIG para kubectl set image o kubectl apply),
      f) Post (notificaciones, status).
   - Asegurar que agentes/ejecutores tienen Docker/Kubectl o usar imágenes que lo contengan.
   - Probar flujo: PR → merge a main → webhook → Jenkins multibranch detecta y ejecuta pipeline.
   - Añadir controles (aprovals, notificaciones) y almacenar logs/artifacts.
   - Documentar cómo configurar Jenkins (plugins, credentials IDs y webhook URL).
