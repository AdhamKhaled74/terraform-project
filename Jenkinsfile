pipeline {
    agent any

    environment {
        AWS_REGION          = 'us-east-1'
        ECR_REPO_NAME       = 'shopflow-app'
        TF_VAR_db_password  = credentials('shopflow-db-password')
        IMAGE_TAG           = "${env.BUILD_NUMBER}"
    }

    stages {

        // ── Stage 1: Lint ──────────────────────────────────────────────────
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

        // ── Stage 2: Docker Build & Push to ECR ───────────────────────────
        stage('Docker Build & Push') {
            steps {
                script {
                    def accountId = sh(
                        script: "aws sts get-caller-identity --query Account --output text",
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    env.IMAGE_URI    = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
                    env.IMAGE_LATEST = "${ECR_REGISTRY}/${ECR_REPO_NAME}:latest"

                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} \\
                            | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        docker build -t ${IMAGE_URI} -t ${IMAGE_LATEST} .

                        docker push ${IMAGE_URI}
                        docker push ${IMAGE_LATEST}
                    """
                }
            }
        }

        // ── Stage 3: Terraform Validate & Plan ────────────────────────────
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

        // ── Stage 4: Manual Approval ───────────────────────────────────────
        stage('Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Deploy to AWS? Review the Terraform plan before approving.',
                          ok: 'Deploy'
                }
            }
        }

        // ── Stage 5: Terraform Apply ───────────────────────────────────────
        stage('Deploy') {
            steps {
                sh '''
                    terraform apply -input=false -auto-approve tfplan
                '''
            }
        }

        // ── Stage 6: Smoke Test ────────────────────────────────────────────
        stage('Smoke Test') {
            steps {
                script {
                    def albDns = sh(
                        script: "terraform output -raw alb_dns_name",
                        returnStdout: true
                    ).trim()

                    sh """
                        echo "Waiting for ALB to become healthy..."
                        for i in \$(seq 1 12); do
                            STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://${albDns} || echo '000')
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
            echo "Pipeline completed successfully. ALB: \$(terraform output -raw alb_dns_name)"
        }
        failure {
            echo "Pipeline failed. Check logs above for details."
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}
