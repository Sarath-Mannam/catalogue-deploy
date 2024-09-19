pipeline {                                // declarative pipeline 
    agent { node { label 'Agent-1' } }
    environment{ 
        // here if you create any variable it will have global access because it is env varialble
        version = ''
    }
    stages {
        stage('Deploy') {
            steps{
                echo "Deploying..."
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