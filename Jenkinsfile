pipeline {                                // declarative pipeline 
    agent { node { label 'Agent-1' } }
    parameters {
        string(name: 'Version', defaultValue: '1.0.1', description: 'Which version to deploy')
    }
    environment{ 
        // here if you create any variable it will have global access because it is env varialble
        version = ''
    }
    stages {
        // Here I need to configure downstream job and I have to pass package version for deployment
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