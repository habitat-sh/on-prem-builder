mkdir -p /etc/systemd/system

environment_proxy=""
if [ ! -z "$HTTP_PROXY" ]; then
  environment_proxy="${environment_proxy}
Environment=\"HTTP_PROXY=${HTTP_PROXY}\""
fi
if [ ! -z "$HTTPS_PROXY" ]; then
  environment_proxy="${environment_proxy}
Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\""
fi
if [ ! -z "$NO_PROXY" ]; then
  environment_proxy="${environment_proxy}
Environment=\"NO_PROXY=${NO_PROXY}\""
fi
if [ -z "$SSL_CERT_FILE" ]; then
  SSL_CERT_FILE="$(hab pkg path core/cacerts)/ssl/cert.pem"
fi

cat <<EOT > /etc/systemd/system/hab-sup.service
[Unit]
Description=Habitat Supervisor

[Service]
ExecStartPre=/bin/bash -c "/bin/systemctl set-environment SSL_CERT_FILE=${SSL_CERT_FILE}"
ExecStart=/bin/hab run
${environment_proxy}

[Install]
WantedBy=default.target
EOT

systemctl daemon-reload
systemctl start hab-sup

# wait for the sup to come up before proceeding.
until hab svc status > /dev/null 2>&1; do
  sleep 1
done
