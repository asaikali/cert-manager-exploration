# cert-manager basics

In this exploration we have a default instllation of cert-manager that 
we will use to explore key aspects of how cert-manager works.

Check version of installed helm manager 
```shell
helm list --all-namespaces
```

## bootstrap a PKI 

### create a self signing issuer 

