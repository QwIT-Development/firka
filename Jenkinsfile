pipeline {
    agent any
    environment {
        FLUTTER_ROOT = "/opt/flutter"
        FLUTTER = "/opt/flutter/bin/flutter"
        DART = "/opt/flutter/bin/dart"
        ANDROID_SDK_ROOT = "/opt/android-sdk"
        ANDROID_HOME = "/opt/android-sdk"
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
        stage('Setup') {
            steps {
                sh 'cp -r /opt/secrets firka/'
            }
        }
        stage('Codegen') {
            steps {
                sh '''
                    cd firka
                    PATH="/opt/flutter/bin:$PATH" $DART run scripts/codegen.dart
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''
                    cd firka
                    $FLUTTER config --android-sdk /opt/android-sdk
                    $FLUTTER build apk --debug
                    $FLUTTER build apk --release
                '''
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: 'firka/build/app/outputs/flutter-apk/app-debug.apk,firka/build/app/outputs/flutter-apk/app-release.apk',
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