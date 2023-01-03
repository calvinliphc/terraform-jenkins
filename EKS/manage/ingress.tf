resource "kubernetes_ingress_v1" "jenkins_ingress" {
  metadata {
    name = "jenkins-ingress"
  }

  spec {
    default_backend {
      service {
        name = "jenkins"
        port {
          number = 8080
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
              name = "jenkins"
              port {
                number = 8080
              }
            }
          }

          path = "/jenkins/*"
        }
      }
    }
  }
}

resource "kubernetes_ingress_class" "example" {
  metadata {
    name = "jenkins"
  }

  spec {
    controller = "example.com/ingress-controller"
    parameters {
      api_group = "k8s.example.com"
      kind      = "IngressParameters"
      name      = "jenkins-ingress"
    }
  }
}