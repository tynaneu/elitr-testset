#!/bin/bash
source common.sh

if [ $# -ne 2 ] ; then
    echo "usage: $0 <path_to_index> <worker_fp>"
    exit
fi

# echo "This script is for en-EU fingerprints, update that manually if you are looking for other languages"

echo "Cleaning the directory and copying new files"
mkdir -p ../../../SLTev/SLTev-cache/OStt-tt-files/
rm -rf ../../../SLTev/SLTev-cache/OStt-tt-files/*

# Copying the files

for line in $(cat $1)
do
	# echo "$line"
	if [[ "$line" == *".link"* ]];
	then
		file=`cat ../../$line`
		if [[ "$file" == *"http"* ]]; then
			wget -O "$(basename $line | rev | cut -d. -f2- | rev)" "$file"
			file="$(basename $line | rev | cut -d. -f2- | rev)"
		fi
	else
		file=`realpath ../../"$line"`
	fi

	cp $file ../../../SLTev/SLTev-cache/OStt-tt-files/
done


# Converting files into 16K format files, TODO:

for i in $(find ../../../SLTev/SLTev-cache/OStt-tt-files/ -type f -name "*.mp3");
do
	temp_name=$(basename $i)
    file_name=$(basename "$temp_name" | rev | cut -d. -f2- | rev)
    dir_name=$(dirname $i)
    op_wav="$dir_name/${file_name}_16K.wav"
	ffmpeg -hide_banner -loglevel panic -y -i $i -acodec pcm_s16le -ar 16000 -ac 1 $op_wav
done

# Processing ASR of files
index_name=$(basename $1)
DATE=$(date '+%Y%m%d')
only_file_name=$(basename "$temp_name" | rev | cut -d. -f4- | rev)

FROMASR=$2

MEDIATOR=mediator.pervoice.com
CLIENT="./ebclient -s $MEDIATOR -p 4448 --timestamps -r"
TEETS="$UNB ./eet-timestamped"
for i in $(find ../../../SLTev/SLTev-cache/OStt-tt-files/ -type f -name "*_16K.wav");
do
	temp_name=$(basename $i)
    file_name=$(basename "$temp_name" | rev | cut -d. -f2- | cut -d_ -f2- | rev)
	LOGSPATH=$(git rev-parse --show-toplevel)/logs
	DIR=${LOGSPATH}/${FROMASR}/${file_name}.pvlogs
	# TRDIR=../../elitr-testset-evaluations/evaluations/${DATE}/${file_name}/${FROMASR}/${file_name}.transcript
	TRDIR=../../elitr-testset-evaluations/evaluations/20201217/${file_name}/${FROMASR}/${file_name}.transcript

	if [ ! -f $DIR/${file_name}.temp.asr ];
	then
	    mkdir -p $DIR
	    mkdir -p $TRDIR
		echo "$UNB $CLIENT -f $FROMASR -i en-EU -t text < $i | $TEETS $DIR/${file_name}.temp.asr" > $DIR/cmd
		bash $DIR/cmd
		cat "$DIR/${file_name}.temp.asr" | cut -d" " -f2- | online-text-flow-events --text | sed -r '/^\s*$/d' > ${TRDIR}/${file_name}.en.asr
	fi
done


# echo "Now, please run score_generation.sh for ASRev score."
