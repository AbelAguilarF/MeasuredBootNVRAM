# Measured Boot NVRAM
This is an example of a simple measured boot using a TPM 2.0 (Infineon slb-9670) with a Raspberry Pi 4B.
El objetivo es usar los hashes de los archivos críticos del sistema 
y comprobar mediante una politica de PCR en el TPM, que siguen siendo los mismos

## Requirements
Have configured the TPM on the raspberry and tested with `eltt2`.

Have `tpm2-tss` `tpm2-tools` `tpm2-abrmd` and `openssl` software installed.

## Building
The first thing we need to do is assign a password to the owner hierarchy, create a primary key and make it persistent.
```
tpm2_changeauth -c owner PASSWORD  
tpm2_createprimary -C o -P PASSWORD -g sha256 -G rsa -c o_primary.ctx
tpm2_evictcontrol -c o_primary.ctx -P tfg
```
The output indicates the index of the object's handler.

Donwload the scripts and move it.
```
git clone 
cd 
sudo cp nvcompcr.sh /usr/local/bin
sudo chmod +x /usr/local/bin/nvcompcr.sh
sudo cp nvmboot.service /etc/systemd/system
sudo mkdir /var/log/mlog
```
We generate the hashes in the resettable PCRs 16 and 23 (they are not always the same) 
using the sha1 bank, 
then we save them in a pcrs.bin file.
To do this we run the bash script nvMeasuredBoot.sh.
```
sudo bash nvMeasuredBoot.sh
```
Now we need to create the pcr policy for read and write in the area, then we
define a NV area (index) and finaly write the secret in the area.
```
tpm2_createpolicy --policy-pcr -l sha1:16,23 -f pcrs.bin -L pcr.policy
tpm2_nvdefine 0x01300000 -C o -P tfg  -L pcr.policy -a "policyread|policywrite"
echo "Successful Boot" > secret
tpm2_nvwrite 0x01300000 -C 0x01300000 -P pcr:sha1:16,23=pcrs.bin -i secret
```
We make sure that the secret has been saved correctly.
```
tpm2_nvread 0x01300000 -C 0x01300000 -P pcr:sha1:16,23 -s 768
```
To remove the area we use `tpm2_nvundefine`.
```
tpm2_nvundefine 0x01300000 -P tfg
```
We leave it ready for the next boot, for that, we reset the PCRs and 
delete the secret and the policy 
(we must do this so as not to leave a trace of what our secret is).
```
tpm2_pcrreset 16 23
rm pcrs.bin
rm pcr.policy
```

Once we have written and prepared the area with the policy.
We are going to proceed to enable the service and start it.
```
sudo systemctl enable nvmboot.service
sudo systemctl start nvmboot.service
```

#Testing
First we reboot the system without changing any critical boot files. 
If we read the log file created, we have to see the secret.
```
sudo cat /var/log/mlog/mlog_%d-%m-%Y
```

Next, we are going to test what would happen if the PCRs 
were not equal to the PCRs of the policy.
We modify the critical /boot/config.txt file either by removing or adding something.
Then we reboot the system and read the log file. 
```
sudo nano /boot/config.txt 
sudo reboot
```
If everything is correct, the log 
file will be empty, that means some critical file has been modified.





