# Secret Rotation

Note, this document explains the general rotation of secrets.

The instructions to rotate the CCDB keys specifically are in
[a separate document](secret_rotation.md).

The audience of this document are:

  - Developers working on KubeCF.

  - Operators deploying KubeCF.

# Background

One of the features KubeCF (or rather the cf-operator it sits on top
of) provides is the ability to declare secrets (passwords and
certificates) and have the system automatically generate something
suitably random for such on deployment, and distribute the results to
the pods using them.

This removes the burden from human operators to come up with lots of
such just to have all the internal components of KubeCF properly wired
up for secure communication.

However, even with this, operators may wish to change such secrets
from time to time, or on a schedule. In other words, re-randomize the
board, and limit the lifetime of any particular secret.

As a note on terminology, this kind of change is called
__rotating a secret__.

This document describes how this can be done, in the context of KubeCF.

# Finding secrets

Retrieve the list of all secrets maintained by a KubeCF deployment via

    kubectl get quarkssecret --namespace kubecf

To see the information about a specific secret, for example the NATS password, use

    kubectl get quarkssecret --namespace kubecf kubecf.var-nats-password --output yaml

Note that each quarkssecret has a corresponding regulare k8s secret it
controls.

    kubectl get secret --namespace kubecf
    kubectl get secret --namespace kubecf kubecf.var-nats-password --output yaml

# Requesting a rotation for a specific secret

We keep using `kubecf.var-nats-password` as our example secret.

To rotate this secret:

  1. Create a YAML file for a ConfigMap of the form:

         ---				   
         apiVersion: v1			   
         kind: ConfigMap			   
         metadata:			   
           name: rotate-kubecf.var-nats-password
           labels:			   
             quarks.cloudfoundry.org/secret-rotation: "true"
         data:				   
           secrets: '["kubecf.var-nats-password"]'

     Note, while the name of this ConfigMap can be technically
     anything (allowed by k8s syntax) we recommend using a name
     derived from the name of the secret itself, to make the
     connection clear.

     Note further that while this example rotates only a single
     secret, the `data.secrets` key accepts an array of secret names,
     allowing the simultaneous rotation of many secrets together.

  2. Apply this ConfigMap using:

         kubectl apply --namespace kubecf -f /path/to/your/yaml/file

  3. The cf-operator will process this ConfigMap due the label

         quarks.cloudfoundry.org/secret-rotation: "true"

     and knows that it has to invoke a rotation of the referenced
     secrets.

     The actions of the cf-operator can be followed in its log.

   4. After the cf-operator has done the rotation, i.e. has not only
      changed the secrets, but also restarted all affected pods (the
      users of the rotated secrets), delete the trigger config map
      again:
      
         kubectl delete --namespace kubecf -f /path/to/your/yaml/file
