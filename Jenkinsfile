pipeline {
    agent any

    parameters {
        string(name: 'TARGET_IP', defaultValue: 'drow-ubuntu', description: 'Target IP/Hostname:\nEnter the IP address or hostname of the target VM', trim: true)
    }

    environment {
        CREDENTIALS_ID = '520f47af-4c1c-4fa1-9e24-0f16c715c04b' // Update with your Jenkins credentials ID
        SSHPASS_CMD = '/usr/local/bin/sshpass' // Ensure this path matches your environment
        PATH = "/usr/local/bin:/usr/local/sbin:$PATH" // Explicitly add /usr/local/bin to PATH
    }

    stages {
        stage('Checkout Script') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/Dr0w/Linux-Scripts.git']]])
            }
        }

        stage('Copy Script to VM') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${CREDENTIALS_ID}", usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                        sh '''
                        set -x
                        ${SSHPASS_CMD} -p "$SSH_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$WORKSPACE/packages_update.sh" "$SSH_USER@$TARGET_IP:~/packages_update.sh"
                        '''
                    }
                }
            }
        }

        stage('Make Script Executable') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${CREDENTIALS_ID}", usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                        sh '''
                        ${SSHPASS_CMD} -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$TARGET_IP" "chmod +x ~/packages_update.sh"
                        '''
                    }
                }
            }
        }

        stage('Execute Script') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${CREDENTIALS_ID}", usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                        sh '''
                        ${SSHPASS_CMD} -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$TARGET_IP" "echo '$SSH_PASS' | sudo -S ~/packages_update.sh"
                        '''
                    }
                }
            }
        }
    }
}
