pipeline {
  agent any
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  parameters {
    string(name: 'IMAGE_NAME', defaultValue: 'django-lab', description: 'Image Repository')
    string(name: 'IMAGE_TAG',  defaultValue: 'latest',     description: 'Image TAG')
  }
  environment {
    
    // ================== Docker Registry Information ==================
    
    // Docker HUB 官方倉庫
    DOCKER_REGISTRY_CREDENTIALS = credentials('docker-hub')

    // 自建 Docker Registry 
    // DOCKER_REGISTRY_CREDENTIALS = credentials('self-docker-registry')    
    
  }
  stages {
    // Clone Git repo
    stage("Checkout Application Git Repository") {
      steps {
        checkout(changelog: false, poll: false, scm: [
            $class: 'GitSCM',
            branches: [
              [name: "*/main"],
            ],
            userRemoteConfigs: [
              [
                url: "git@gitlab.example.com:it/django-lab.git",
                credentialsId: "gitlab_deploy_key"
              ],
            ],
        ])
      }
    }
    // 建立Docker Image
    stage('Build Image') {
      steps {
        // sh 'make build DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR IMAGE_TAG=$IMAGE_TAG'
        sh 'make build DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR IMAGE_TAG=$(git rev-parse --short HEAD)'
      }
    }
    // 登入Docker Registry
    stage('Docker Login') {
      steps {
        // sh 'make push DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_CREDENTIALS_PSW IMAGE_TAG=$IMAGE_TAG'
        sh 'make push DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_CREDENTIALS_PSW IMAGE_TAG=$(git rev-parse --short HEAD)'
      }
    }
    // 使用Helm部署至Kubernetes
    stage('Deploy to kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'jenkins-kubeconfig', variable: 'KUBECONFIG')]) {
          // sh 'helm upgrade --install $IMAGE_NAME django-lab-chart --namespace devops --set image.tag=$IMAGE_TAG'
          sh 'helm upgrade --install $IMAGE_NAME django-lab-chart --namespace devops --set image.tag=$(git rev-parse --short HEAD)'
        }
      }
    }

  }
  post {
    always {
      sh 'docker logout $DOCKER_REGISTRY_URL'
    }
  }
}