export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../../functions
. attest_pod

if [ $# -ne 1 ]; then
  echo "Usage: $0 <data-subdirectory-under-data>"
  exit
fi

datadir="data"
datahome="${datadir}/$1"
file_driver_id="${datahome}/driver_id.txt"
file_exec_ids="${datahome}/exec_ids.txt"

if [ ! -e ${file_driver_id} ]; then
  echo "Make metadata first; use mk_metadata.sh"
  exit
fi

kmaster="192.168.0.1:6431"
driver=`sed -n 1p ${file_driver_id}`
drivergroup="gabbi:${driver}"

postVMInstance $IAAS $kmaster kube-image vpc-1 10.96.0.1:1-65535 192.168.1.0/24

postEndorsementLink bob kube-image
postEndorsement bob kube-image attester 1
postTrustedEndorser gabbi bob attester

checkAttester gabbi $IAAS $kmaster

postSparkPod ${driver} "driver" ${datahome}
# checkLaunches gabbi $kmaster ${driver} "GJOIpguw8b1Zhdc7kYBhtbVaU4IRolUfSEbCyKNQXHM"
# checkHasConfig gabbi $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" containers '[\"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__default__spark-kubernetes-driver\", \"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__init__spark-init\"]'

while IFS= read -r line
do
  echo "Attest for executor pod: ${line}"
  postSparkPod ${line} "worker" ${datahome}
done < ${file_exec_ids}
 

# ConfigSet for worker admission
postPodPolicy gabbi confexec safe-spark-worker
postImagePolicy gabbi confexec '[\"spark:v2.3\",image_c2,image_c3]'
postProhibitedPolicy gabbi confexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY3\"]'
postProhibitedPolicy gabbi confexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY4\"]' 
postRequiredPolicy gabbi confexec '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\",\"SPARK_DRIVER_URL\"]'
postRequiredPolicy gabbi confexec '[\"spark:v2.3\",\"KUBERNETES_PORT\"]'
postQualifierPolicy gabbi confexec '[\"spark:v2.3\",[\"SPARK_EXECUTOR_ID\",\"3\"],[\"arg0\",\"executor\"]]'
postQualifierPolicy gabbi confexec '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'
postEndorsementLink gabbi trustPolicy/confexec

# Among the following queries, only the check on pod 3 would pass.
printf "\n\n\nchecking executor pods against confexec\n\n"
while IFS= read -r exec_id
do
  checkPodAttestation gabbi $kmaster ${exec_id} confexec
done < ${file_exec_ids}


postGroupAdmissionPolicy gabbi ${drivergroup} "safe-spark-worker" gabbi

# Driver authorizes a worker to be part of the job
# Only pod 3 would pass
printf "\n\n\nchecking access for pods\n\n"
while IFS= read -r exec_id
do
  checkPodAccess ${driver} ${kmaster} ${exec_id} ${drivergroup}
done < ${file_exec_ids}


# ConfigSet by another principal                                                                              
postPodPolicy jack jconfexec safe-spark-worker
postImagePolicy jack jconfexec '[image_00,image_01,\"spark:v2.3\"]'
postProhibitedPolicy jack jconfexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY1\"]'
postProhibitedPolicy jack jconfexec '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY2\"]'
postRequiredPolicy jack jconfexec '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\"]'
postRequiredPolicy jack jconfexec '[\"spark:v2.3\",\"KUBERNETES_PORT\",\"SPARK_EXECUTOR_ID\"]'
postQualifierPolicy jack jconfexec '[\"spark:v2.3\",[\"SPARK_DRIVER_URL\",\"spark://CoarseGrainedScheduler@spatial-spark-20d5886815b14d169348a8a830b0171c-driver-svc.latte-gabbi.svc:7078\"],[\"arg0\",\"executor\"]]'
postQualifierPolicy jack jconfexec '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'

postEndorsementLink jack trustPolicy/jconfexec
postAndDLinkTrustedEndorser gabbi jack trustPolicy endorsements/trustPolicy/jconfexec


# All of the following check would pass.                                                   
printf "\n\n\nchecking executor pods against jconfexec\n\n"
while IFS= read -r exec_id
do
  checkPodByPolicy gabbi $kmaster ${exec_id} jconfexec
done < ${file_exec_ids}

postGroupAdmissionPolicy gabbi ${drivergroup} "safe-spark-worker" jack
postGroupAdmissionPolicy gabbi ${drivergroup} "safe-spark-worker" gabbi

# Driver authorizes a worker to be part of the job
# All checks would pass
printf "\n\n\nchecking access for pods\n\n"
while IFS= read -r exec_id
do
  checkWorker ${driver} ${kmaster} ${exec_id} ${drivergroup}
done < ${file_exec_ids}



# ConfigSet to check the driver  
postPodPolicy bob configd safe-spark-job
postImagePolicy bob configd '[image_00, image_01, \"spark:v2.3\",\"spark:v2.3\"]'
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
checkPodByPolicy alice $kmaster ${driver} configd
while IFS= read -r exec_id
do
  checkPodByPolicy alice $kmaster ${exec_id} configd
done < ${file_exec_ids}

# Install configd for admission of alice's tag0                                                        
postGroupAdmissionPolicy alice alice:tag0 "safe-spark-job" bob

# Authorizer frank issues checks on alice:tag0                                                         
# Only the first pod (the driver) can pass the check                                                   
printf "\n\n\nchecking access for pods\n\n"
checkPodAccess frank $kmaster ${driver} alice:tag0
while IFS= read -r exec_id
do
  checkPodAccess frank $kmaster ${exec_id} alice:tag0
done < ${file_exec_ids}


# Check the checker: ConfigSet of Driver ConfigSet                                                     
postPodPolicy tom driveradm safe-drivergroup
postImagePolicy tom driveradm '[\"image_00\", \"image_01\", \"image_02\", \"spark:v2.3\", \"spark:v2.3\"]'

postRequiredPolicy tom driveradm '[[\"spark:v2.3\", prohibited], \"KUBERNETES_PROHIBITED_KEY1\"]'
postProhibitedPolicy tom driveradm '[[\"spark:v2.3\", prohibited], \"KUBERNETES_PROHIBITED_PROHIBITED_KEY1\"]'
postQualifierPolicy tom driveradm '[[\"spark:v2.3\", prohibited]]'

postRequiredPolicy tom driveradm '[[\"spark:v2.3\", prohibited], \"KUBERNETES_PROHIBITED_KEY2\"]'
postProhibitedPolicy tom driveradm '[[\"spark:v2.3\", prohibited], \"KUBERNETES_PROHIBITED_PROHIBITED_KEY2\"]'
postQualifierPolicy tom driveradm '[[\"spark:v2.3\", prohibited]]'

postRequiredPolicy tom driveradm '[[\"spark:v2.3\", required], \"KUBERNETES_SERVICE_PORT\"]'
postProhibitedPolicy tom driveradm '[[\"spark:v2.3\", required], \"KUBERNETES_OPTION_NOT_EXIST_0\"]'
postQualifierPolicy tom driveradm '[[\"spark:v2.3\", required]]'

postRequiredPolicy tom driveradm '[[\"spark:v2.3\", required], \"SPARK_EXECUTOR_ID\"]'
postProhibitedPolicy tom driveradm '[[\"spark:v2.3\", required], \"KUBERNETES_OPTION_NOT_EXIST_1\"]'
postQualifierPolicy tom driveradm '[[\"spark:v2.3\", required]]'

postRequiredPolicy tom driveradm '[[\"spark:v2.3\", qualifier], \"arg0\"]'
postProhibitedPolicy tom driveradm '[[\"spark:v2.3\", qualifier], \"SPARK_OPTION_NOT_EXIST_2\"]'
postQualifierPolicy tom driveradm '[[\"spark:v2.3\", qualifier], [\"SPARK_DRIVER_URL\",\"spark://CoarseGrainedScheduler@spatial-spark-20d5886815b14d169348a8a830b0171c-driver-svc.latte-gabbi.svc:7078\"]]'

postRequiredPolicy tom driveradm '[[\"spark:v2.3\", qualifier], \"arg0\", \"arg1\"]'
postProhibitedPolicy tom driveradm '[[\"spark:v2.3\", qualifier], \"SPARK_OPTION_NOT_EXIST_3\"]'
postQualifierPolicy tom driveradm '[[\"spark:v2.3\", qualifier], [\"arg0\",\"init\"]]'

postEndorsementLink tom trustPolicy/diveradm


printf "\n\nCheck driver group\n\n"

# This driver-group check should pass
checkDriverGroup tom $kmaster ${driver} gabbi driveradm
