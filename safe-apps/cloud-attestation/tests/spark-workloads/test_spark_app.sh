export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../../functions
. attest_pod

kmaster="192.168.0.1:6431"

postVMInstance $IAAS $kmaster kube-image vpc-1 10.96.0.1:1-65535 192.168.1.0/24

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
postTrustedEndorser alice bob attester
postAndDLinkTrustedEndorser alice bob trustPolicy endorsements/trustPolicy/configset1
postTrustedEndorser bob bob attester

checkAttester alice $IAAS $kmaster

postSparkPod "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "driver"
checkLaunches alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "GJOIpguw8b1Zhdc7kYBhtbVaU4IRolUfSEbCyKNQXHM"
checkHasConfig alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" containers '[\"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__default__spark-kubernetes-driver\", \"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__init__spark-init\"]'

postSparkPod "2df11174-0b17-4056-a8e7-f248876f7acf" "worker"
postSparkPod "776740af-4895-4eaf-83a3-b7552227b13b" "worker"
postSparkPod "8d827ee8-91a6-4402-9df5-ed2414d6edcd" "worker"
 
 
postPodPolicy bob configset1 safe-spark-job
postImagePolicy bob configset1 '[\"spark:v2.3\",\"spark:v2.3\"]'
postProhibitedPolicy bob configset1 '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY1\"]' 
postProhibitedPolicy bob configset1 '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY2\"]' 
postRequiredPolicy bob configset1 '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\",\"SPARK_DRIVER_ARGS\"]'
postRequiredPolicy bob configset1 '[\"spark:v2.3\",\"KUBERNETES_PORT\"]'
postQualifierPolicy bob configset1 '[\"spark:v2.3\",[\"SPARK_JAVA_OPT_17\",\"-Dspark.jars=http://192.168.0.1:12345/spatial-spark.jar,http://192.168.0.1:12345/spatial-spark.jar\"],[\"arg0\",\"driver\"]]'
postQualifierPolicy bob configset1 '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'

# Among the following queries, only the check on the first pod would pass.
printf "\n\n\nchecking pods against configset1\n\n"
checkPodByPolicy alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" configset1
checkPodByPolicy alice $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" configset1
checkPodByPolicy alice $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" configset1
checkPodByPolicy alice $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" configset1


# This check must pass
debugCheck1 alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" configset1

# This check must fail
checkHasConfig alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__default__spark-kubernetes-driver" '[\"spark:v2.3\",[\"SPARK_DRIVER_CLASS\",\"spatialspark.main.SpatialJoinApp\"],[\"SPARK_JAVA_OPT_0\",\"-Dspark.kubernetes.authenticate.submission.caCertFile=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt\"]]'


# Using alice's own policy
postPodPolicy alice configset2 safe-spark-job
postImagePolicy alice configset2 '[\"spark:v2.3\",image_c2,image_c3]'
postProhibitedPolicy alice configset2 '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY3\"]'
postProhibitedPolicy alice configset2 '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY4\"]' 
postRequiredPolicy alice configset2 '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\",\"SPARK_DRIVER_URL\"]'
postRequiredPolicy alice configset2 '[\"spark:v2.3\",\"KUBERNETES_PORT\"]'
postQualifierPolicy alice configset2 '[\"spark:v2.3\",[\"SPARK_EXECUTOR_ID\",\"3\"],[\"arg0\",\"executor\"]]'
postQualifierPolicy alice configset2 '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'
postEndorsementLink alice trustPolicy/configset2

# All the following checks except for the last one would fail.
printf "\n\n\nchecking pods against configset2\n\n"
checkPodAttestation alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" configset2
checkPodAttestation alice $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" configset2
checkPodAttestation alice $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" configset2
checkPodAttestation alice $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" configset2

# Install policy1 for admission of alice's tag0
postGroupAdmissionPolicy alice alice:tag0 "safe-spark-job" bob
postGroupAdmissionPolicy alice alice:tag0 "safe-spark-job" alice

# Authorizer frank issues the following checks using alice:tag0
# The first and the last can pass this check
printf "\n\n\nchecking access for pods\n\n"
checkPodAccess frank $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" alice:tag0
checkPodAccess frank $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" alice:tag0
checkPodAccess frank $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" alice:tag0
checkPodAccess frank $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" alice:tag0