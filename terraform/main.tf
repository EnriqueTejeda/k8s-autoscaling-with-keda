provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "keda" {
  metadata {
    name = var.keda_namespace
  }
}

resource "helm_release" "keda" {
  name = "keda"

  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  namespace  = var.keda_namespace
  atomic     = true

}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = var.ingress_nginx_namespace
  }
}

resource "helm_release" "ingress-nginx" {
  name = "nginx-ingress"

  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
  namespace  = var.ingress_nginx_namespace
  atomic     = true

  set {
    name  = "controller.watchIngressWithoutClass"
    value = "true"
  }

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.httpPort.nodePort"
    value = "30005"
  }
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = var.prometheus_namespace
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = var.prometheus_namespace
  atomic     = true

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.service.nodePort"
    value = "30010"
  }
}

resource "kubernetes_namespace" "hello-app" {
  metadata {
    name = var.hello_app_namespace
  }
}

resource "helm_release" "hello-app" {
  name = "hello-app"

  chart                 = "../hello-app/chart"
  namespace             = var.hello_app_namespace
  atomic                = true
  cleanup_on_fail       = true
  timeout               = 150
  force_update          = true
  lint                  = true
  render_subchart_notes = true
}
