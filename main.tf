terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.17.0"
    }
  }

  cloud {
        organization = "VascoORG"
        workspaces {
          name = "ntt"
        }
  }
}


provider "google" {
  project = "olas-485615"
  #credentials = "key.json"
}


data "google_compute_network" "my-network" {
  name = "vpc-network"
}

#resource "google_compute_global_address" "private_ip_address" {
 # name          = "private-ip-address"
  #purpose       = "VPC_PEERING"
  #address_type  = "INTERNAL"
  #prefix_length = 16
  #network       = data.google_compute_network.my-network.id

#}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.my-network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "instance" {
  name             = "database-instance"
  region           = "europe-west12"
  database_version = "POSTGRES_15"
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.my-network.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "database" {
 name     = "my-database"
 instance = google_sql_database_instance.instance.name
 depends_on = [google_sql_database_instance.instance]
}