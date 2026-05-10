pipeline {
    agent any

    environment {
        AWS_REGION         = 'us-east-1'
        ECR_REPO_NAME      = 'shopflow-app'
        TF_VAR_db_password = credentials('shopflow-db-password')
        IMAGE_TAG          = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Lint') {
            steps {
                sh '''
                    echo "Running Dockerfile lint..."
                    docker run --rm -i hadolint/hadolint < Dockerfile || true

                    echo "Running HTML lint..."
                    npx --yes htmlhint index.html || true
                '''
            }
        }

        stage('Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'my-aws',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        def accountId = sh(
                            script: '''
                                docker run --rm \
                                    -e AWS_REGION \
                                    -e AWS_ACCESS_KEY_ID \
                                    -e AWS_SECRET_ACCESS_KEY \
                                    amazon/aws-cli sts get-caller-identity \
                                    --query Account --output text
                            ''',
                            returnStdout: true
                        ).trim()

                        env.ECR_REGISTRY = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        env.IMAGE_URI    = "${env.ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
                        env.IMAGE_LATEST = "${env.ECR_REGISTRY}/${ECR_REPO_NAME}:latest"

                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} \\
                                | docker login --username AWS --password-stdin ${env.ECR_REGISTRY}

                            docker build -t ${env.IMAGE_URI} -t ${env.IMAGE_LATEST} .
                            docker push ${env.IMAGE_URI}
                            docker push ${env.IMAGE_LATEST}
                        """
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                    terraform init -input=false
                    terraform validate
                    terraform plan -input=false -out=tfplan \
                        -var-file=environments/dev/terraform.tfvars
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Deploy to AWS? Review the Terraform plan before approving.',
                          ok: 'Deploy'
                }
            }
        }

        stage('Deploy') {
            steps {
                sh 'terraform apply -input=false -auto-approve tfplan'
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    env.ALB_DNS = sh(
                        script: 'terraform output -raw alb_dns_name',
                        returnStdout: true
                    ).trim()

                    sh """
                        echo "Waiting for ALB to become healthy at ${env.ALB_DNS}..."
                        for i in \$(seq 1 12); do
                            STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${env.ALB_DNS} || echo '000')
                            echo "Attempt \$i: HTTP \$STATUS"
                            if [ "\$STATUS" = "200" ]; then
                                echo "Smoke test passed."
                                exit 0
                            fi
                            sleep 15
                        done
                        echo "Smoke test failed — ALB did not return 200 after 3 minutes."
                        exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully. ALB: ${env.ALB_DNS ?: 'n/a'}"
        }
        failure {
            echo 'Pipeline failed. Check logs above for details.'
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}