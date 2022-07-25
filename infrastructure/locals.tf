locals {
  ingester_out_dir                              = "${path.root}/../out/ingester"
  ingester_zip_out_dir                          = "${path.root}/../out/zip/ingester"
  ingester_influxdb_apitoken_ssm_parameter_name = "/homesensors/ingester/influxdb-apitoken"
  influxdb_url                                  = "https://influxdb.samuelbagattin.com"
}