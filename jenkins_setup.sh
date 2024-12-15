#!/bin/bash
set -e

read -p "Enter Docker Registry URL (e.g., localhost:5000): " DOCKER_REGISTRY
if [[ "$DOCKER_REGISTRY" == localhost:* ]]; then
    echo "Local Docker registry detected. No username or password required."
    DOCKER_USER="null"
    DOCKER_PASS="null"
else
echo "### Local Jenkins Setup Automation ###"
echo "If you are using Docker Hub, enter your Docker Hub username and password either press only Enter key, you don't need any password."
read -p "Enter Docker Username: " DOCKER_USER
read -sp "Enter Docker Password: " DOCKER_PASS
fi

cat <<EOF > jenkins_config.env
### Local Jenkins Setup Automation ###
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_PASS=$DOCKER_PASS
EOF

read -p "Will you use a private Git repository? (y/n): " USE_PRIVATE_REPO
if [[ "$USE_PRIVATE_REPO" == "y" ]]; then
    read -p "Enter the path to your SSH private key (e.g., .ssh/id_rsa): " SSH_KEY_PATH
fi

echo "Configuration saved to jenkins_config.env."
ansible-playbook -i localhost, -c local playbook.yml --extra-vars "ansible_python_interpreter=/usr/bin/python3.12"

JENKINS_CLI="/usr/local/bin/jenkins-cli.jar"
JENKINS_URL="http://localhost:8090"
ADMIN_USER="admin"
THE_PASS=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
ADMIN_PASS="$THE_PASS"

echo "password: $THE_PASS"

echo "Configuring Docker registry credentials for Jenkins..."
mkdir -p /var/lib/jenkins/.docker
echo '{ "auths": { "'"${DOCKER_REGISTRY}"'": { "auth": "'"$(echo -n "${DOCKER_USER}:${DOCKER_PASS}" | base64)"'" } } }' > /var/lib/jenkins/.docker/config.json
chown -R jenkins:jenkins /var/lib/jenkins/.docker

if [[ "$USE_PRIVATE_REPO" == "y" ]]; then
    echo "Copying SSH key for Jenkins..."
    mkdir -p /var/lib/jenkins/.ssh
    cp "${SSH_KEY_PATH}" /var/lib/jenkins/.ssh/id_rsa
    chmod 600 /var/lib/jenkins/.ssh/id_rsa
    chown jenkins:jenkins /var/lib/jenkins/.ssh/id_rsa

    echo "Adding known hosts for GitHub..."
    ssh-keyscan github.com >> /var/lib/jenkins/.ssh/known_hosts
fi

echo "Testing Jenkins CLI login..."
if ! java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" -auth "${ADMIN_USER}:${ADMIN_PASS}" who-am-i; then
    echo "Jenkins CLI authentication failed. Exiting..."
    exit 1
fi

echo "Installing Jenkins plugins..."
PLUGINS=(
    "configuration-as-code:1850.va_a_8c31d3158b_"
    "credentials:1389.vd7a_b_f5fa_50a_2"
    "plain-credentials:183.va_de8f1dd5a_2b_"
    "ssh-credentials:349.vb_8b_6b_9709f5b_"
    "credentials-binding:687.v619cb_15e923f"
    "git:5.6.0"
    "git-client:6.1.0"
    "job-dsl:1.90"
    "role-strategy:743.v142ea_b_d5f1d3"
)

for plugin in "${PLUGINS[@]}"; do
    echo "Installing plugin: $plugin"
    java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" -auth "${ADMIN_USER}:${ADMIN_PASS}" install-plugin "$plugin"
done

echo "Restarting Jenkins to apply plugins..."
java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" -auth "${ADMIN_USER}:${ADMIN_PASS}" safe-restart

sudo sed -i '/Environment="CASC_JENKINS_CONFIG/d' /lib/systemd/system/jenkins.service
sudo sed -i '/Environment="JAVA_OPTS/d' /lib/systemd/system/jenkins.service

sudo sed -i '/^\[Service\]/a Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/my_whanos.yml"' /lib/systemd/system/jenkins.service
sudo sed -i '/^\[Service\]/a Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false"' /lib/systemd/system/jenkins.service

sudo systemctl daemon-reload
sudo systemctl restart jenkins

echo "Removing initial admin password file..."
sudo rm -f /var/lib/jenkins/secrets/initialAdminPassword
sudo chown -R jenkins:jenkins /var/lib/jenkins/

echo "Restarting Jenkins..."
sudo systemctl daemon-reload
sudo systemctl restart jenkins

echo "### Jenkins Setup Complete! ###"
echo "Docker registry configured."
[[ "$USE_PRIVATE_REPO" == "y" ]] && echo "SSH keys configured for private repositories."
echo "Installed plugins:"
for plugin in "${PLUGINS[@]}"; do
    echo " - $plugin"
done
echo "Access Jenkins at: ${JENKINS_URL}"
