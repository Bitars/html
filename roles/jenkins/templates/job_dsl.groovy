folder('Tools') {
    displayName('Tools')
    description('Folder for miscellaneous tools.')

    job('Tools/clone-repository') {
        description('Clones a Git repository and builds a Docker image.')
        wrappers {
            preBuildCleanup()
        }
        parameters {
            stringParam('GIT_REPOSITORY_URL', '', 'Git URL of the repository to clone')
        }
        steps {
            shell('''
                REPO_NAME=$(basename $GIT_REPOSITORY_URL .git)
                echo "Repository name: $REPO_NAME"
                echo "Current workspace: $(pwd)"
                echo "Contents of workspace:"
                ls -la
                chmod +x /var/lib/jenkins/k3s.sh

                echo "Removing existing html and app directories if any"
                rm -rf html app

                echo "Cloning repository: $GIT_REPOSITORY_URL"
                git clone $GIT_REPOSITORY_URL

                echo "Removing .git directory in workspace if it exists to prevent overwrite issues"
                rm -rf .git

                echo "Moving repository contents to the workspace root"
                mv html/* html/.[!.]* .
                rm -rf html

                echo "Workspace contents after moving:"
                ls -la

                echo "Ensuring detect_language.sh is executable"
                chmod +x /var/lib/jenkins/detect_language.sh

                echo "Running detect_language.sh with workspace root:"
                /var/lib/jenkins/detect_language.sh .

            ''')
        }

    }
    job('Tools/buil-and-push-BaseImages') {
        steps {
            shell('''
                chmod +x /var/lib/jenkins/pushBase.sh
                /var/lib/jenkins/pushBase.sh .
            ''')
        }
    }
}
