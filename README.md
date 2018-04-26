# Distributed JPetStore Experiment

## Importing the PCM Model Project in Eclipse

- To be able to edit the model you should switch to the Modeling Perspective.

## Experiment setup

To be able to run this experiment, you need at least
- A present version of our jpetstore-6
- A set of the iobserve tools from iobserve-analysis
- Our selenium based workload runner
The correct set of tools depends and the corret version of the jpetstore depend on
the experiment script.

### execute-integrated-experiment.sh

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
`# git clone https://github.com/research-iobserve/selenium-workloads.git
`# cd selenium-workloads`
`# git checkout jss-paper`
`# ./gradlew build`
`# cd ..`

Compile and install iObserve:
`# git clone https://github.com/research-iobserve/iobserve-analysis.git`
`# cd iobserve-analysis`
`# git checkout jss-paper`
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
`# tar -xvpf $BASE/iobserve-analysis/collector/build/distributions/collector-0.0.3-SNAPSHOT.tar`
`# tar -xvpf $BASE/selenium-workloads/build/distributions/selenium-experiment-workloads-1.0.tar`

Configure experiment:
`# cd $BASE/distributed-jpetstore-experiment`
`# cp config.template config`
Now open `config` in an editor and adjust the directories.

Running the experiment:
`# ./execute-integrated-experiment.sh jpetstore-configuration.yaml`

This executes the experiment using the `jpetstore-configuration.yaml` workload model.


