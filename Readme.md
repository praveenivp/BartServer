# highly Experimental stage

# Descrition
These scripts can send time consuming bart command like `ecalib` to gadgetron Server from MATLAB.

# Server Side:remote gadgetron Setup
 Experimental Docker container file has to be compiled

 ```
 cd docker
 Docker build -t gadgetron_bart:devel .
 ```
docker  save and load image
```
docker save mynewimage > gadgetron_bart.tar 
scp gadgetron_bart user@192.168.2.1:/home/user
docker load < gadgetron_bart.tar
```


start the container: 
with ecalib.py on the gadgetron python path
`docker run --rm -ti --net=host --volume /home/meduser/ecalib:/usr/local/share/gadgetron/python a40abc`

at the moment we need to set `TOOLBOX_PATH`
`export TOOLBOX_PATH=/opt/code/bart/`

start gadgetron
`gadgetron -p 9020`

# Client Side : windows
now only ecalib is supported
## Encapsulate matrix into a ismrmrdfile 
use `matlab\calib2ismrmrd.m `for conversion

and send it to gadgetron
`gadgetron_ismrmrd_client.exe -f Calibdata.h5 -C ecalib.xml -a 192.168.2.1 -p 9020 -o test1out.h5`



