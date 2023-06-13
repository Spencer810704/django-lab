pipeline {
  agent any
  options {
    buildDiscarder(logRotator(numToKeepStr: "5"))
  }
  environment {
    // ====================== Project Information ======================
    // 專案名稱
    PROJECT_NAME = "django-lab"

    // 取得 Git Commit Hash前六碼 作為Image Tag
    IMAGE_TAG = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()

    // ================== Docker Registry Information ==================
    
    // For Docker HUB
    DOCKER_REGISTRY_URL         = "registry-1.docker.io"
    DOCKER_REGISTRY_CREDENTIALS = credentials("docker-hub")
    DOCKER_REGISTRY_REPOSITORY  = "$DOCKER_REGISTRY_CREDENTIALS_USR/$PROJECT_NAME"

    // For Custom Docker Registry
    // DOCKER_REGISTRY_URL         = "myregistrydomain.com"
    // DOCKER_REGISTRY_CREDENTIALS = credentials("self-docker-registry")
    // DOCKER_REGISTRY_REPOSITORY  = "$DOCKER_REGISTRY_CREDENTIALS_USR/$PROJECT_NAME"

    // ================== Kubernetes Information ==================
    // Kubernetes Namespace
    KUBERNETES_NAMESPACE = "devops"

    // Helm Chart Information
    HELM_RELEASE_NAME    = "$PROJECT_NAME"
    HELM_CHART_NAME      = "$PROJECT_NAME-chart"
    
    // HELM SECRET PLUGIN 
    SOPS_PGP_FP          = "73F88B4A3B8DFFE2D1EFB704D566664AE2AC5616"
  }
  stages {
    // Clone Git repo
    stage("Checkout Application Git Repository") {
      steps {
        checkout(changelog: false, poll: false, scm: [
            $class: "GitSCM",
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
    stage("Show Jenkins Environment") {
      steps {
        script {
          // Groovy 語法印出目前使用的變數 , 用echo會有點難看 , 所以才採用此種方式
          String output = """\
            ==================== Jenkinsfile Environment ====================
            DOCKER_REGISTRY_URL         : ${DOCKER_REGISTRY_URL        ?: 'undefined'}
            DOCKER_REGISTRY_REPOSITORY  : ${DOCKER_REGISTRY_REPOSITORY ?: 'undefined'}
            IMAGE_TAG                   : ${IMAGE_TAG                  ?: 'undefined'}
            KUBERNETES_NAMESPACE        : ${KUBERNETES_NAMESPACE       ?: 'undefined'}
            HELM_RELEASE_NAME           : ${HELM_RELEASE_NAME          ?: 'undefined'}
            HELM_CHART_NAME             : ${HELM_CHART_NAME            ?: 'undefined'}
            SOPS_PGP_FP                 : ${SOPS_PGP_FP                ?: 'undefined'}
            ================================================================== 
          """.stripIndent()
          // 輸出內容
          echo output
        }
      }
    }
    // 建立Docker Image(設定 --no-cache 不使用 image cache)
    stage("Build Image") {
      steps {
        sh "make build DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR IMAGE_TAG=$IMAGE_TAG"
      }
    }
    // 登入Docker Registry
    stage("Docker login and push image") {
      steps {
        sh "make push DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_CREDENTIALS_PSW IMAGE_TAG=$IMAGE_TAG"
      }
    }
    // 使用Helm部署至Kubernetes
    stage("Deploy to kubernetes") {
      steps {
        withCredentials([file(credentialsId: "jenkins-kubeconfig", variable: "KUBECONFIG")]) {
          sh "helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART_NAME --namespace $KUBERNETES_NAMESPACE --set image.repository=$DOCKER_REGISTRY_REPOSITORY --set image.tag=$IMAGE_TAG"
        }
      }
    }
  }
  post {
    always {
      sh "docker logout $DOCKER_REGISTRY_URL"
    }
  }
}