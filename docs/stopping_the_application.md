# Stopping the Application

The application should be shut down gracefully as it modifies external services. Shutting down the application abruptly may result in a miss configuration of the DHCP server.

## Stopping `rackup`

In a development environment it is possible to run the application directly through `rackup`. However stopping the application contains some risk if `DHCP` is currently being updated.

The best approach is to send the `rack` process a single `Interrupt`, either using `kill -SIGINT` or `ctrl-c`. If DHCP is being updated, it will attempt to rollback to the last working state.

However there is a race condition where the application has restarted `DHCP` but did not receive the response. This fools the application into thinking its a validation error and does not restart `DHCP` a second time.

Therefore it is always advised to restart the `DHCP` server after stopping the application in this manner.

*WARN*: Only send a single interrupt. Multiple interrupts will cause a hard abort to the process.

## Stopping `unicorn` daemon

When running unicorn in an interactive shell, it is possible to stop it as if it was a `rackup` as described above. However the following should be used to stop the daemon process.

Because `unicorn` runs in a `master`-`worker` architecture it is possible to preform a graceful shut down. This is done by finding the `PID` of the master `unicorn` process and send it the signals below.

### Finding the Master Unicorn `PID`

The master unicorn process can either be found using `ps`:

```
# Look for the first unicorn process
ps -auxffw | grep unicorn
```

Or it can be found in the temporary pid file:

```
cat <configured-temporary-directory>/unicorn/master.pid
```

### Gracefully shut down the Daemon

The master process should first be instructed to kill off its workers. This gives each worker a chance to finish their current request.

To commence the shut down, send the master process the `WINCH` signal:

```
kill -WINCH <PID>
```

Give the master process a moment to shut down its workers and confirm that only the single master process is running:

```
# Should only show the master process and the grep
ps -auxffw | grep unicorn
```

Finally send `QUIT` to the master process:

```
kill -QUIT <PID>
```

Sending `QUIT` whilst their are active workers will still shut down the application. However each worker process will receive the `QUIT` signal. This has a similar effect to sending `INTERRUPT` as described above.

