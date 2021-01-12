#! /bin/bash

#Verification si on est root.
#if [ $EUID != 0 ]
#then
#  echo "Ce script doit être executé en tant que ROOT. Try again."
#  exit 1
#fi

#Declaration des variables


os_name=`uname -v | awk {'print$3'} | cut -f2 -d'-'`
upt=`uptime | awk {'print$3'} | cut -f1 -d','`
ip_add=`ip a | grep "inet" | head -3 | tail -1 | awk {'print$2'} | cut -f2 -d:`
num_proc=`ps -ef | wc -l`
root_fs_pc=`df -h /dev/sda1 | tail -1 | awk '{print$5}'`
total_root_size=`df -h /dev/sda1 | tail -1 | awk '{print$2}'`
#load_avg=`uptime | cut -f5 -d':'`
load_avg=`cat /proc/loadavg  | awk {'print$1,$2,$3'}`
ram_usage=`free -m | head -2 | tail -1 | awk {'print$3'}`
ram_total=`free -m | head -2 | tail -1 | awk {'print$2'}`
inode=`df -i / | head -2 | tail -1 | awk {'print$5'}`
os_version=`cat /etc/debian_version`

#Création du répertoire de stockage des rapports.
if [ ! -d ${HOME}/health_reports ]
then
  mkdir ${HOME}/health_reports
fi

#Déclaration du nom du fichier
html="${HOME}/health_reports/Server-Health-Report-`hostname`-`date +%y%m%d`-`date +%H%M`.html"

#Adresse email d'envoi si besoin.
email_add="jpg@popaul77.org"

#Recherche de l'espace occupé dans le dossier utilisateur.
for i in `ls /home`; do du -sh /home/$i/* | sort -nr | grep G; done > /tmp/dir.txt

#Création de la page html
echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">" >> $html
echo "<html>" >> $html
echo "<link rel="stylesheet" href="https://unpkg.com/purecss@0.6.2/build/pure-min.css">" >> $html
echo "<body>" >> $html
echo "<fieldset>" >> $html
echo "<center>" >> $html
echo "<h2>Rapport d'usage" >> $html
echo "<h3><legend>Script de surveillance machine</legend></h3>" >> $html
echo "</center>" >> $html
echo "</fieldset>" >> $html
echo "<br>" >> $html
echo "<center>" >> $html
echo "<h2>Details de l'OS: </h2>" >> $html
echo "<table class="pure-table">" >> $html
echo "<thead>" >> $html
echo "<tr>" >> $html
echo "<th>Distribution</th>" >> $html
echo "<th>Version</th>" >> $html
echo "<th>Addresse IP</th>" >> $html
echo "<th>Uptime</th>" >> $html
echo "</tr>" >> $html
echo "</thead>" >> $html
echo "<tbody>" >> $html
echo "<tr>" >> $html
echo "<td>$os_name</td>" >> $html
echo "<td>$os_version</td>" >> $html
echo "<td>$ip_add</td>" >> $html
echo "<td>$upt</td>" >> $html
echo "</tr>" >> $html
echo "</tbody>" >> $html
echo "</table>" >> $html
echo "<h2>Utilisation des resources: </h2>" >> $html
echo "<br>" >> $html
echo "<table class="pure-table">" >> $html
echo "<thead>" >> $html
echo "<tr>" >> $html
echo "<th>Processus</th>" >> $html
echo "<th>Espace occupé dans la Racine</th>" >> $html
echo "<th>Taille totale de la Racine</th>" >> $html
echo "<th>Charge systeme</th>" >> $html
echo "<th>RAM utilisée.(en MB)</th>" >> $html
echo "<th>RAM Totale.(in MB)</th>" >> $html
echo "<th>État des iNode</th>" >> $html
echo "</tr>" >> $html
echo "</thead>" >> $html
echo "<tbody>" >> $html
echo "<tr>" >> $html
echo "<td><center>$num_proc</center></td>" >> $html
echo "<td><center>$root_fs_pc</center></td>" >> $html
echo "<td><center>$total_root_size</center></td>" >> $html
echo "<td><center>$load_avg</center></td>" >> $html
echo "<td><center>$ram_usage</center></td>" >> $html
echo "<td><center>$ram_total</center></td>" >> $html
echo "<td><center>$inode</center></td>" >> $html
echo "</tr>" >> $html
echo "</tbody>" >> $html
echo "</table>" >> $html
echo "<h2>Espace occupé par les dossiers utilisateur: </h2>" >> $html
echo "<br>" >> $html
echo "<table class="pure-table">" >> $html
echo "<thead>" >> $html
echo "<tr>" >> $html
echo "<th>Taille</th>" >> $html
echo "<th>Chemin</th>" >> $html
echo "</tr>" >> $html
echo "</thead>" >> $html
echo "<tr>" >> $html
while read size name;
do
  echo "<td>$size</td>" >> $html
  echo "<td>$name</td>" >> $html
  echo "</tr>" >> $html
  echo "</tbody>" >> $html
done < /tmp/dir.txt
echo "</table>" >> $html
echo "</body>" >> $html
echo "</html>" >> $html
echo "Rapport a été generé dans ${HOME}/health_reports avec le nom de fichier = $html. Le rapport est aussi envoyé à: $email_add."
#Sending Email to the user
cat $html | mail -s "`hostname` - Rapport systeme journalier" -a "MIME-Version: 1.0" -a "Content-Type: text/html" -a "From: admin-system<jpg@mydell.lan>" $email_add
