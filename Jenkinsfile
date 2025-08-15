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
        DOCKER_IMAGE_PRODUCER = 'papakao/voyeur-producer'
        DOCKER_IMAGE_CONSUMER = 'papakao/voyeur-consumer'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DJANGO_HOST = 'peoplesystem.tatdvsonorth.com'
        DJANGO_ENV = 'production'
        MONGODB_DB = 'palais'
        MONGODB_COLLECTION = 'tyf_visits'
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
                            string(credentialsId: 'VOYEUR_SECRET_KEY', variable: 'VOYEUR_SECRET_KEY'),
                            string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                            string(credentialsId: 'REDIS_CUSTOM_PORT', variable: 'REDIS_CUSTOM_PORT'),
                            string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                            string(credentialsId: 'REDIS_QUEUE_VOYEUR', variable: 'REDIS_QUEUE_VOYEUR'),
                            string(credentialsId: 'WEBSOCKET_TYMB', variable: 'WEBSOCKET_TYMB')
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

        stage('Build Docker Images') {
            steps {
                container('docker') {
                    script {
                        withCredentials([
                            usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                            string(credentialsId: 'MONGODB_URI', variable: 'MONGODB_URI'),
                            string(credentialsId: 'MONGODB_USERNAME', variable: 'MONGODB_USERNAME'),
                            string(credentialsId: 'MONGODB_PASSWORD', variable: 'MONGODB_PASSWORD'),
                            string(credentialsId: 'MONGODB_AUTH_SOURCE', variable: 'MONGODB_AUTH_SOURCE'),
                            string(credentialsId: 'VOYEUR_SECRET_KEY', variable: 'VOYEUR_SECRET_KEY'),
                            string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                            string(credentialsId: 'REDIS_CUSTOM_PORT', variable: 'REDIS_CUSTOM_PORT'),
                            string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                            string(credentialsId: 'REDIS_QUEUE_VOYEUR', variable: 'REDIS_QUEUE_VOYEUR'),
                            string(credentialsId: 'WEBSOCKET_TYMB', variable: 'WEBSOCKET_TYMB')
                        ]) {
                            sh '''
                                echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                                
                                # 構建並推送 Producer 鏡像
                                docker build \
                                    --target producer \
                                    --build-arg BUILDKIT_INLINE_CACHE=1 \
                                    --build-arg MONGODB_URI="${MONGODB_URI}" \
                                    --build-arg MONGODB_USERNAME="${MONGODB_USERNAME}" \
                                    --build-arg MONGODB_PASSWORD="${MONGODB_PASSWORD}" \
                                    --build-arg MONGODB_AUTH_SOURCE="${MONGODB_AUTH_SOURCE}" \
                                    --build-arg MONGODB_DB="${MONGODB_DB}" \
                                    --build-arg MONGODB_COLLECTION="${MONGODB_COLLECTION}" \
                                    --build-arg VOYEUR_SECRET_KEY="${VOYEUR_SECRET_KEY}" \
                                    --build-arg DJANGO_HOST="${DJANGO_HOST}" \
                                    --build-arg DJANGO_ENV="${DJANGO_ENV}" \
                                    --build-arg DJANGO_ALLOWED_HOSTS="peoplesystem.tatdvsonorth.com" \
                                    --build-arg REDIS_HOST="${REDIS_HOST}" \
                                    --build-arg REDIS_CUSTOM_PORT="${REDIS_CUSTOM_PORT}" \
                                    --build-arg REDIS_PASSWORD="${REDIS_PASSWORD}" \
                                    --build-arg REDIS_QUEUE_VOYEUR="${REDIS_QUEUE_VOYEUR}" \
                                    --build-arg WEBSOCKET_TYMB="${WEBSOCKET_TYMB}" \
                                    --cache-from ${DOCKER_IMAGE_PRODUCER}:latest \
                                    -t ${DOCKER_IMAGE_PRODUCER}:${DOCKER_TAG} \
                                    -t ${DOCKER_IMAGE_PRODUCER}:latest \
                                    .
                                docker push ${DOCKER_IMAGE_PRODUCER}:${DOCKER_TAG}
                                docker push ${DOCKER_IMAGE_PRODUCER}:latest
                                
                                # 構建並推送 Consumer 鏡像
                                docker build \
                                    --target consumer \
                                    --build-arg REDIS_HOST="${REDIS_HOST}" \
                                    --build-arg REDIS_CUSTOM_PORT="${REDIS_CUSTOM_PORT}" \
                                    --build-arg REDIS_PASSWORD="${REDIS_PASSWORD}" \
                                    --build-arg REDIS_QUEUE_VOYEUR="${REDIS_QUEUE_VOYEUR}" \
                                    --cache-from ${DOCKER_IMAGE_CONSUMER}:latest \
                                    -t ${DOCKER_IMAGE_CONSUMER}:${DOCKER_TAG} \
                                    -t ${DOCKER_IMAGE_CONSUMER}:latest \
                                    .
                                docker push ${DOCKER_IMAGE_CONSUMER}:${DOCKER_TAG}
                                docker push ${DOCKER_IMAGE_CONSUMER}:latest
                            '''
                        }
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
                                string(credentialsId: 'VOYEUR_SECRET_KEY', variable: 'VOYEUR_SECRET_KEY'),
                                string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                                string(credentialsId: 'REDIS_CUSTOM_PORT', variable: 'REDIS_CUSTOM_PORT'),
                                string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                                string(credentialsId: 'REDIS_QUEUE_VOYEUR', variable: 'REDIS_QUEUE_VOYEUR'),
                                string(credentialsId: 'WEBSOCKET_TYMB', variable: 'WEBSOCKET_TYMB')
                            ]) {
                                sh '''
                                    # 替換 deployment.yaml 中的環境變數
                                    envsubst < k8s/deployment.yaml > k8s/deployment.yaml.tmp
                                    mv k8s/deployment.yaml.tmp k8s/deployment.yaml
                                    
                                    # 部署 Producer
                                    kubectl apply -f k8s/deployment.yaml
                                    kubectl rollout restart deployment voyeur
                                    
                                    # 部署 Consumer
                                    kubectl apply -f k8s/voyeur-consumer.yaml
                                    kubectl rollout restart deployment voyeur-consumer
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