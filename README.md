# Distributed JPetStore Experiment

## Importing the PCM Model Project in Eclipse

- To be able to edit the model you should switch to the Modeling Perspective.

## Experiment setup

To be able to run this experiment, you need at least
- A present version of our jpetstore-6
- In case you want to use specific iObserve features, payload and/or privacy monitoring
  - A set of the iObserve tools from iobserve-analysis
- In case only trace monitoring is required, you will use the distributed version
  of the jpetstore with Kieker instrumentation
  - The Kieker collector form the Kieker binary distribution
- Our selenium based workload runner (optional)

## Scripts

Note: The correct set of tools depends and the specific version of the jpetstore depend on
the experiment script.

### Common configuration

Depending on the tool and setup you have, you need to configure the experiment.
- Copy the `config.template` to `config`.
- Open `config` in an editor.
- Adapt the configuration variables (you may not need to adapt everything depending on
  the experiment you are running.
- Note: `$BASE_DIR` is set by the scripts and is the location where the scripts are located.
- `TOOLS_DIR` the directory where your tools are located
- `DATA_DIR` the directory where monitoring data will be logged to (or in a directory inside).
- `RESULT_DIR` in case an analysis is used, the results go there
- `DOCKER_REPO` location of an external docker repository (optional, depending on setup)
- `LOGGER` IP address of the host where the monitoring data should be send to. When using the
  collector, this is the IP address of your local machine, but not localhost.
- `JPETSTORE` the script used to run the JPetStore this is usually
  `"$BASE_DIR/execute-jpetstore-with-workload.sh"`
- `WORKLOAD_RUNNER` complete path to the workload runner (optional depending on setup)
- `WEB_DRIVER` in case you are using the built-in HtmlUnit driver of Selenium, this variable
  must be empty. Otherwise you can use the Chrome or GeckoDriver (see Selenium documentation
  for details).
- `COLLECTOR` full path to the collector (optional, used by `execute-observation.sh`)


### execute-jpetstore-with-workload.sh

**Usage:** execute-jpetstore-with-workload.sh [workload-file.yaml]

This script supports running the JPetStore with an optional workload. Is the workload omitted
it will run without it and allow the user to use the JPetStore interactively. This script
uses Docker and not Docker Compose.

Note: The script will report on missing parts when executed, but will not check on the
correct verion of the tools.

When started, the script tries to stop and remove any docker container which might be
remaining from the previous run, in case the script has failed. It also tries to stop rogue
collector services. This means you cannot run this experiment simultaneously with itself
or other experiments which rely on the JPetStore or a collector service.

In case no JPetStore was running it will report "errors" from the docker calls.

The script will then start all four docker container and setup a bridged network for these
containers.

This might look similar to:
```
ef1559eae9b556a408df8f9bc0817d53e048fe290547a3542cc1c7806380b57a
3c904e128253540583007577ac50d66e8c6d7988f1185d80c588a7661c69e6ae
0c70b374d3f8fa0a413bfc1edf14b5ff7b8db6e65aea295b49f51ca67af12c20
f27ae67dbeaa6e88f692c8d102c229f5fcb42bc76ab81dd93922e3cfa17ff0be
50f5992d7555ec5e12128629af8a8658b3b2a363ed90d3c3b6262aa83da80907
[info] Service URL http://172.20.0.5:8080/jpetstore-frontend
waiting for service coming up...
```

The last line can be repeated several times. The script tries to connect to the frontend and
will repeat this until success.

**Interactive mode**

In interactive mode, the script signals success with the following tow lines

```
[info] You may now use JPetStore
[info] Press Enter to stop the service
```

To stop the JPetStore, press Enter. The script will then stop and remove all containers

**Workload mode**

In workload mode, the script will immediatly start the workload runner, which looks like this:
```
[info] Running workload driver
2020-02-18 17:34:46 INFO  WorkloadGenerationMain - Executing workloads: CatToCartBehavior
2020-02-18 17:34:46 INFO  BehaviorModelRunnable - Running behavior CatToCartBehavior
2020-02-18 17:34:46 INFO  BehaviorModelRunnable - Running behavior CatToCartBehavior
```

The script automatically terminates after executing the workload and waiting for the JPetStore
to finish its tasks.

### execute-observation.sh

**Usage:** execute-observation.sh [workload-file.yaml]

The `execute-observation.sh` script allows to run the JPetStore and collect monitoring data
in a file. This is helpful for debugging your setup and collecting monitoring data to be 
analyzed later by other tools when a direct link is not necessary or not useful.

The script can use the iObserve or the Kieker collector. The difference is mainly in the
number of records supported. The iObserve variant supports additional iObserve records.
In case you are using specific iObserve records or events, please use the iObserve collector
in all other cases use the Kieker version, which can be obtained from Kieker prebuild.

### execute-integrated-experiment.sh

Runs the complete setup on your local docker setup and collects the data in a Kieker log.

### execute-integrated-kube-experiment.sh

Runs the complete setup on your a Kubernetes setup and collects the data in a Kieker log.
To be able to use it, you need to deploy your Docker images on an docker repository
accessible to your Kubernetes service. 

### Compile your setup

This is somewhat outdated. It is left here for now, but you might be better of with
the specific build instructions of the respective projects.

- Workload runner https://github.com/research-iobserve/selenium-workloads 
  use the jss-paper branch
- iObserve analysis https://github.com/research-iobserve/iobserve-analysis/tree/jss-paper
  use the jss-paper branch
- JPetStore form https://github.com/research-iobserve/jpetstore-6/tree/iobserve-monitoring
  use the iobserve-monitoring branch
- PhantomJS version 2.1.1 (later version might work as well)

Note: The `#` in the following lines indicate a command line operation. Please enter the
complete command following the `# ` into a terminal.

Compile first the workload runner:

`# git clone https://github.com/research-iobserve/selenium-workloads.git`

`# cd selenium-workloads`

`# git checkout master`

`# ./gradlew build`

`# cd ..`

Compile and install iObserve:

Note: Only need when specific iObserve records are used.

`# git clone https://github.com/research-iobserve/iobserve-analysis.git`

`# cd iobserve-analysis`

`# git checkout YOUR-BRANCH`

`# ./gradlew build install`

`# cd ..`

Compile and build docker images:

`# git clone https://github.com/research-iobserve/jpetstore-6.git`

`# cd jpetstore-6`

`# mvn compile package`

`# ./make-docker-images.sh`

`# cd ..`

Install iObserve tools and workloads:
Choose a location where you want to place all tools. In the following we call that folder $TOOLS
and the folder $BASE is the folder where all your checkouts reside.

`# mkdir -p $TOOLS`

`# cd $TOOLS`

this is how to get the iObserve collector (please check for the correct version).
`# tar -xvpf $BASE/iobserve-analysis/collector/build/distributions/collector-0.0.3-SNAPSHOT.tar`

`# tar -xvpf $BASE/selenium-workloads/build/distributions/selenium-experiment-workloads-1.0.tar`

Configure experiment:

`# cd $BASE/distributed-jpetstore-experiment`

`# cp config.template config`

Now open `config` in an editor and adjust the directories.

Execute the desired experiment setup.


