
import numpy as np
import gadgetron
import ismrmrd
import logging
import time
#import matplotlib.pyplot as plt

#BART import
import os
import sys
path = os.environ["TOOLBOX_PATH"] + "/python/"
sys.path.append(path)
from bart import bart

def send_reconstructed_images(connection, data_array,acq_header):
    # the fonction creates an new ImageHeader for each 4D dataset [RO,E1,E2,CHA]
    # copy information from the acquisitonHeader
    # fill additionnal fields
    # and send the reconstructed image and ImageHeader to the next gadget
    # some field are not correctly filled like image_type that floattofix point doesn't recognize , why ?
	
    data_array=np.expand_dims(data_array, tuple(np.arange(data_array.ndim,data_array.ndim + 5 )) )
    dims=data_array.shape   

    base_header=ismrmrd.ImageHeader()
    base_header.version=2
    ndims_image=(dims[0], dims[1], dims[2], dims[3])
    base_header.channels = ndims_image[3]       
    base_header.matrix_size = (data_array.shape[0],data_array.shape[1],data_array.shape[2])    
    base_header.position = acq_header.position
    base_header.read_dir = acq_header.read_dir
    base_header.phase_dir = acq_header.phase_dir
    base_header.slice_dir = acq_header.slice_dir
    base_header.patient_table_position = acq_header.patient_table_position
    base_header.acquisition_time_stamp = acq_header.acquisition_time_stamp
    base_header.image_index = 0 
    base_header.image_series_index = 0
    base_header.data_type = ismrmrd.DATATYPE_CXFLOAT
    base_header.image_type= ismrmrd.IMTYPE_COMPLEX
    base_header.repetition=acq_header.idx.repetition

    I=np.zeros((dims[0], dims[1], dims[2], dims[3]))
    print("dimension of data to be sent: ",dims)
    for slc in range(dims[6]):
        for n in range(dims[5]):
            for s in range(dims[4]):
                I = np.reshape(data_array[:, :, :, :,s,n,slc], ndims_image)
                base_header.slice = slc
                base_header.set=s
                base_header.repetition=n
                base_header.image_type= ismrmrd.IMTYPE_COMPLEX
                image_array = ismrmrd.image.Image.from_array(I, headers=base_header)
                connection.send(image_array)
                print("4D data with (set,rep,slc)= ({},{},{}) Successfully sent!".format(s,n,slc))

def ecalibGadget(connection):
   logging.info("Python reconstruction running - reading readout data")
   h=connection.header
   Bartcmd=(h.userParameters.userParameterString[0].value)
   start = time.time()
   counter = 0
   for acquisition in connection:
       for reconBit in acquisition:
           try:
               print("calling BART : "+ Bartcmd +"\n")
               refdata=np.array(reconBit.data.data)
               im = bart(1, Bartcmd,  refdata)
               reference_header=reconBit.data.headers.flat[34]
               send_reconstructed_images(connection,im,reference_header)
           except Exception as e: 
               print(e) 
               print("issue with BART")
           
       #connection.send(acquisition)

   logging.info( f"Python reconstruction done. Duration: {(time.time() - start):.2f} s")
