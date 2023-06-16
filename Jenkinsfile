pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: "5"))           // 建置紀錄只保留5份
        gitLabConnection('gitlab')                              // 設置 Gitlab Connection , 用於回寫建置狀態回Gitlab Pipeline (Pending、Success、Failed) , 
                                                                // 注意：需要在 『管理 Jenkins』-> 『設定系統』->『Gitlab』-> 把 『Enable authentication for '/project' end-point』選項取消 , 否則會回寫失敗 , 出現403錯誤
                                                                // 為什麼造成這個原因目前還沒特別去查
    }
    triggers {
        // 設置 Gitlab Webhook Trigger
        gitlab(
            triggerOnPush: true,
            triggerOnMergeRequest: false, 
            triggerOpenMergeRequestOnPush: "never",
            triggerOnNoteRequest: false,
            noteRegex: "Jenkins please retry a build",
            skipWorkInProgressMergeRequest: true,
            ciSkip: true,
            setBuildDescription: true,
            addNoteOnMergeRequest: false,
            addCiMessage: false,
            addVoteOnMergeRequest: false,
            acceptMergeRequestOnSuccess: false,
            // 設置哪一些 Branch 的異動時，可以觸發此Pipeline
            branchFilterType: "NameBasedFilter",
            includeBranchesSpec: "main",
            excludeBranchesSpec: "",
            pendingBuildName: "Jenkins",
            cancelPendingBuildsOnUpdate: false,
            // 因為 Secret Token 是在 Jenkinsfile 中管理 , 所以需要注意該專案的Viewer權限(Private repo)只能給特定團隊成員 , 否則任何人有 secret token 就可以觸發該任務
            // 另外也能從 Jenkins Job 修改組態的設定中生成 , 如果是這種方式需要特別設置該 Job 只能給特定用戶修改組態權限
            secretToken: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEF"
        )
    }
    environment {

        // ================================================================== Project  ==================================================================
        
        ENVIRONMENT   = "prod"                                                                // define environment
        GIT_REPO      = "git@gitlab.example.com:it/django-lab.git"                            // define git repo url
        BRANCH        = "master"                                                              // define git repo branch
        IMAGE_TAG     = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()   // 取得 Git Commit Hash 前六碼 作為 Image Tag
        PROJECT_NAME  = "django-lab"                                                          // define project name
        WORKSPACE_DIR = "${WORKSPACE}/${BUILD_ID}"                                            // define workspace

        // ============================================================== Docker Image Repository  ==============================================================

        DOCKER_REGISTRY_URL         = "registry-1.docker.io"                                // Docker Hub URL
        DOCKER_REGISTRY_CREDENTIALS = credentials("docker-hub")                             // Docker Hub Credentials
        DOCKER_REGISTRY_REPOSITORY  = "$DOCKER_REGISTRY_CREDENTIALS_USR/$PROJECT_NAME"      // Docker Hub 倉庫地址
            
        // DOCKER_REGISTRY_URL         = "myregistrydomain.com"                             // Docker registry URL
        // DOCKER_REGISTRY_CREDENTIALS = credentials("self-docker-registry")                // Docker registry Credentials
        // DOCKER_REGISTRY_REPOSITORY  = "$DOCKER_REGISTRY_CREDENTIALS_USR/$PROJECT_NAME"   // Docker registry 倉庫地址

        // ================================================================= Kubernetes  =================================================================

        KUBERNETES_NAMESPACE = "devops"                                                     // Kubernetes Namespace

        HELM_CHART_NAME      = "$PROJECT_NAME-chart"                                        // Helm Chart Name
        HELM_RELEASE_NAME    = "$PROJECT_NAME"                                              // Helm Release Name

        SOPS_PGP_FP          = "73F88B4A3B8DFFE2D1EFB704D566664AE2AC5616"                   // Helm-secret Plugin

        // ================================================================================================================================================
    }
    stages {
        // setup environment
        stage('Setup Environment') {
            steps {
                script {
                    switch (env.ENVIRONMENT) {
                        case ["sit"]:
                            env.KUBECONFIG = "sit_jenkins_kubeconfig"
                            env.GITKEY = "gitlab_deploy_key"
                            break
                        case ["stg"]:
                            env.KUBECONFIG = "stg_jenkins_kubeconfig"
                            env.GITKEY = "gitlab_deploy_key"
                            break
                        case ["prod"]:
                            env.KUBECONFIG = "prod_jenkins_kubeconfig"
                            env.GITKEY = "gitlab_deploy_key"
                            break
                    }
                }
            }
        } // end of setup environment
        // git checkout
        stage('Git checkout') {
            steps {
                dir(WORKSPACE_DIR) {
                    git url: "${GIT_REPO}",
                            credentialsId: "${GITKEY}",
                            branch: "${BRANCH}"
                }

                dir(WORKSPACE_DIR) {
                    sh("git checkout ${REVISION}")
                }
            }
        } // end of stage
        // stage("Checkout Application Git Repository") {
        //     steps {
        //         checkout(changelog: false, poll: false, scm: [
        //             $class: "GitSCM",
        //             branches: [
        //             [name: "*/main"],
        //             ],
        //             userRemoteConfigs: [
        //             [
        //                 url: "git@gitlab.example.com:it/django-lab.git",
        //                 credentialsId: "gitlab_deploy_key"
        //             ],
        //             ],
        //         ])
        //     }
        // }
        // stage("Show Jenkins Environment") {
        //     steps {
        //         // 更新 Gitlab Pipeline 中的建置狀態
        //         updateGitlabCommitStatus name: 'build', state: 'pending'

        //         script {
        //         // Groovy 語法印出目前使用的變數 , 用echo會有點難看 , 所以才採用此種方式
        //         String output = """
        //             ==================== Jenkinsfile Environment ====================
        //             IMAGE_TAG                   : ${IMAGE_TAG                  ?: 'undefined'}
        //             DOCKER_REGISTRY_URL         : ${DOCKER_REGISTRY_URL        ?: 'undefined'}
        //             DOCKER_REGISTRY_REPOSITORY  : ${DOCKER_REGISTRY_REPOSITORY ?: 'undefined'}
        //             KUBERNETES_NAMESPACE        : ${KUBERNETES_NAMESPACE       ?: 'undefined'}
        //             HELM_CHART_NAME             : ${HELM_CHART_NAME            ?: 'undefined'}
        //             HELM_RELEASE_NAME           : ${HELM_RELEASE_NAME          ?: 'undefined'}
        //             SOPS_PGP_FP                 : ${SOPS_PGP_FP                ?: 'undefined'}
        //             ================================================================== 
        //         """.stripIndent()
        //         // 輸出內容
        //         echo output
        //         }
        //     }
        // }
        // stage("Build Image") {
        //     steps {
        //         // 建立Docker Image(設定 --no-cache 不使用 image cache)
        //         sh "make build DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR IMAGE_TAG=$IMAGE_TAG"
        //     }
        // }
        // stage("Docker login and push image") {
        //     steps {
        //         // 登入Docker Registry
        //         sh "make push DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_CREDENTIALS_USR DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_CREDENTIALS_PSW IMAGE_TAG=$IMAGE_TAG"
        //     }
        // }
        // stage("Deploy to kubernetes") {
        //     steps {
        //         // 使用Helm部署至Kubernetes
        //         withCredentials([file(credentialsId: "jenkins-kubeconfig", variable: "KUBECONFIG")]) {
        //             sh "helm secrets upgrade --install $HELM_RELEASE_NAME $HELM_CHART_NAME --namespace $KUBERNETES_NAMESPACE --set image.repository=$DOCKER_REGISTRY_REPOSITORY --set image.tag=$IMAGE_TAG --values django-lab-chart/values-prod.yaml --values django-lab-chart/secrets.prod.yaml"
        //         }
        //     }
        // }
    }
    post {
        failure {
            // 更新 Gitlab Pipeline 中的建置狀態
            updateGitlabCommitStatus name: 'build', state: 'failed'
        }
        success {
            // 更新 Gitlab Pipeline 中的建置狀態
            updateGitlabCommitStatus name: 'build', state: 'success'
        }
        always {
            sh "docker logout $DOCKER_REGISTRY_URL"
        }
    }
}