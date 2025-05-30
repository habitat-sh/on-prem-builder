+++
title = "Habitat Builder logs"

[menu]
  [menu.habitat]
    title = "Logs"
    identifier = "habitat/on-prem-builder/logs"
    parent = "habitat/on-prem-builder"
    weight = 20
+++

## Supported log levels

The recognized values for logging are: `error`, `warn`, `info`, `debug`, and `trace`.
For a more detailed explanation of logging in Chef Habitat, see the [Supervisor Log Configuration Reference](https://www.habitat.sh/docs/reference/#supervisor-log-configuration-reference) and the [Supervisor Log Key](https://www.habitat.sh/docs/reference/#supervisor-log-key) documentation.

## Basic logging

To turn on and examine the services debug logging in your Habitat installation:

1. Open the `/hab/user/builder-api/config/user.toml` file.
1. On the first line, set the value of `log_level`:

    ```toml
    log_level="<LOG_LEVEL>,tokio_core=error,tokio_reactor=error,zmq=error,hyper=error"
    ```

    Replace `<LOG_LEVEL>` with the log level, for example `debug` or `error`.

1. Save and close the file.
1. Restart Habitat:

    ```sh
    sudo systemctl restart hab-sup
    ```

1. Use `journalctl -fu hab-sup` to view the logs.

## Configure Rust logging

You can use the `RUST_LOG` environment variable to view detailed logging and configure backtraces in Habitat Builder.

To see an individual Habitat command's debug and backtrace, run the following command:

- ```bash
  # Linux/macOS
  env RUST_LOG=debug RUST_BACKTRACE=1 <HAB_COMMAND>
  ```

  Replace <HAB_COMMAND> with a Habitat CLI command, for example `hab sup run`.

To configure rust logging in Habitat Builder, follow these steps:

1. Open the `/hab/svc/builder-api/user.toml` file.
1. Change the second line to the following:

    ```toml
    RUST_LOG=debug RUST_BACKTRACE=1
    ```

### Log Rotation

The `builder-api-proxy` service will log (via Nginx) all access and errors to log files in your service directory. Since these files may get large, you may want to add a log rotation script. Below is a sample logrotate file that you can use as an example for your needs:

```bash
/hab/svc/builder-api-proxy/logs/host.access.log
/hab/svc/builder-api-proxy/logs/host.error.log
{
        rotate 7
        daily
        missingok
        notifempty
        delaycompress
        compress
        postrotate
                /bin/kill -USR1 `cat /hab/svc/builder-api-proxy/var/pid 2>/dev/null` 2>/dev/null || true
        endscript
}
```
