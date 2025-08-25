pipeline {
    agent {
        label 'ubuntu'
    }
    environment {
        PATH = "/home/jenkins/development/flutter/bin:${env.PATH}"
    }
    stages {
        stage('Pre-build Cleanup') {
            steps {
                script {
                    sh '''#!/bin/sh
                    set -x
                    fusermount -u secrets || true
                    '''
                }
            }
        }
        stage('Decrypt main keys') {
            when {
                branch 'main'
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
        stage('Rename Release APKs') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''#!/bin/sh
                    set -e
                    
                    APK_DIR="firka/build/app/outputs/flutter-apk"
                    
                    # Find all release APKs and rename them
                    for apk_file in $APK_DIR/app-*-release.apk; do
                        if [ -f "$apk_file" ]; then
                            # Extract ABI from filename (e.g., app-arm64-v8a-release.apk -> arm64-v8a)
                            basename_file=$(basename "$apk_file")
                            abi=$(echo "$basename_file" | sed 's/app-//; s/-release.apk//')
                            
                            # Create new filename
                            new_name="app.firka.naplo_${abi}.apk"
                            new_path="$APK_DIR/$new_name"
                            
                            echo "Renaming $apk_file to $new_path"
                            mv "$apk_file" "$new_path"
                        fi
                    done
                    
                    ls -la $APK_DIR/app.firka.naplo_*.apk || echo "APK files not found"
                    '''
                }
            }
        }
        stage('Publish release artifacts') {
            when {
                branch 'main'
            }
            steps {
                archiveArtifacts artifacts: 'firka/build/app/outputs/flutter-apk/app.firka.naplo_*.apk', fingerprint: true
            }
        }
        stage('Publish debug artifacts') {
            when {
                not {
                    branch 'main'
                }
            }
            steps {
                archiveArtifacts artifacts: 'firka/build/app/outputs/flutter-apk/app-debug.apk', fingerprint: true
            }
        }
        stage('Upload to F-Droid Debug') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'fdroid-ssh', usernameVariable: 'SSH_USER', passwordVariable: 'SSHPASS')]) {
                        sh '''
                            SOURCE_FILE="firka/build/app/outputs/flutter-apk/app-debug.apk"
                            REMOTE_PATH="/home/fdroid/firka-fdroid/repo/app.firka.naplo.debug.apk"                            
                            export SSHPASS
                            
                            sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                "$SOURCE_FILE" "$SSH_USER@10.0.0.21:$REMOTE_PATH"
                            sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                "$SSH_USER@10.0.0.21" \
                                "cd /home/fdroid/firka-fdroid && /run/current-system/sw/bin/fdroid update"
                        '''
                    }
                }
            }
        }
        stage('Upload to F-Droid Release') {
            when {
                branch 'main'
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'fdroid-ssh', usernameVariable: 'SSH_USER', passwordVariable: 'SSHPASS')]) {
                        sh '''
                    # Use the renamed APK files
                    REMOTE_PATH="/home/fdroid/firka-fdroid/repo/"
                    export SSHPASS
                    
                    # Loop over each APK file and upload it one by one
                    for SOURCE_FILE in firka/build/app/outputs/flutter-apk/app.firka.naplo_*.apk; do
                        if [ -f "$SOURCE_FILE" ]; then
                            echo "Uploading $SOURCE_FILE to $REMOTE_PATH"
                            sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                "$SOURCE_FILE" "$SSH_USER@10.0.0.21:$REMOTE_PATH"
                        else
                            echo "No APK files found to upload."
                        fi
                    done
                    
                    # Update F-Droid repository
                    sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                        "$SSH_USER@10.0.0.21" \
                        "cd /home/fdroid/firka-fdroid && /run/current-system/sw/bin/fdroid update"
                        '''
                    }
                }
            }
        }
        stage('Post Cleanup') {
            steps {
                script {
                    sh '''
                    rm firka/build/app/outputs/flutter-apk/app.firka.naplo_*.apk || true
                    rm firka/build/app/outputs/flutter-apk/app-debug.apk || true
                    git checkout -- firka/pubspec.yaml
                    '''
                }
            }
        }
    }
}