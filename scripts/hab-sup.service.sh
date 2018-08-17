mkdir -p /etc/systemd/system

environment_proxy=""
if [ ! -z "$HTTP_PROXY" ]; then
  environment_proxy="\"HTTP_PROXY=${HTTP_PROXY}\" "
fi
if [ ! -z "$HTTPS_PROXY" ]; then
  environment_proxy="\"HTTPS_PROXY=${HTTPS_PROXY}\" "
fi
if [ ! -z "${environment_proxy}" ]; then
  environment_proxy="Environment=${environment_proxy}"
fi

cat <<EOT > /etc/systemd/system/hab-sup.service
[Unit]
Description=Habitat Supervisor

[Service]
ExecStartPre=/bin/bash -c "/bin/systemctl set-environment SSL_CERT_FILE=$(hab pkg path core/cacerts)/ssl/cert.pem"
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
