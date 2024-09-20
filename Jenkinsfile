pipeline {                                // declarative pipeline 
    agent { node { label 'Agent-1' } }
    options {
        ansiColor('xterm')
    }
    parameters {
        string(name: 'version', defaultValue: '1.0.1', description: 'Which version to deploy')
    }
    stages {
        stage('Deploy') {
            steps{
                echo "Deploying..."
                echo "Version from params: ${params.version}"
            }
        }
        stage('Init') {
            steps{
                sh """
                cd terraform
                terraform init -reconfigure
                """
            }
        }
        stage('Plan') {
            steps{
                sh """
                cd terraform
                terraform plan
                """
            }
        }
    }
    
    post{
        always{
            echo 'cleaning up workspace'
            deleteDir()
        }
    }
}