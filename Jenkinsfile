pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins-admin
                  containers:
                  - name: python
                    image: python:3.13
                    command: ["cat"]
                    tty: true
                    volumeMounts:
                    - mountPath: /home/jenkins/agent
                      name: workspace-volume
                    workingDir: /home/jenkins/agent
                  - name: docker
                    image: docker:23-dind
                    privileged: true
                    securityContext:
                      privileged: true
                    env:
                    - name: DOCKER_HOST
                      value: tcp://localhost:2375
                    - name: DOCKER_TLS_CERTDIR
                      value: ""
                    - name: DOCKER_BUILDKIT
                      value: "1"
                    volumeMounts:
                    - mountPath: /home/jenkins/agent
                      name: workspace-volume
                  - name: kubectl
                    image: bitnami/kubectl:1.30.7
                    command: ["/bin/sh"]
                    args: ["-c", "while true; do sleep 30; done"]
                    alwaysPull: true
                    securityContext:
                      runAsUser: 0
                    volumeMounts:
                    - mountPath: /home/jenkins/agent
                      name: workspace-volume
                  volumes:
                  - name: workspace-volume
                    emptyDir: {}
            '''
            defaultContainer 'python'
            inheritFrom 'default'
        }
    }
    options {
        timestamps()
        disableConcurrentBuilds()
    }
    environment {
        DOCKER_IMAGE = 'papakao/voyeur'
        DOCKER_TAG = "${BUILD_NUMBER}"
    }
    stages {
        stage('Clone and Setup') {
            steps {
                container('python') {
                    script {
                        withCredentials([
                            string(credentialsId: 'MONGODB_URI', variable: 'MONGODB_URI'),
                            string(credentialsId: 'MONGODB_USERNAME', variable: 'MONGODB_USERNAME'),
                            string(credentialsId: 'MONGODB_PASSWORD', variable: 'MONGODB_PASSWORD'),
                            string(credentialsId: 'MONGODB_AUTH_SOURCE', variable: 'MONGODB_AUTH_SOURCE'),
                            string(credentialsId: 'DJANGO_SECRET_KEY', variable: 'DJANGO_SECRET_KEY')
                        ]) {
                            sh '''
                                # 確認 Dockerfile 存在
                                ls -la
                                if [ ! -f "Dockerfile" ]; then
                                    echo "Error: Dockerfile not found!"
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                container('python') {
                    sh '''
                        pip install poetry
                        poetry lock
                        poetry install
                    '''
                }
            }
        }

        stage('Build Docker Image with BuildKit') {
            steps {
                container('docker') {
                    script {
                        withCredentials([
                            usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                            string(credentialsId: 'MONGODB_URI', variable: 'MONGODB_URI'),
                            string(credentialsId: 'MONGODB_USERNAME', variable: 'MONGODB_USERNAME'),
                            string(credentialsId: 'MONGODB_PASSWORD', variable: 'MONGODB_PASSWORD'),
                            string(credentialsId: 'MONGODB_AUTH_SOURCE', variable: 'MONGODB_AUTH_SOURCE'),
                            string(credentialsId: 'DJANGO_SECRET_KEY', variable: 'DJANGO_SECRET_KEY')
                        ]) {
                            sh '''
                                cd /home/jenkins/agent/workspace/VOYEUR/voyeur-deploy
                                echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                                # 確認 Dockerfile 存在
                                ls -la
                                if [ ! -f "Dockerfile" ]; then
                                    echo "Error: Dockerfile not found!"
                                    exit 1
                                fi
                                # 構建 Docker 鏡像
                                docker build \
                                    --build-arg BUILDKIT_INLINE_CACHE=1 \
                                    --build-arg MONGODB_URI="${MONGODB_URI}" \
                                    --build-arg MONGODB_USERNAME="${MONGODB_USERNAME}" \
                                    --build-arg MONGODB_PASSWORD="${MONGODB_PASSWORD}" \
                                    --build-arg MONGODB_AUTH_SOURCE="${MONGODB_AUTH_SOURCE}" \
                                    --build-arg DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY}" \
                                    --cache-from ${DOCKER_IMAGE}:latest \
                                    -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                                    -t ${DOCKER_IMAGE}:latest \
                                    .
                                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                                docker push ${DOCKER_IMAGE}:latest
                            '''
                        }
                    }
                }
            }
        }

        stage('Debug Environment') {
            steps {
                container('kubectl') {
                    script {
                        echo "=== Listing all environment variables ==="
                        sh 'printenv | sort'
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'kubeconfig-secret']) {
                        script {
                            try {
                                // 測試集群連接
                                sh 'kubectl cluster-info'
                                
                                // 檢查 deployment.yaml 文件
                                sh 'ls -la k8s/'
                                
                                // 檢查 Deployment 是否存在
                                sh '''
                                    if kubectl get deployment voyeur -n default; then
                                        echo "Deployment exists, updating..."
                                        kubectl set image deployment/voyeur voyeur=${DOCKER_IMAGE}:${DOCKER_TAG} -n default
                                        kubectl rollout restart deployment voyeur
                                    else
                                        echo "Deployment does not exist, creating..."
                                        kubectl apply -f k8s/deployment.yaml
                                    fi
                                '''
                                
                                // 檢查部署狀態
                                sh 'kubectl get deployments -n default'
                                sh 'kubectl rollout status deployment/voyeur'
                            } catch (Exception e) {
                                echo "Error during deployment: ${e.message}"
                                throw e
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}