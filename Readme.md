# Test DevOps
---
## 1. Configurar un pipeline CI/CD en Azure DevOps (build, test y deploy a AKS)
   1. Crear en Azure DevOps el proyecto y conectar el repositorio.
   2. Crear Service Connections:
      -  ACR (para push/pull de imágenes).
      -  Azure Resource Manager (para ejecutar az aks / kubectl).
   3. Definir variables y variable groups (registry, image name, aksResourceGroup, aksClusterName, namespace, cred IDs).
   4. Añadir azure-pipelines.yml en la raíz que orqueste stages (Build → Test → Deploy) y que use los templates en pipelines/templates/.
   5. Build stage: Docker build y push (task Docker@2), tag con $(Build.BuildId) o commit SHA.
   6. Test stage: ejecutar pruebas unitarias (ej. npm ci && npm test) y fallar si no pasan.
   7. Deploy stage: usar AzureCLI@2 para az aks get-credentials y kubectl set image o kubectl apply contra los manifiestos en k8s/, luego kubectl rollout status.
   8. Asegurar permisos: asignar rol Pull al identity de AKS contra ACR o usar imagePullSecrets.
   9. Probar pipeline en rama main y validar despliegue en AKS; ajustar timeouts/rollout strategy.
   10. Documentar variables y cómo crear los service connections (en README).
---
## 2. Crear un script Bash para rotación de logs en Linux
   1. Identificar directorio y patrón de logs (ej. /var/log/myapp/*.log).
   2. Escribir scripts/rotate_logs.sh que:
      -  Cree el directorio si falta,
      -  Liste archivos por fecha y borre/archiva los más antiguos manteniendo N copias,
      -  Opcionalmente comprima los archivos rotados.
   3. Dar permisos ejecutables (chmod +x).
   4. Probar manualmente en entorno de test.
   5. Programar ejecución automática (cron o systemd timer) con salida a log de la tarea.
   6. Añadir alerta o monitorización si la rotación falla (revisión de espacio en disco).
   7. Documentar ubicación y configuración en README.
---
## 3. Implementar workflow en GitHub Actions para desplegar en AWS (contenedores)
   1. Crear IAM user en AWS con permisos para ECR y ECS/EKS según destino; almacenar credenciales en Secrets de GitHub (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, etc.).
   2. Crear repositorio ECR (o usar existente).
   3. Añadir workflow .github/workflows/deploy-aws.yml que:
      -  Haga actions/checkout,
      -  Configure credenciales con aws-actions/configure-aws-credentials,
      -  Login a ECR (amazon-ecr-login),
      -  Build, tag y docker push a ECR,
      -  Actualice el servicio objetivo (ECS update-service o EKS kubectl con kubeconfig).
   4. Versionado de imagen usando SHA o tag semántico.
   5. Probar push y despliegue automático en la rama main.
   6. Añadir pasos de rollback o verificación (health check) después del despliegue.
   7. Documentar secrets y cómo probar el workflow.
---  
## 4. Conexión segura a un servidor remoto mediante SSH con clave privada

   1. Generar un par de claves SSH en tu máquina local
      - ssh-keygen -t rsa -b 4096 -C "infra@XYZ.com"
      - Presionar Enter para aceptar ruta por defecto (~/.ssh/id_rsa)
   2. Copiar la clave pública al servidor
      - Método rápido:
        ssh-copy-id user@ip_server:puerto
      - Método manual:
        - En tu máquina local, mostrar tu clave pública:
           cat ~/.ssh/id_rsa.pub
        - Copiar todo el contenido mostrado.
        - Conectarte al servidor:
           ssh user@ip_server:puerto
        - Abrir el archivo authorized_keys:
           vi ~/.ssh/authorized_keys
        - Pegar el contenido de la clave pública en el archivo, guardar y salir (`Esc`, escribir `:wq` y presionar `Enter`).
           - Modo rapido -> echo "clave_publica" >> ~/.ssh/authorized_keys
        - Ajustar permisos:
           chmod 600 ~/.ssh/authorized_keys
   3. Probar conexión con clave
      - ssh user@ip_server:puerto (No debe pedir contraseña)
---
## 5. Crear manifiesto YAML para AKS con recursos y variables de entorno
   1. Crear k8s/deployment.yml con:
      -  metadata.name coherente (ej. myapp),
      -  spec.replicas, selector y labels,
      -  contenedor con image placeholder (pipeline reemplaza tag),
      -  env desde ConfigMap/Secret o valores directos,
      -  resources.requests y limits.
   2. Añadir probes: livenessProbe y readinessProbe.
   3. Crear k8s/service.yml (ClusterIP/LoadBalancer) según necesidad.
   4. Si se requieren secretos, incluir manifest Secret o indicar uso de Azure Key Vault + CSI Driver.
   5. En pipeline: usar kubectl set image para actualizar imagen o kubectl apply -f k8s/.
   6. Verificar con kubectl get pods, kubectl logs y kubectl rollout status.
   7. Documentar variables de entorno esperadas, y cómo inyectarlas (ConfigMap/Secret).
---
## 6. Diseñar pipeline en Bitbucket Pipelines (tests unitarios + deploy a staging) — Solución / pasos
   1. Crear bitbucket-pipelines.yml en la raíz.
   2. Definir pipeline para rama develop (build & test):
      -  Instalar dependencias (npm ci),
      -  Ejecutar npm test,
      -  Construir imagen Docker si corresponde.
   3. Configurar variables/secure env en Bitbucket (DOCKER_USER, DOCKER_PASS, AWS keys, etc.).
   4. Autenticar contra registro y docker push.
   5. Definir paso de deploy a staging (puede usar pipe de Atlassian para ECS, o kubectl si es K8s).
   6. Marcar el paso como deployment: staging para trazabilidad.
   7. Probar flujo con commits en develop y validar entornos de staging.
   8. Documentar variables y permisos necesarios.
---
## 7. Script Bash/Python para verificar pods y notificar CrashLoopBackOff
   1. Asegurar que kubectl tiene el contexto correcto (az aks get-credentials en CI si aplica).
   2. Script scripts/check_pods.sh que:
      -  Lista pods (kubectl get pods -n <ns> -o jsonpath/...),
      -  Filtra por estado CrashLoopBackOff o status.phase!=Running,
      -  Para cada pod afectado recolecta kubectl describe pod y kubectl logs --previous,
      -  Prepara un resumen y devuelve código de salida 1 si hay fallos o 0 si todo OK.
   3. Añadir opción de notificación: webhook (Slack/Teams), email o API de incidentes.
   4. Probar manualmente y luego programar (cron) o integrarlo como step en pipeline (monitor post-deploy).
   5. Asegurar manejo de credenciales y permisos en CI.
   6. Documentar uso y ejemplos de webhook.
---
## 8. Plantilla básica en Terraform (o Bicep) para desplegar VM en Azure
1. Elegir herramienta (Terraform recomendado para portabilidad).
2. Crear infra/azure-vm/main.tf, variables.tf, outputs.tf:
   -  provider "azurerm" configurado,
   -  azurerm_resource_group, azurerm_virtual_network, azurerm_subnet,
   -  azurerm_public_ip, azurerm_network_interface,
   -  azurerm_linux_virtual_machine con admin_ssh_key apuntando a ~/.ssh/id_*.pub.
3. Configurar variables resource_group_name, location, admin_username, public_key_path.
4. Inicializar y probar: terraform init, terraform plan, terraform apply.
5. Configurar backend remoto (Azure Storage) para el state si es producción.
6. Añadir outputs relevantes (IP pública).
7. Documentar cómo pasar la ruta de la clave pública y cómo eliminar los recursos (terraform destroy).
---
## 9. Pasos de diagnóstico de fallo en deploy:
   1. Revisar logs del pipeline Azure DevOps (Build / Deploy) — ver si imagen se subió al ACR y tag usado.
   2. Verificar que la imagen exista en ACR: az acr repository show --name <ACR_NAME> --repository myapp --query "tags"
   3. Obtener credenciales AKS y revisar pods:
      -  az aks get-credentials -g my-aks-rg -n my-aks-cluster
      -  kubectl get pods -n default
      -  kubectl describe pod <pod-name> -n default
      -  kubectl logs <pod-name> -n default --previous
      -  kubectl get events -n default
   4. Si kubectl describe muestra error de imagen (ImagePullBackOff): comprobar nombre/tag y permisos ACR/AKS (Aks needs pull permission).
      -  Verificar imagePullSecrets o que ACR esté ligado al AKS (AKS ACR integration / role assignment to SP): az role assignment list --assignee <aks-sp-id> --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/<acr>
   5. Si CrashLoopBackOff por error de aplicación (e.g., configuración, falta de env var, DB unreachable): ver kubectl logs para la excepción y ajustar config/secret/env.
   6. Comprobar recursos (OOMKilled): kubectl describe pod → ver State / Last State / Reason.
   7. Prueba local: ejecutar la imagen localmente para reproducir error: docker run --rm -e ENVIRONMENT=production myregistry.azurecr.io/myapp:<tag>
   8. Corregir: rebuild de la imagen con fix → push → rerun pipeline → kubectl rollout restart deployment/myapp o kubectl set image.
---
## 10. Configurar job en Jenkins que integre con GitHub y despliegue al merge en main
   1. Añadir Jenkinsfile en la raíz del repo (pipeline-as-code).
   2. En Jenkins, crear Multibranch Pipeline o usar plugin GitHub Branch Source apuntando al repo.
   3. Configurar credenciales en Jenkins:
      -  Credenciales para el registro de contenedores (acr-credentials),
      -  Archivo kubeconfig o credenciales para acceder a AKS (kubeconfig-cred).
   4. Configurar webhook en GitHub (o conectar Jenkins GitHub App) para notificar pushes/merges.
   5. Pipeline (etapas):
      -  Checkout (scm),
      -  Build (docker build),
      -  Push (login -> docker push),
      -  Test (unit/integration),
      -  Deploy (usar KUBECONFIG para kubectl set image o kubectl apply),
      -  Post (notificaciones, status).
   6. Asegurar que agentes/ejecutores tienen Docker/Kubectl o usar imágenes que lo contengan.
   7. Probar flujo: PR → merge a main → webhook → Jenkins multibranch detecta y ejecuta pipeline.
   8. Añadir controles (aprovals, notificaciones) y almacenar logs/artifacts.
   9. Documentar cómo configurar Jenkins (plugins, credentials IDs y webhook URL).
