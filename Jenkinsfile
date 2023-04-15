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

    // 自建Docker Image倉庫 
    DOCKER_REGISTRY_URL = "myregistrydomain.com"
    DOCKER_REGISTRY_CREDENTIALS = credentials('self-docker-registry')    
    
    DOCKER_REGISTRY_ACCOUNT = "$DOCKER_REGISTRY_CREDENTIALS_USR"
    DOCKER_REGISTRY_REPOSITOY_NAME = "$DOCKER_REGISTRY_ACCOUNT/$IMAGE_NAME"
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
        sh 'docker build -t $DOCKER_REGISTRY_URL/$DOCKER_REGISTRY_REPOSITOY_NAME:$IMAGE_TAG ./'
      }
    }
    stage('Docker Login') {
      steps {
        sh 'echo $DOCKER_REGISTRY_CREDENTIALS_PSW | docker login $DOCKER_REGISTRY_URL -u $DOCKER_REGISTRY_CREDENTIALS_USR --password-stdin'
      }
    }
    stage('Docker Push') {
      steps {
        sh 'docker push $DOCKER_REGISTRY_URL/$DOCKER_REGISTRY_REPOSITOY_NAME:$IMAGE_TAG'
      }
    }
  }
  post {
    always {
      sh 'docker logout $DOCKER_REGISTRY_URL'
    }
  }
}