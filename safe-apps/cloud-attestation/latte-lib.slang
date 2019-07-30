// Latte library
import("conf.slang").

defcon consTrustWallet() :-
  ?Auxlabel0 := label("endorsements/K8sTest"),
  ?Auxlabel1 := label("endorsements/$PageRankJobSource"),
  ?Auxlabel2 := label("endorsements/$SparkSource"),
  ?Auxlabel3 := label("endorsements/$TapConSource"),
  {
    label("trustWallet").
    trustedCloudProvider($IaaS).
    trustedCloudProvider($IaaSGid).
    tapconImageSource($TapConSource).
    tapconDaemonSource($TapConDockerSource).
    tapconKernelSource($TapConLinuxSource).
    approvedDns($OpenDns).
    builderImage($BuilderImage).
    builderSource($TapConSource).
    buildsFrom($BuilderImage, $TapConSource).
    link($Auxlabel0).
    link($Auxlabel1).
    link($Auxlabel2).
    link($Auxlabel3).
  }.

definit consTrustWallet().


// Latte rulesets

defcon lattePolicyRules() :-
  {
    label("latte-library-rules").

    hasConfig(Instance, ConfKey, ConfValue) :-
      H: config(Instance, ConfKey, ConfValue),
      attester(H).

    runs(Instance, Image) :-
      H: runs(Instance, Image),
      attester(H).

    attester(Instance) :-
      hasProperty(Instance, $PropertyAttester, true).

    attester(Instance) :-
      trustedCloudProvider(Instance).

    hasProperty(Instance, Property, Value) :-
      runs(Instance, Image),
      hasProperty(Image, Property, Value).

    hasProperty(Image, Property, Value) :-
      E: endorse(Image, Property, Value),
      endorser(E).

    hasProperty(Image, Property, Value) :-
      buildsFrom(Image, Source),
      E: endorse(Source, Property, Value),
      endorser(E).

    hasProperty(Instance, Property, Value) :-
      runs(Instance, Image),
      hasConfig(Instance, ConfKey, Value),
      E: parameterizedEndorse(Image, Property, ConfKey),
      endorser(E).

    hasProperty(Instance, Property, Value) :-
      runs(Instance, Image),
      buildsFrom(Image, Source),
      E: parameterizedEndorse(Source, Property, ConfKey),
      endorser(E),
      hasConfig(Instance, ConfKey, Value).

    hasProperty(Instance, Property, Value) :-
      runs(Instance, Image),
      E: endorseIfEqual(Image, ConfKey, SpecValue, Property, Value),
      endorser(E),
      hasConfig(Instance, ConfKey, ConfValue),
      ConfValue = SpecValue.

    hasProperty(Instance, Property, Value) :-
      runs(Instance, Image),
      buildsFrom(Image, Source),
      endorseIfEqual(Source, ConfKey, SpecValue, Property, Value),
      hasConfig(Instance, ConfKey, ConfValue),
      ConfValue = SpecValue.

// Not sure how this is used
//
//    sourceCheck(Instance, Package, Source) :-
//      runs(Instance, Image),
//      packageBuildsFrom(Image, Package, Source).
//
//    sourceCheck(Instance, Package, Source) :-
//      runs(Instance, Image),
//      buildsFrom(Image, ISource),
//      packageBuildsFrom(ISource, Package, Source).
//
//    versionCheck(Instance, Package, Version) :-
//      runs(Instance, Image),
//      packageVersion(Image, Package, Source).
//
//    versionCheck(Instance, Package, Version) :-
//      runs(Instance, Image),
//      buildsFrom(Image, ISource),
//      packageVersion(ISource, Package, Source).
//
//    packageBuildsFrom(Image, Package, Source) :-
//      packageSource(Image, Package, Source).
//
//    packageBuildsFrom(Image, Package, Source) :-
//      buildsFrom(Image, ISource),
//      packageSource(ISource, Package, Source).

    member(Instance, Cluster, Master) :-
      Master: member(Cluster, Instance),
      Instance: join(Cluster, Master).

    member(Instance, Cluster, Master) :-
      Master: member(Cluster, Instance),
      trustedCloudProvider(Master).

// Not sure the assumed scenarios here
    connection(Instance, Package, Ep) :-
      runs(Instance, Image),
      parameterizedConnection(Image, Package, ConfKey),
      hasConfig(Instance, ConfKey, Ep).

    connection(Instance, Package, Ep) :-
      runs(Instance, Image),
      buildsFrom(Image, Source),
      parameterizedConnection(Source, Package, ConfKey),
      hasConfig(Instance, ConfKey, Ep).
  }.
