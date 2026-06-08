pipeline {
    agent any
    environment {
        FLUTTER_ROOT = "/home/jenkins/flutter"
        PATH = "/home/jenkins/flutter/bin:${env.PATH}"
    }
    stages {

    stage('Debug') {
    steps {
        sh '''
            echo "shell binary: $(readlink /proc/$$/exe)"
            echo "which bash: $(which bash)"
            echo "which flutter: $(which flutter || echo NOT FOUND)"
            /home/jenkins/flutter/bin/flutter --version
        '''
    }
}
        stage('Clone Submodules') {
            steps {
                sh 'git submodule update --init --recursive'
            }
        }
        stage('Environment') {
            steps {
                sh '''
                    export PATH="/home/jenkins/flutter/bin:$PATH"
                    flutter --version
                    dart --version
                    flutter doctor -v
                '''
            }
        }
        stage('Dependencies') {
            steps {
                sh '''
                    export PATH="/home/jenkins/flutter/bin:$PATH"
                    cd firka
                    flutter pub get
                '''
            }
        }
        stage('Codegen') {
            steps {
                sh '''
                    export PATH="/home/jenkins/flutter/bin:$PATH"
                    cd firka
                    dart run scripts/codegen.dart
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''
                    export PATH="/home/jenkins/flutter/bin:$PATH"
                    cd firka
                    flutter build apk --debug
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