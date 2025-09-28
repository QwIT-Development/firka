pipeline {
    agent {
        label 'ubuntu'
    }
    environment {
        FLUTTER_HOME = tool('FlutterSDK')
        PATH = "${FLUTTER_HOME}/bin:${env.PATH}"
        // top 10 how to leak the user directory
        // PATH = "/home/jenkins/development/flutter/bin:${env.PATH}"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        // removed unnecessary crypto cockriding
        stage('Build firka') {
            steps {
                script {
                    def commitCount = sh(returnStdout: true, script: 'git rev-list --count HEAD').trim()
                    // simple cleanup
                    sh 'flutter clean'
                    sh 'flutter pub get'
                    sh "flutter build apk --release --build-name=1.0.${commitCount} --build-number=${commitCount}"
                    sh "flutter build appbundle --release --build-name=1.0.${commitCount} --build-number=${commitCount}"
                }
            }
        }
        stage('Publish artifacts') {
            when {branch 'main'}
            steps {
                archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk', fingerprint: true
                archiveArtifacts artifacts: 'build/app/outputs/bundle/release/app-release.aab', fingerprint: true
            }
        }
        stage('Upload to F-Droid Release') {
            when {
                branch 'main'
            }
            steps {
                sshagent(credentials: ['fdroid-ssh-key']) {
                    script {
                        // how to leak the internal infra ip in easy steps
                        // (was 10.0.0.21) i leave this here, so the "devs" can learn
                        withCredentials([
                            string(credentialsId: 'fdroid-host-ip', variable: 'REMOTE_HOST'),
                            string(credentialsId: 'fdroid-remote-user', variable: 'REMOTE_USER'),
                            string(credentialsId: 'fdroid-remote-path', variable: 'REMOTE_BASE_PATH')
                        ]) {
                            // the so called devs will fix their hardcoded paths later
                            def apkDir = "firka/build/app/outputs/flutter-apk"
                            def metadataFile = "${REMOTE_BASE_PATH}/metadata/app.firka.naplo.yml"
                            def remoteRepoPath = "${REMOTE_BASE_PATH}/repo/"
                            def apks = findFiles(glob: "${apkDir}/app-*-release.apk")
                            if (apks.isEmpty()) {
                                error "No APK files found to upload."
                            }
                            for (apk in apks) {
                                echo "Uploading ${apk.path}..."
                                sh "scp ${apk.path} ${REMOTE_USER}@${REMOTE_HOST}:${remoteRepoPath}"
                            }
                            sh """
                                ssh ${REMOTE_USER}@${REMOTE_HOST} "sed -i 's/^CurrentVersionCode: .*/CurrentVersionCode: ${env.VERSION_CODE}/' ${metadataFile}"
                            """
                            sh """
                                ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_BASE_PATH} && fdroid update"
                            """
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            // this will always run, even if there's an error (woah)
            cleanWs()
        }
    }
}