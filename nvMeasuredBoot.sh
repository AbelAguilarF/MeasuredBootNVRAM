#!/bin/bash
mbootServiceH=$(sha1sum /etc/systemd/system/fio-daemon.service | awk '{print $1}')
comparatorPCRH=$(sha1sum /usr/local/bin/tpm2_getsession | awk '{print $1}')
snortH=$(sha1sum /usr/local/bin/snort | awk '{ print $1 }')
snortluaH=$(sha1sum /usr/local/etc/snort/snort.lua | awk '{ print $1 }')
splunkH=$(sha1sum /opt/splunkforwarder/bin/splunk | awk '{ print $1 }')

bootcH=$(sha1sum /boot/bootcode.bin | awk '{ print $1 }')
startH=$(sha1sum /boot/start.elf | awk '{ print $1 }')
configH=$(sha1sum /boot/config.txt | awk '{ print $1 }')
kernelH=$(sha1sum /boot/kernel8.img | awk '{ print $1 }')
cmdlineH=$(sha1sum /boot/cmdline.txt | awk '{ print $1 }')

tpm2_pcrextend 16:sha1=$mbootServiceH
tpm2_pcrextend 16:sha1=$comparatorPCRH
tpm2_pcrextend 16:sha1=$snortH
tpm2_pcrextend 16:sha1=$snortluaH
tpm2_pcrextend 16:sha1=$splunkH

tpm2_pcrextend 23:sha1=$bootcH
tpm2_pcrextend 23:sha1=$startH
tpm2_pcrextend 23:sha1=$configH
tpm2_pcrextend 23:sha1=$kernelH
tpm2_pcrextend 23:sha1=$cmdlineH

tpm2_pcrread -o pcrs.bin sha1:16,23


