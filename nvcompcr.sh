#!/bin/bash
mbootServiceH=$(sha1sum /etc/systemd/system/nvmboot.service | awk '{print $1}')
comparatorPCRH=$(sha1sum /usr/local/bin/nvcompcr.sh | awk '{print $1}')
shadowH=$(sha1sum /etc/shadow | awk '{ print $1 }')
sudoersH=$(sha1sum /etc/sudoers | awk '{ print $1 }')
fstabH=$(sha1sum /etc/fstab | awk '{ print $1 }')

bootcH=$(sha1sum /boot/bootcode.bin | awk '{ print $1 }')
startH=$(sha1sum /boot/start.elf | awk '{ print $1 }')
configH=$(sha1sum /boot/config.txt | awk '{ print $1 }')
kernelH=$(sha1sum /boot/kernel8.img | awk '{ print $1 }')
cmdlineH=$(sha1sum /boot/cmdline.txt | awk '{ print $1 }')

tpm2_pcrextend 16:sha1=$mbootServiceH
tpm2_pcrextend 16:sha1=$comparatorPCRH
tpm2_pcrextend 16:sha1=$shadowH
tpm2_pcrextend 16:sha1=$sudoersH
tpm2_pcrextend 16:sha1=$fstabH

tpm2_pcrextend 23:sha1=$bootcH
tpm2_pcrextend 23:sha1=$startH
tpm2_pcrextend 23:sha1=$configH
tpm2_pcrextend 23:sha1=$kernelH
tpm2_pcrextend 23:sha1=$cmdlineH

# Registro con el secreto si se cumple la politica
fecha=$(date +"%d-%m-%Y")
mlog="mlog_$fecha"
touch /var/log/mlog/$mlog
tpm2_nvread 0x01800000 -C 0x01800000 -P pcr:sha1:16,23 -s 768 > "/var/log/mlog/$mlog"

tpm2_pcrreset 16 23

#Limpiamos historial para no dejar rastro de los comandos.
history -c
