// defcons for publishing endorsements

import("conf.slang").

// K8s attester Set
defcon k8sAttesterSet() :-
  {
    label("endorsements/K8sTest").
    endorse($SparkImage, "attester", true).
    endorse($K8sImage, "attester", true).
  }.

definit k8sAttesterSet().

// Spark attester set
defcon sparkAttesterSet() :-
  {
    label("endorsements/$SparkSource").
    endorse($SparkSource, "attester", true).
  }.

definit sparkAttesterSet().

// Spark app set (endorsements: pageRankSourceSet)
// QC: who does column aggregation?
//     who uses output guard?
defcon consPageRankSourceSet() :-
  {
    label("endorsements/$PageRankJobSource").
    parameterizedEndorse($PageRankJobSource, "inFile", "cmdArg1").
    parameterizedEndorse($PageRankJobSource, "outFile", "cmdArg2").
    parameterizedColumnUsed($PageRankJobSource, "cmdArg1", "url").
    parameterizedColumnUsed($PageRankJobSource, "cmdArg1", "neighbor").
    parameterizedColumnAggregated($PageRankJobSource, "cmdArg1", "url", "count").
    endorse($PageRankJobSource, "stateless", true).
    parameterizedOutputGuard($PageRankJobSource, "cmdArg2", "outputGuard").

    columnUsed(Instance, InFileName, ColName) :-
      parameterizedColumnUsed($PageRankJobSource, InFileArg, ColNameArg),
      runs(Instance, Image),
      buildsFrom(Image, $PageRankJobSource),
      hasConfig(Instance, InFileArg, InFileName),
      hasConfig(Instance, ColNameArg, ColName).

    columnAggregated(Instance, InFileName, ColName, OpText) :-
      parameterizedColumnAggregated($PageRankJobSource, InFileArg, ColNameArg, OpText),
      runs(Instance, Image),
      buildsFrom(Image, $PageRankJobSource),
      hasConfig(Instance, InFileArg, InFileName),
      hasConfig(Instance, ColNameArg, ColName).

    runsOutputGuard(Instance, OutFileName, GuardText) :-
      parameterizedOutputGuard($PageRankJobSource, OutFileArg, GuardConfName),
      runs(Instance, Image),
      buildsFrom(Image, $PageRankJobSource),
      hasConfig(Instance, OutFileArg, OutFileName),
      hasConfig(Instance, GuardConfName, GuardText).
  }.

definit consPageRankSourceSet().

// Endorsing Tapcon
defcon consTapconSet() :-
  {
    label("endorsements/$TapConSource").
    kernelBuildConfig($TapConSource, "namespace", 1).
    kernelBuildConfig($TapConSource, "selinux", true).
    kernelBuildConfig($TapConSource, "seccomp", true).
    kernelBuildConfig($TapConSource, "apparmor", 1).
    kernelBuildConfig($TapConSource, "portext", 1).
    endorse($TapConSource, $PropertyNossh, true).
    endorse($TapConSource, $PropertyDns, "8.8.8.8").
    endorse($TapConSource, $PropertyPackage, "docker").
    endorse($TapConSource, $PropertyPackage, "dhcpcd").
    endorse($TapConSource, $PropertyPackage, "syslog").
    endorse($TapConSource, $PropertyPackage, "libc").
    packageSource($TapConSource, "linux", $TapConLinuxSource).
    packageSource($TapConSource, "docker", $TapConDockerSource).
    packageVersion($TapConSource, "linux", "4.4.39").
    packageVersion($TapConSource, "syslog", "3.9.1").
    packageVersion($TapConSource, "dhcpcd", "7.0.1").
    packageVersion($TapConSource, "libc", "2.6.0").
    parameterizedConnection($TapConSource, "docker", "imageRepo").
    endorse($TapConSource, "attester", true).
  }.

definit consTapconSet().


// Policy rules for verifying container isolation

defcon containerIsolationRuleSet() :-
  {
    label("container-isolation-rules").
    containerSpec("pidns", "default").
    containerSpec("netns", "default").
    containerSpec("mountns", "default").
    containerSpec("utsns", "default").
    containerSpec("ipcns", "default").
    containerSpec("apparmor-profile", "default").
    containerSpec("privileged", "false").

    kernelBuildConfig(Image, ConfKey, ConfValue) :-
      buildsFrom(Image, Source),
      kernelBuildConfig(Source, ConfKey, ConfValue).

    unsatisfiedConfig(Instance, ConfKey, ConfValue) :-
      containerSpec(ConfKey, SpecValue),
      hasConfig(Instance, ConfKey, ConfValue),
      SpecValue \== ConfValue.

    isolatedContainer(Instance) :-
      H: config(Instance, "pidns", "default"),
      H: config(Instance, "netns", "default"),
      H: config(Instance, "mountns", "default"),
      H: config(Instance, "utsns", "default"),
      H: config(Instance, "ipcns", "default"),
      H: config(Instance, "apparmor-profile", "default"),
      H: config(Instance, "privileged", "false"),
      H: config(Instance, "mount", "null"),
      attester(H),
      runs(H, TapconImage),
      kernelBuildConfig(TapconImage, "apparmor", 1),
      kernelBuildConfig(TapconImage, "selinux", true),
      kernelBuildConfig(TapconImage, "seccomp", true),
      kernelBuildConfig(TapconImage, "namespace", 1),
      kernelBuildConfig(TapconImage, "portext", 1).
  }.

definit containerIsolationRuleSet().


// Rulesets of external endorsements: K8sSparkGuardRuleSet

defcon k8sSparkRuleSet() :-
  {
    label("K8sSparkGuardRuleSet").
    fileAcl("point1k.tsv", "kuser1", "46dcbbfdf9c95d5920dca19aa396cecc0a49527e2c61886f75a4d34e617b3375").
    fileAcl("nycb.tsv", "kuser1", "46dcbbfdf9c95d5920dca19aa396cecc0a49527e2c61886f75a4d34e617b3375").
    k8sImg("52af3fd4-8d42-445d-86fa-5953cffedeb5").
    sparkImg("spark").

    k8sVM(Instance) :-
      runs(Instance, Image),
      k8sImg(Image).

    safeSpark(Pod) :-
      hasConfig(Pod, "container0.cmd0", "driver"),
      hasConfig(Pod, "container0.image", Image),
      sparkImg(Image).

    // QC: what master is responsible for the group membership
    safeSpark(Pod) :-
      M: member(Pod, "SafeSparkGroup"),
      safeSpark(M).

    authPodToUser(Pod, User) :-
      hasConfig(Pod, "latte.user", User).

    authPodToUser(Pod, User) :-
      hasConfig(Pod, "latte.creator", Creator),
      authPodToUser(Creator, User).

    authPodToImage(Pod, Image) :-
      Pod: config(Pod, "spark.jar", Image).

    checkK8sPodAccess(Pod, Host, File) :-
      safeSpark(Pod),
      k8sVM(Host),
      authPodToUser(Pod, User),
      authPodToImage(Pod, Image),
      fileAcl(File, User, Image).
  }.

definit k8sSparkRuleSet().


// KeystoneGuardRuleSet

defcon keystoneRuleSet() :-
  {
    label("KeystoneGuardRuleSet").
    approvedSource($KeystoneClientSource).

    checkKeystoneRequesterImage(Instance) :-
      runs(Instance, Image),
      buildsFrom(Image, Source),
      checkKeystoneRequesterSource(Source).

    checkKeystoneRequesterSource(Source) :-
      approvedSource(Source).
  }.

definit keystoneRuleSet().


defcon launchGuardRuleSet() :-
  {
    label("LaunchGuardGuardRuleSet").
    expectedLaunchGuard($LaunchGuardText).

    checkVMClusterLaunchGuard(Instance) :-
      H: config(Instance, "vpcid", ClusterID),
      H: config(ClusterID, "launchGuard", GuardText),
      trustedCloudProvider(H),
      expectedLaunchGuard(GuardText).
  }.

definit launchGuardGuardRuleSet().

defcon membershipRuleSet() :-
  {
    label("MembershipGuardRuleSet").
    trustedMasterSource($MasterSource).
    trustedWorkerSource($WorkerSource).
    trustedOwnerGuard($OwnerGuard).
    trustedJoinerGuard($JoinerGuard).

    trustedCluster(Instance) :-
      runs(Instance, ImageW),
      buildsFrom(ImageW, SourceW),
      trustedWorkerSource(SourceW),
      Instance : join(ClusterID, Master),
      Master : member(ClusterID, Instance),
      masterRunsSource(Master).

    masterRunsSource(Master) :-
      Master : cluster(ClusterID, GuardO, GuardJ),
      trustedOwnerGuard(GuardO),
      trustedJoinerGuard(GuardJ),
      runs(Master, Image),
      buildsFrom(Image, Source),
      trustedMasterSource(Source).
  }.

definit membershipRuleSet().