
variable "bucket_name" {
    type = string
    description = "The bucket name to store data lake files"
    default = "great-expectations-glue-demo"
}

variable "datalake_prefix" {
    type = string
    description = "The prefix to store data lake data"
    default = "datalake"
}


variable "batch_dates" {
    type = list(string)
    description = "The Year-Month to load files from NYC Trip Data into the bucket"
    default = ["2022-01", "2022-02", "2022-03"]
}

variable "database_name" {
    type = string
    description = "The database name to create in Glue Data Catalog"
    default = "db_ge_with_glue_demo"
}

variable "table_name" {
    type = string
    description = "The table name for the NYC Trip Data"
    default = "tb_nyc_trip_data"
}

variable "glue_role_name" {
    type = string
    description = "The glue role name"
    default = "GE-Glue-Demo-Role"
}

variable "tags"{
    type = map(string)
    description = "Tags to be applied in the resources created."
    default = {
        ProjectName = "Great Expectations with Glue Data Catalog Demo"
        CreatedBy = "Terraform"
    }
}