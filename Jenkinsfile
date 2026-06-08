pipeline {
    agent any
    environment {
        PATH = "/home/jenkins/development/flutter/bin:${env.PATH}"
    }
    stages {
        stage('Clone Submodules') {
            steps {
                sh 'git submodule update --init --recursive'
            }
        }
        stage('Flutter Doctor') {
            steps {
                sh 'flutter doctor'
            }
        }
        stage('Dependencies') {
            steps {
                sh 'cd firka && flutter pub get'
            }
        }
        stage('Codegen') {
            steps {
                sh 'cd firka && dart run scripts/codegen.dart'
            }
        }
        stage('Build') {
            steps {
                sh 'cd firka && flutter build apk --debug'
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'firka/build/app/outputs/flutter-apk/app-debug.apk',
                                 fingerprint: true
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}