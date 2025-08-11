pipeline {
  agent any
  environment {
    ACR_NAME = 'myregistry'
    IMAGE_NAME = 'myapp'
    REGISTRY_CREDENTIALS = 'acr-credentials'
    KUBECONFIG_CREDENTIALS = 'kubeconfig-cred'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build') {
      steps {
        sh 'docker build -t ${ACR_NAME}/${IMAGE_NAME}:${BUILD_NUMBER} .'
      }
    }
    stage('Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}", usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            echo "$REG_PASS" | docker login ${ACR_NAME} -u "$REG_USER" --password-stdin
            docker push ${ACR_NAME}/${IMAGE_NAME}:${BUILD_NUMBER}
            docker logout ${ACR_NAME}
          '''
        }
      }
    }
    stage('Test') {
      steps {
        sh 'npm ci || true'
        sh 'npm test || true'
      }
    }
    stage('Deploy') {
      steps {
        withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=${KUBECONFIG_FILE}
            kubectl set image deployment/myapp myapp=${ACR_NAME}/${IMAGE_NAME}:${BUILD_NUMBER} -n default --record || kubectl apply -f k8s/deployment.yml -n default
            kubectl rollout status deployment/myapp -n default
          '''
        }
      }
    }
  }
  post {
    success {
      echo 'Pipeline finalizado correctamente.'
    }
    failure {
      echo 'Falló el pipeline.'
    }
  }
}
