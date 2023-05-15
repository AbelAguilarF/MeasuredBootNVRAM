# Measured Boot NVRAM
This is an example of a simple measured boot using a TPM 2.0 (Infineon slb-9670) with a Raspberry Pi 4B.
This measured boot uses the PCRs, the NVRAM area, and the PCR policy to ensure that the integrity of critical boot files has not been compromised. If the secret stored in the non-volatile area is revealed in the log, it means that the boot has been successful, on the other hand, if the secret is not recorded in the log, it means that something bad has happened.


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
git clone https://github.com/AbelAguilarF/MeasuredBootNVRAM.git
cd MeasuredBootNVRAM
sudo cp nvcompcr.sh /usr/local/bin
sudo chmod +x /usr/local/bin/nvcompcr.sh
sudo cp nvmboot.service /etc/systemd/system
sudo mkdir /var/log/mlog
```


To increase security, we are going to obfuscate the script. To do this we could first change the name of the script and the service, making it go unnoticed. Then we could use a tool called `shc` (Shell Script Compiler), this tool does not provide absolute protection or encrypt the code, what it does is make it difficult to read the code casually, turning it into an executable binary.
```
sudo mv /usr/local/bin/nvcompcr.sh /usr/local/bin/tpm2_getsession
sudo mv /etc/systemd/system/nvmboot.service /etc/systemd/system/fio-daemon.service
sudo apt-get install shc
sudo shc -f /usr/local/bin/tpm2_getsession
sudo mv /usr/local/bin/tpm2_getsession.x /usr/local/bin/tpm2_getsession 
sudo rm /usr/local/bin/tpm2_getsession.x.c
```


We generate the hashes in the resettable PCRs 16 and 23 (they are not always the same) using the sha1 bank, then we save them in a pcrs.bin file.
To do this we run the bash script nvMeasuredBoot.sh.
```
sudo bash nvMeasuredBoot.sh
```


Now we need to create the pcr policy for read and write in the area, then we define a NV area (index) and finaly write the secret in the area.
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


We leave it ready for the next boot, for that, we reset the PCRs and delete the secret and the policy (we must do this so as not to leave a trace of what our secret is).
```
tpm2_pcrreset 16 23
rm nvMeasuredBoot.sh
rm pcrs.bin
rm pcr.policy
rm secret
```


Once we have written and prepared the area with the policy.
We are going to proceed to enable the service and start it.
```
sudo systemctl enable fio-daemon.service
sudo systemctl start fio-daemon.service
```


## Testing
First we reboot the system without changing any critical boot files. 
If we read the log file created, we have to see the secret.
```
sudo cat /var/log/mlog/mlog_ACTUALDATE
```

Next, we are going to test what would happen if the PCRs were not equal to the PCRs of the policy.
We modify the critical /boot/config.txt file either by removing or adding something. Then we reboot the system and read the log file. 
```
sudo nano /boot/config.txt 
sudo reboot
```

If everything is correct, the log file will be empty, that means some critical file has been modified.


## Things to keep in mind
- If we prefer, we can use the sha256 bank, which is more secure than sha1, although for a measured boot it does not usually have much importance.

+ The best thing would be to overwrite and even delete the log after reading it so that there is no trace of the secret, and clear command history usging (we use that in the nvcompcr.sh).
``` 
history -c
```

+ After changing any of the two scripts, we must redo everything since the hashes will not be the same.

* This simple measured boot is based on the idea of [Ian Oliver](https://github.com/tpm2dev/tpm.dev.tutorials/tree/master/Boot-with-TPM)  who said: "As long as you write something to the TPM during boot, you'll get a Measured Boot". That's what we've intended with this.

+ You can also build a similar measured boot using the `Quote` function.





