export SAFE_ADDR=http://127.0.0.1:7777
. attest_pod

postSparkPod "026f48d4-3a68-42fd-b8b0-9c94f00b1f1a" "driver"
postSparkPod "2df11174-0b17-4056-a8e7-f248876f7acf" "worker"
postSparkPod "776740af-4895-4eaf-83a3-b7552227b13b" "worker"
postSparkPod "8d827ee8-91a6-4402-9df5-ed2414d6edcd" "worker"


