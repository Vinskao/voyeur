pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins-admin
                  imagePullSecrets:
                  - name: dockerhub-credentials
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
                    withCredentials([
                        string(credentialsId: 'MONGODB_URI', variable: 'MONGODB_URI'),
                        string(credentialsId: 'VOYEUR_SECRET_KEY', variable: 'VOYEUR_SECRET_KEY'),
                        string(credentialsId: 'REDIS_HOST', variable: 'REDIS_HOST'),
                        string(credentialsId: 'REDIS_CUSTOM_PORT', variable: 'REDIS_CUSTOM_PORT'),
                        string(credentialsId: 'REDIS_PASSWORD', variable: 'REDIS_PASSWORD'),
                        string(credentialsId: 'REDIS_QUEUE_VOYEUR', variable: 'REDIS_QUEUE_VOYEUR'),
                        string(credentialsId: 'WEBSOCKET_TYMB', variable: 'WEBSOCKET_TYMB'),
                        usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')
                    ]) {
                        script {
                            sh '''
                                set -e

                                # 確認叢集可用（使用 Pod SA jenkins-admin）
                                kubectl cluster-info

                                # 確保 default namespace 有 imagePullSecret（若不存在則建立/更新）
                                kubectl create secret docker-registry dockerhub-credentials \
                                  --docker-server=https://index.docker.io/v1/ \
                                  --docker-username="${DOCKER_USERNAME}" \
                                  --docker-password="${DOCKER_PASSWORD}" \
                                  --docker-email="none" \
                                  -n default \
                                  --dry-run=client -o yaml | kubectl apply -f -

                                # 檢查檔案
                                ls -la k8s/

                                # 產生並套用 Producer 的 Secret + Deployment（k8s/deployment.yaml 內含 Secret 與 Deployment）
                                envsubst < k8s/deployment.yaml > k8s/deployment.effective.yaml
                                kubectl apply -f k8s/deployment.effective.yaml

                                # 若 Deployment 已存在則更新 image，確保使用新 tag
                                if kubectl get deployment voyeur -n default >/dev/null 2>&1; then
                                  kubectl set image deployment/voyeur voyeur=${DOCKER_IMAGE_PRODUCER}:${DOCKER_TAG} -n default
                                fi
                                kubectl rollout status deployment/voyeur -n default

                                # Consumer：存在則滾動更新，否則套用 yaml
                                if kubectl get deployment voyeur-consumer -n default >/dev/null 2>&1; then
                                  kubectl set image deployment/voyeur-consumer voyeur-consumer=${DOCKER_IMAGE_CONSUMER}:${DOCKER_TAG} -n default
                                else
                                  kubectl apply -f k8s/voyeur-consumer.yaml
                                fi
                                kubectl rollout status deployment/voyeur-consumer -n default

                                # 檢視狀態
                                kubectl get deploy,po,svc -n default
                            '''
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