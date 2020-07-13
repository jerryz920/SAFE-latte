export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../../functions
. attest_pod

kmaster="192.168.0.1:6431"
driver="026f48d4-3a68-42fd-b8b0-9c94f00b1f1a"
drivergroup="gabbi:${driver}"

postVMInstance $IAAS $kmaster kube-image vpc-1 10.96.0.1:1-65535 192.168.1.0/24

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
postTrustedEndorser gabbi bob attester


checkAttester gabbi $IAAS $kmaster

postSparkPod "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "driver"
checkLaunches gabbi $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "GJOIpguw8b1Zhdc7kYBhtbVaU4IRolUfSEbCyKNQXHM"
checkHasConfig gabbi $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" containers '[\"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__default__spark-kubernetes-driver\", \"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__init__spark-init\"]'

postSparkPod "2df11174-0b17-4056-a8e7-f248876f7acf" "worker"
postSparkPod "776740af-4895-4eaf-83a3-b7552227b13b" "worker"
postSparkPod "8d827ee8-91a6-4402-9df5-ed2414d6edcd" "worker"
 
# Spark-worker admission policy
postPodPolicy gabbi confexec safe-spark-worker
postImagePolicy gabbi confexec '[\"spark:v2.3\",image_c2,image_c3]'
postProhibitedPolicy gabbi confexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY3\"]'
postProhibitedPolicy gabbi confexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY4\"]' 
postRequiredPolicy gabbi confexec '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\",\"SPARK_DRIVER_URL\"]'
postRequiredPolicy gabbi confexec '[\"spark:v2.3\",\"KUBERNETES_PORT\"]'
postQualifierPolicy gabbi confexec '[\"spark:v2.3\",[\"SPARK_EXECUTOR_ID\",\"3\"],[\"arg0\",\"executor\"]]'
postQualifierPolicy gabbi confexec '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'
postEndorsementLink gabbi trustPolicy/confexec


# Among the following queries, only the check on the last pod would pass.
printf "\n\n\nchecking pods against confexec\n\n"
checkPodAttestation gabbi $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" confexec
checkPodAttestation gabbi $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" confexec
checkPodAttestation gabbi $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" confexec

# postGroupAdmissionPolicy gabbi ${drivergroup} "safe-spark-worker" gabbi
# 
# # Driver authorizes a worker to be part of the job
# # Only the last check would pass
# printf "\n\n\nchecking access for pods\n\n"
# checkPodAccess ${driver} $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" ${drivergroup}
# checkPodAccess ${driver} $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" ${drivergroup}
# checkPodAccess ${driver} $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" ${drivergroup}


# ConfigSet by another principal                                                                              
postPodPolicy jack jconfexec safe-spark-worker
postImagePolicy jack jconfexec '[\"spark:v2.3\",image_00,image_01]'
postProhibitedPolicy jack jconfexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY1\"]'
postProhibitedPolicy jack jconfexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY2\"]'
postRequiredPolicy jack jconfexec '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\"]'
postRequiredPolicy jack jconfexec '[\"spark:v2.3\",\"KUBERNETES_PORT\",\"SPARK_EXECUTOR_ID\"]'
postQualifierPolicy jack jconfexec '[\"spark:v2.3\",[\"SPARK_DRIVER_URL\",\"spark://CoarseGrainedScheduler@spatial-spark-26cc9625ccb0362f834ba50405af6879-driver-svc.latte-gabbi.svc:7078\"],[\"arg0\",\"executor\"]]'
postQualifierPolicy jack jconfexec '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'

postEndorsementLink jack trustPolicy/jconfexec
postAndDLinkTrustedEndorser gabbi jack trustPolicy endorsements/trustPolicy/jconfexec


# All of the following check would pass.                                                   
printf "\n\n\nchecking pods against jconfexec\n\n"
checkPodByPolicy gabbi $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" jconfexec
checkPodByPolicy gabbi $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" jconfexec
checkPodByPolicy gabbi $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" jconfexec

postGroupAdmissionPolicy gabbi ${drivergroup} "safe-spark-worker" jack
postGroupAdmissionPolicy gabbi ${drivergroup} "safe-spark-worker" gabbi

# Driver authorizes a worker to be part of the job
# All checks would pass
printf "\n\n\nchecking access for pods\n\n"
checkWorker ${driver} $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" ${drivergroup}
checkWorker ${driver} $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" ${drivergroup}
checkWorker ${driver} $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" ${drivergroup}


# Driver policy  
postPodPolicy bob configd safe-spark-job
postImagePolicy bob configd '[\"spark:v2.3\",\"spark:v2.3\"]'
postProhibitedPolicy bob configd '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY1\"]' 
postProhibitedPolicy bob configd '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY2\"]' 
postRequiredPolicy bob configd '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\",\"SPARK_DRIVER_ARGS\"]'
postRequiredPolicy bob configd '[\"spark:v2.3\",\"KUBERNETES_PORT\"]'
postQualifierPolicy bob configd '[\"spark:v2.3\",[\"SPARK_JAVA_OPT_17\",\"-Dspark.jars=http://192.168.0.1:12345/spatial-spark.jar,http://192.168.0.1:12345/spatial-spark.jar\"],[\"arg0\",\"driver\"]]'
postQualifierPolicy bob configd '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'
postEndorsementLink bob trustPolicy/configd

postAndDLinkTrustedEndorser alice bob trustPolicy endorsements/trustPolicy/configd
postTrustedEndorser alice bob attester


# Exercise configd: only the check on the first pod would pass.
printf "\n\n\nchecking pods against configd\n\n"
checkPodByPolicy alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" configd
checkPodByPolicy alice $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" configd
checkPodByPolicy alice $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" configd
checkPodByPolicy alice $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" configd

# Install configd for admission of alice's tag0
postGroupAdmissionPolicy alice alice:tag0 "safe-spark-job" bob

# Authorizer frank issues checks on alice:tag0
# Only the first pod (the driver) can pass the check
printf "\n\n\nchecking access for pods\n\n"
checkPodAccess frank $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" alice:tag0
checkPodAccess frank $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" alice:tag0
checkPodAccess frank $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" alice:tag0
checkPodAccess frank $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" alice:tag0