# Disaster recovery example for Percona XtraDB Cluster

Percona XtraDB Cluster (PXC) is usually able to recover from node failures
automatically. However in some cases manual interaction is required.

This document shows steps that can be taken to help with manual recovery.

**Disclaimer:**
The described steps are merely an example for recovery and not a reference. It
does not cover all scenarios that can occur.
It was only tested in a development environment and not on a production system.
Great care and additional reading or consultation should be taken when
recovering a production system.

## Bring up all nodes in standby mode

In cases of database failures it is likely that the replicas of the database
StatefulSet are not running and are not able to come up anymore.
In order to have manual access to mysql on each node the StatefulSet has to be
altered in the following way.

1. Scale down the StatefulSet

    ```bash
    $ kubectl -n <NAMESPACE> patch sts database -p '{"spec":{"replicas":0}}'
    ```
1. Patch Pod template to come up in standby mode

    ```bash
    $ kubectl -n <NAMESPACE> patch sts database --patch '
    spec:
      template:
        spec:
          containers:
          - name: database
            command: ["sleep", "infinity"]
            readinessProbe:
              initialDelaySeconds: 1
              exec:
                command: ["/bin/true"]
            livenessProbe:
              initialDelaySeconds: 1
              exec:
                command: ["/bin/true"]
          - name: logs
            command: ["sleep", "infinity"]
    '
    ```
1. Scale up the StatefulSet

    **Note**: Replace "3" with the number of replicas you were running before.

    ```bash
    $ kubectl -n <NAMESPACE> patch sts database -p '{"spec":{"replicas":3}}'
    ```


At that point all replicas should come up and have all the data available, but
mysqld will not be started. It is then possible to connect to the nodes using

```bash
$ kubectl -n <NAMESPACE> exec -it database-0 -- env TERM=screen-256color COLUMNS=101 LINES=55 /bin/bash
$ kubectl -n <NAMESPACE> exec -it database-1 -- env TERM=screen-256color COLUMNS=101 LINES=55 /bin/bash
[...]
```

## Example: Recover from ALL-NON-PRIMARY case

When all replicas die at about the same time without a chance of clean shut
down the statefulset will not be able to recover and thus not come up properly.

The replica "0" will refuse to bootstrap as the primary node because it can not
be sure to have been the last to have left the cluster. There might be other
nodes with additional data that would be lost if the "0" node would become the
new primary.

### Find node with highest sequence number

To resolve the situation we need to bring up the nodes as described above.
We can then use the following command to find the sequence number that was
written last for each of the nodes, e.g.

```
$ database-0:/ # mysqld_safe --wsrep-recover
2020-03-06T11:20:22.978115Z mysqld_safe Logging to '/var/log/mysqld.log'.
2020-03-06T11:20:22.985807Z mysqld_safe Logging to '/var/log/mysqld.log'.
2020-03-06T11:20:23.032266Z mysqld_safe Starting mysqld daemon with databases from /var/lib/mysql
2020-03-06T11:20:23.071467Z mysqld_safe WSREP: Running position recovery with --log_error='/var/lib/mysql/wsrep_recovery.W4uSJQ' --pid-file='/var/lib/mysql/-database-0-recover.pid'
2020-03-06T11:20:27.201286Z mysqld_safe WSREP: Recovered position c34bd2f1-5f8f-11ea-8733-aed77685a9db:10166
2020-03-06T11:20:30.239623Z mysqld_safe mysqld from pid file /var/run/mysqld/mysqld.pid ended
```

As we can see from the line containing "Recovered position" the last sequence
number written on `database-0` was 10166.

For `database-1` and `database-2` the number is 10171:

```
database-1:/ # mysqld_safe --wsrep-recover
2020-03-06T11:22:03.418074Z mysqld_safe Logging to '/var/log/mysqld.log'.
2020-03-06T11:22:03.425476Z mysqld_safe Logging to '/var/log/mysqld.log'.
2020-03-06T11:22:03.481908Z mysqld_safe Starting mysqld daemon with databases from /var/lib/mysql
2020-03-06T11:22:03.530278Z mysqld_safe WSREP: Running position recovery with --log_error='/var/lib/mysql/wsrep_recovery.EBhAbX' --pid-file='/var/lib/mysql/-database-1-recover.pid'
2020-03-06T11:22:07.573558Z mysqld_safe WSREP: Recovered position c34bd2f1-5f8f-11ea-8733-aed77685a9db:10171
2020-03-06T11:22:10.625598Z mysqld_safe mysqld from pid file /var/run/mysqld/mysqld.pid ended
```

### Synchronize nodes

We thus select `database-1` as the new primary and let it know that it
can bootstrap by modifying `/var/lib/mysql/grastate.dat` and setting
`safe_to_bootstrap` to `1`. We then start mysql by running

```bash
$ K8S_SERVICE_NAME= bash /startup-scripts/entrypoint.sh &
$ tail -f /var/log/mysqld.log
```

Notice that we need to unset `K8S_SERVICE_NAME` on the new primary.

On the non-primary nodes we also need to run the script to start mysqld and
join the cluster, but without unsetting the `K8S_SERVICE_NAME` environment
variable:

```bash
$ bash /startup-scripts/entrypoint.sh &
$ tail -f /var/log/mysqld.log
```

If you don't see any progress in the primary node's logs it can be nessary
to restart mysqld on the non-primary a few times until it sees and connects
properly:

```bash
$ pkill -9 mysqld
$ bash /startup-scripts/entrypoint.sh &
$ tail -f /var/log/mysqld.log
```

Before proceeding make sure that all nodes joined the cluster successfully by
checking the logs for messages like this:

```
2020-03-06T13:19:46.770075Z 0 [Note] WSREP: Shifting JOINED -> SYNCED (TO: 182)
2020-03-06T13:19:46.787835Z 6 [Note] WSREP: Synchronized with group, ready for connections
```

### Shut down nodes in right succession

After successful synchronisation all nodes need to be shutdown in the right
succession so that the node with the number "0" is the last to shut down.

Run on each node - starting on the node with the highest number - the following
command and wait for it to succeed before continuing with the next node:

```bash
mysqladmin shutdown
```

### Reset StatefulSet to original state

```bash
kubectl -n <NAMESPACE> edit qsts database
```

Set the replicas field to "0" and wait until all database pods have disappeared,

Edit the qsts again and set the replicas number back to what it was before.

Wait until all pods are ready.
