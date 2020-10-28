# Frequently Asked Questions (FAQ)

## Kubernetes Monitoring shows `DOWN` state for some control plane components. Are control plane components working correctly?

You have to check control plane components metrics addresses binding as follows:

The metrics bind addresses of `etcd` and `kube-proxy` control plane components are
by default bind to the localhost that prometheus instances **cannot** access.
Also `scheduler` and `controller-manager` control plane components could have the
same metrics addresses binding.
You should expose metrics by changing bind addresses if you want to collect them.

Edit and use `kubeadm_init.yaml` file to configure `kubeadm init` in case of fresh K8s deployment.

```bash
kubeadm init --config=helpers/kubeadm_init.yaml
```

Manual setup in case of already running K8s deployment.

* Setup `etcd` metrics bind address
    ```bash
    # On k8s master node
    cd /etc/kubernetes/manifests/
    sudo vim etcd.yaml
    # Add listen-metrics-urls as etcd command option
    ...
    - --listen-metrics-urls=http://0.0.0.0:2381
    ...
    ```

* Setup `kube-proxy` metrics bind address

    Edit kube-proxy daemon set
    ```bash
    kubectl edit ds kube-proxy -n kube-system
    ...containers:
          - command:
            - /usr/local/bin/kube-proxy
            - --config=/var/lib/kube-proxy/config.conf
            - --hostname-override=$(NODE_NAME)
            - --metrics-bind-address=0.0.0.0  # Add metrics-bind-address line
    ```
    Edit kube-proxy config map
    ```bash
    kubectl -n kube-system edit cm kube-proxy
    ...
        kind: KubeProxyConfiguration
        metricsBindAddress: "0.0.0.0:10249" # Add metrics-bind-address host:port
        mode: ""
    ```
    Delete the kube-proxy pods and reapply the new configuration
    ```bash
    kubectl -n kube-system delete po -l k8s-app=kube-proxy
    ```
