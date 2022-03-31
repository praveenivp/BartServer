# highly Experimental stage(Probably Forever!)

# Descrition
Toy project to send time consuming BART command like `ecalib` to gadgetron Server from MATLAB(Windows).

# Server Side:remote gadgetron Setup
 Experimental Docker container file has to be compiled.

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
```
docker run --rm -ti --net=host --volume /home/meduser/ecalib:/usr/local/share/gadgetron/python a40abc
```

at the moment we need to set `TOOLBOX_PATH` and start gadgetron manually while running the container

```
export TOOLBOX_PATH=/opt/code/bart/
gadgetron -p 9020
```
Ideally this should be done in dockerfile.

# Client Side : windows
now only ecalib is supported now.

See `matalb\demo.m` to get started!.
## what it does?
The calibration data is Encapsulated into a ISMRMRD data file(h5) with BART command ( see `matlab\calib2ismrmrd.m `) and sent to the gadgetron container we built before. You can also execute the system call on a command prompt to continue using MATLAB!
```
gadgetron_ismrmrd_client.exe -f Calibdata.h5 -C ecalib.xml -a 192.168.2.1 -p 9020 -o test1out.h5
```



