pipeline {
  agent any
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  parameters {
    string(name: 'IMAGE_NAME', defaultValue: 'mylab', description: 'Image Name')
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Image TAG')

  }
  environment {
    
    // ================== Docker Registry Information ==================
    
    // Docker HUB 官方倉庫
    // DOCKER_REGISTRY_URL = "registry-1.docker.io"
    // DOCKER_REGISTRY_CREDENTIALS = credentials('docker-hub')

    // 自建 Docker Registry 
    DOCKER_REGISTRY_URL = "myregistrydomain.com"
    DOCKER_REGISTRY_CREDENTIALS = credentials('self-docker-registry')    
    
  }
  stages {
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
    stage('Build Image') {
      steps {
        sh 'make build DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR IMAGE_TAG=$IMAGE_TAG'
      }
    }
    stage('Docker Login') {
      steps {
        sh 'make push DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_CREDENTIALS_PSW IMAGE_TAG=$IMAGE_TAG'
      }
    }
  }
  post {
    always {
      sh 'docker logout $DOCKER_REGISTRY_URL'
    }
  }
}