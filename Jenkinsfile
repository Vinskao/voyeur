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
                    image: python:3.12
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
                            string(credentialsId: 'DJANGO_SECRET_KEY', variable: 'DJANGO_SECRET_KEY'),
                            string(credentialsId: 'DJANGO_HOST', variable: 'DJANGO_HOST'),
                            string(credentialsId: 'DJANGO_ENV', variable: 'DJANGO_ENV'),
                            string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                            string(credentialsId: 'REDIS_PORT', variable: 'REDIS_PORT'),
                            string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                            string(credentialsId: 'REDIS_QUEUE_NAME', variable: 'REDIS_QUEUE_NAME')
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
                        poetry config virtualenvs.create false
                        poetry install --no-root --only main
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
                            string(credentialsId: 'DJANGO_SECRET_KEY', variable: 'DJANGO_SECRET_KEY'),
                            string(credentialsId: 'DJANGO_HOST', variable: 'DJANGO_HOST'),
                            string(credentialsId: 'DJANGO_ENV', variable: 'DJANGO_ENV'),
                            string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                            string(credentialsId: 'REDIS_PORT', variable: 'REDIS_PORT'),
                            string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                            string(credentialsId: 'REDIS_QUEUE_NAME', variable: 'REDIS_QUEUE_NAME')
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
                                    --build-arg DJANGO_HOST="${DJANGO_HOST}" \
                                    --build-arg DJANGO_ENV="production" \
                                    --build-arg DJANGO_ALLOWED_HOSTS="peoplesystem.tatdvsonorth.com" \
                                    --build-arg REDIS_HOST="${REDIS_HOST}" \
                                    --build-arg REDIS_PORT="${REDIS_PORT}" \
                                    --build-arg REDIS_PASSWORD="${REDIS_PASSWORD}" \
                                    --build-arg REDIS_QUEUE_NAME="${REDIS_QUEUE_NAME}" \
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
                            withCredentials([
                                string(credentialsId: 'MONGODB_URI', variable: 'MONGODB_URI'),
                                string(credentialsId: 'MONGODB_USERNAME', variable: 'MONGODB_USERNAME'),
                                string(credentialsId: 'MONGODB_PASSWORD', variable: 'MONGODB_PASSWORD'),
                                string(credentialsId: 'MONGODB_AUTH_SOURCE', variable: 'MONGODB_AUTH_SOURCE'),
                                string(credentialsId: 'DJANGO_SECRET_KEY', variable: 'DJANGO_SECRET_KEY'),
                                string(credentialsId: 'DJANGO_HOST', variable: 'DJANGO_HOST'),
                                string(credentialsId: 'DJANGO_ENV', variable: 'DJANGO_ENV'),
                                string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                                string(credentialsId: 'REDIS_PORT', variable: 'REDIS_PORT'),
                                string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                                string(credentialsId: 'REDIS_QUEUE_NAME', variable: 'REDIS_QUEUE_NAME')
                            ]) {
                                sh '''
                                    # 替換 deployment.yaml 中的環境變數
                                    envsubst < k8s/deployment.yaml > k8s/deployment.yaml.tmp
                                    mv k8s/deployment.yaml.tmp k8s/deployment.yaml
                                    
                                    # 部署到 Kubernetes
                                    kubectl apply -f k8s/deployment.yaml
                                    kubectl rollout restart deployment voyeur
                                '''
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