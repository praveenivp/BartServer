## building containers

```
apptainer build gadgetron.sif gadgetron_ubunutu22.recipe
#test for python support and proper PATHS
apptainer exec --nv gadgetron.sif gadgetron --info
apptainer exec --nv gadgetron.sif gadgetron -p 9056
appatiner exec --nv gadgetron.sif bart bench
```

## Cluster 

```
salloc
ssh -Y -L 9002:localhost:9002 <user>@<node>
```

#### starting gadgetron
`GADGETRON_HOME` is wrong in the container :/
```
#!/bin/bash
apptainer exec \
-B /ptmp/pvalsala/test/ecalib_test/gadgetron-gadgets/config:/usr/local/share/gadgetron/config \
-B /ptmp/pvalsala/test/ecalib_test/gadgetron-gadgets/python:/usr/local/share/gadgetron/python \
/ptmp/pvalsala/MyContainers/gadgetron.sif bash -c \
" export GADGETRON_HOME=/usr/local && gadgetron"
```
#### client
```
#!/bin/bash
apptainer exec gadgetron.sif gadgetron_ismrmrd_client "$@"
```
