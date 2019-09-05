mkdir -p /etc/systemd/system

environment_proxy=""
if [ ! -z "$HTTP_PROXY" ]; then
  environment_proxy="${environment_proxy}
Environment=\"HTTP_PROXY=${HTTP_PROXY}\""
elif [ ! -z "$http_proxy" ]; then
    environment_proxy="${environment_proxy}
Environment=\"HTTP_PROXY=${http_proxy}\""
fi
if [ ! -z "$HTTPS_PROXY" ]; then
  environment_proxy="${environment_proxy}
Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\""
elif [ ! -z "$https_proxy" ]; then
  environment_proxy="${environment_proxy}
Environment=\"HTTPS_PROXY=${https_proxy}\""
fi
if [ ! -z "$HAB_BLDR_URL" ]; then
  environment_proxy="${environment_proxy}
Environment=\"HAB_BLDR_URL=${HAB_BLDR_URL}\""
fi
if [ ! -z "$NO_PROXY" ]; then
  environment_proxy="${environment_proxy}
Environment=\"NO_PROXY=${NO_PROXY}\""
elif [ ! -z "$no_proxy" ]; then
  environment_proxy="${environment_proxy}
Environment=\"NO_PROXY=${no_proxy}\""
fi
if [ -z "$SSL_CERT_FILE" ]; then
  SSL_CERT_FILE="$(hab pkg path core/cacerts)/ssl/cert.pem"
fi

cat <<EOT > /etc/systemd/system/hab-sup.service
[Unit]
Description=Habitat Supervisor

[Service]
ExecStartPre=/bin/bash -c "/bin/systemctl set-environment SSL_CERT_FILE=${SSL_CERT_FILE}"
ExecStart=/bin/hab sup run
ExecStop=/bin/hab sup term
KillMode=process
LimitNOFILE=65535
${environment_proxy}

[Install]
WantedBy=default.target
EOT

systemctl daemon-reload
systemctl start hab-sup
systemctl enable hab-sup

# wait for the sup to come up before proceeding.
until hab svc status > /dev/null 2>&1; do
  sleep 1
done
