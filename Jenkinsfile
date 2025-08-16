pipeline {
    agent  { label 'ubuntu' }
    environment {
        PATH = "/home/jenkins/development/flutter/bin:${env.PATH}"
    }

    stages {
        stage('Cleanup') {
            steps {
                script {
                    sh '''#!/bin/sh
                    set -x
                    fusermount -u secrets || true
                    '''
                }
            }
        }

        stage('Decrypt keys') {
            when {
                branch 'play'
            }
            steps {
                script {
                    def userInput = input(
                        id: 'signaturePassword',
                        message: 'Please enter the signing key password:',
                        parameters: [
                            password(
                                defaultValue: '',
                                description: 'Enter the signing key password',
                                name: 'password'
                            )
                        ]
                    )

                    env.PASSWORD = userInput.toString()
                }

                sh '''#!/bin/sh
                echo \$PASSWORD | gocryptfs $HOME/android_secrets secrets/ -nonempty
                '''
            }
        }

        stage('Clone submodules') {
            steps {
                script {
                    sh 'git submodule update --init --recursive'
                }
            }
        }

        stage('Build firka') {
            steps {
                sh 'bash -c "./tools/linux/build_apk.sh ' + env.BRANCH_NAME + '"'
            }
        }

        stage('Publish release artifacts') {
            when {
                branch 'play'
            }
            steps {
                archiveArtifacts artifacts: 'firka/build/app/outputs/bundle/*.aab', fingerprint: true
                sh 'rm firka/build/app/outputs/bundle/*.aab'
            }
        }

        stage('Publish debug artifacts') {
            when {
                not {
                    branch 'play'
                }
            }
            steps {
                archiveArtifacts artifacts: 'firka/build/app/outputs/flutter-apk/app-debug.apk', fingerprint: true
                sh 'rm firka/build/app/outputs/flutter-apk/app-debug.apk'
            }
        }
    }
}
