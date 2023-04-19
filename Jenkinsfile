pipeline {
  agent any
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  environment {
    // ================== Docker Registry Information ==================
    // Docker HUB 官方倉庫
    DOCKER_REGISTRY_URL         = 'registry-1.docker.io'
    DOCKER_REGISTRY_CREDENTIALS = credentials('docker-hub')
    DOCKER_REGISTRY_REPOSITORY = '$DOCKER_REGISTRY_CREDENTIALS_USR/django-lab'

    // 取得 Git Commit Hash 作為Image Tag
    IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()


    // 自建 Docker Registry 
    // DOCKER_REGISTRY_CREDENTIALS = credentials('self-docker-registry')    
    // DOCKER_REGISTRY_REPOSITORY = 'spencer810704/django-lab'

    // Kubernetes Namespace
    KUBERNETES_NAMESPACE = 'devops'

    // Helm Chart Information
    HELM_RELEASE_NAME    = 'django-lab'
    HELM_CHART_NAME      = 'django-lab-chart'
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
    stage('Show Jenkins Environment') {
      steps {
        // 設定IMAGE_TAG為git commit 前六碼
        sh '''
        echo DOCKER_REGISTRY_URL: $DOCKER_REGISTRY_URL \nDOCKER_REGISTRY_REPOSITORY: $DOCKER_REGISTRY_REPOSITORY
        echo DOCKER_REGISTRY_REPOSITORY: $DOCKER_REGISTRY_REPOSITORY
        echo IMAGE_TAG: $IMAGE_TAG
        echo KUBERNETES_NAMESPACE: $KUBERNETES_NAMESPACE
        echo HELM_RELEASE_NAME: $HELM_RELEASE_NAME
        echo HELM_CHART_NAME: $HELM_CHART_NAME
        '''
      }
    }
    // // 建立Docker Image(設定 --no-cache 不使用 image cache)
    // stage('Build Image') {
    //   steps {
    //     // 設定IMAGE_TAG為git commit 前六碼
    //     sh 'make build DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR IMAGE_TAG=$IMAGE_TAG'
    //   }
    // }
    // // 登入Docker Registry
    // stage('Docker Login') {
    //   steps {
    //     // 設定IMAGE_TAG為git commit 前六碼
    //     sh 'make push DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_CREDENTIALS_PSW IMAGE_TAG=$IMAGE_TAG'
    //   }
    // }
    // // 使用Helm部署至Kubernetes
    // stage('Deploy to kubernetes') {
    //   steps {
    //     withCredentials([file(credentialsId: 'jenkins-kubeconfig', variable: 'KUBECONFIG')]) {
    //       // 設定IMAGE_TAG為git commit 前六碼
    //       sh 'helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART_NAME --namespace $KUBERNETES_NAMESPACE --set image.repository=$DOCKER_REGISTRY_REPOSITORY --set image.tag=$IMAGE_TAG'
    //     }
    //   }
    // }
  }
  post {
    always {
      sh 'docker logout $DOCKER_REGISTRY_URL'
    }
  }
}