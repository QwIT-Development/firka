pipeline {
    agent any
    environment {
        FLUTTER_ROOT = "/home/jenkins/flutter"
        FLUTTER = "/home/jenkins/flutter/bin/flutter"
        DART = "/home/jenkins/flutter/bin/dart"
    }
    stages {
        stage('Clone Submodules') {
            steps {
                sh 'git submodule update --init --recursive'
            }
        }
        stage('Environment') {
            steps {
                sh '''
                    $FLUTTER --version
                    $DART --version
                    $FLUTTER doctor -v
                '''
            }
        }
        stage('Dependencies') {
            steps {
                sh '''
                    cd firka
                    $FLUTTER pub get
                '''
            }
        }
        stage('Codegen') {
            steps {
                sh '''
                    cd firka
                    $DART run scripts/codegen.dart
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''
                    cd firka
                    $FLUTTER build apk --debug
                '''
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: 'firka/build/app/outputs/flutter-apk/app-debug.apk',
                    fingerprint: true
                )
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}