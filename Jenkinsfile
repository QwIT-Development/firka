pipeline {
agent any

environment {
    FLUTTER_ROOT = "/home/jenkins/flutter"
    PATH = "/home/jenkins/flutter/bin:${env.PATH}"
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
                echo "PATH=$PATH"

                which flutter
                flutter --version

                which dart
                dart --version

                flutter doctor -v
            '''
        }
    }

    stage('Dependencies') {
        steps {
            sh '''
                cd firka
                flutter pub get
            '''
        }
    }

    stage('Codegen') {
        steps {
            sh '''
                cd firka
                dart run scripts/codegen.dart
            '''
        }
    }

    stage('Build') {
        steps {
            sh '''
                cd firka
                flutter build apk --debug
            '''
        }
    }

    stage('Archive') {
        steps {
            archiveArtifacts(
                artifacts: 'firka/build/app/outputs/flutter-apk/app-release.apk',
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
