export SAFE_ADDR=http://127.0.0.1:7777
export IAAS=152.3.145.38:444
. ../../functions
. attest_pod

kmaster="192.168.0.1:6431"

postVMInstance $IAAS $kmaster kube-image vpc-1 10.96.0.1:1-65535 192.168.1.0/24

postEndorsementLink bob kube-image
#postEndorsementLink bob trustPolicy/policy1
postEndorsement bob kube-image attester 1
#postEndorsementLink alice image-builder-vm kube-image
postTrustedEndorser alice bob attester
postAndDLinkTrustedEndorser alice bob trustPolicy endorsements/trustPolicy/policy1
#postTrustedEndorser alice bob trustPolicy
#postEndorsementLink alice trustPolicy/policy1
#postTrustedEndorser alice alice trustPolicy
postTrustedEndorser bob bob attester

checkAttester alice $IAAS $kmaster

postSparkPod "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "driver"
checkLaunches alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "GJOIpguw8b1Zhdc7kYBhtbVaU4IRolUfSEbCyKNQXHM"
checkHasConfig alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" containers '[\"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__default__spark-kubernetes-driver\", \"026f48d4-3a68-42fd-b8b0-9c94f00b1f1a__init__spark-init\"]'

postSparkPod "2df11174-0b17-4056-a8e7-f248876f7acf" "worker"
postSparkPod "776740af-4895-4eaf-83a3-b7552227b13b" "worker"
postSparkPod "8d827ee8-91a6-4402-9df5-ed2414d6edcd" "worker"
 
 
postPodPolicy bob policy1 leak-free
postImagePolicy bob policy1 '[\"spark:v2.3\",\"spark:v2.3\"]'
postProhibitedPolicy bob policy1 '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY1\"]' 
postProhibitedPolicy bob policy1 '[\"spark:v2.3\", \"KUBERNETES_PROHIBITED_KEY2\"]' 
postRequiredPolicy bob policy1 '[\"spark:v2.3\",\"KUBERNETES_SERVICE_PORT\",\"SPARK_DRIVER_ARGS\"]'
postRequiredPolicy bob policy1 '[\"spark:v2.3\",\"KUBERNETES_PORT\"]'
postQualifierPolicy bob policy1 '[\"spark:v2.3\",[\"arg0\",\"driver\"]]'
postQualifierPolicy bob policy1 '[\"spark:v2.3\",[\"arg0\",\"init\"],[\"arg1\",\"/etc/spark-init/spark-init.properties\"]]'

# Among the queries, only the check on the first pod would pass.
printf "\n\n\nchecking pods\n\n"
checkPodByPolicy alice $kmaster "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" policy1
checkPodByPolicy alice $kmaster "2df11174-0b17-4056-a8e7-f248876f7acf" policy1
checkPodByPolicy alice $kmaster "776740af-4895-4eaf-83a3-b7552227b13b" policy1
checkPodByPolicy alice $kmaster "8d827ee8-91a6-4402-9df5-ed2414d6edcd" policy1