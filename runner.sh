

# initial AWS infrastructure setups
terraform apply --var 'stage_name=dev' --auto-approve

# Data Pipelines not really supported in Terraform, so we are going with this workaround here:
# http://themrmax.github.io/2015/08/24/A-Python-Script-on-AWS-Data-Pipeline.html
response=`aws datapipeline create-pipeline --name etl_pipeline --unique-id etl_pipeline`
#response is of the form { "pipelineId": "df-05033941C83LSDPT0B42" }
id=${response:21:23}
aws datapipeline put-pipeline-definition --pipeline-id $id --pipeline-definition file://etl_pipeline.cf
aws datapipeline activate-pipeline --pipeline-id $id

# Glue version trigger
aws glue start-trigger --name etl_trigger



# Kubernetes stuff:

# Note that requires the right image to run and I am leaving that as an exercise to the reader
kubectl create -f etl_kube.yaml


