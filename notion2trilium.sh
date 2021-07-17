#!/bin/bash

rename() {
	local name="$1"
	for k in "$name"/*; do
	FILETYPE=$(file -b "$k" | awk '{print $1}')

	if [[ $FILETYPE == "directory" ]];
		then
		HASHVAL=$(echo $k | awk '{ print $NF }' | sed 's/\.md//g')
		echo "$HASHVAL" >> ./hash_db.txt

		NEWNAME=$(echo $k | sed "s/ $HASHVAL//g")
		echo "Moving '$k' to '$NEWNAME'"
		mv "$k" "$NEWNAME"
		rename "$NEWNAME"

	elif [[ $FILETYPE != "CSV" && $FILETYPE != "PNG" && $FILETYPE != "JPEG" && $FILETYPE != "directory" ]];
		then
		HASHVAL=$(echo $k | awk '{ print $NF }' | sed 's/\.md//g')
		echo "$HASHVAL" >> ./hash_db.txt

		NEWNAME=$(echo $k | sed "s/ $HASHVAL//g")
		echo "Moving '$k' to '$NEWNAME'"
		mv "$k" "$NEWNAME"
	fi
	done
}

fixInternalLink() {
	local dirName="$1"
	for k in "$dirName"/*; do
	FILETYPE=$(file -b "$k" | awk '{print $1}')

	if [[ $FILETYPE == "directory" ]];
		then
		fixInternalLink "$k"

	elif [[ $FILETYPE != "CSV" && $FILETYPE != "PNG" && $FILETYPE != "JPEG" && $FILETYPE != "directory" ]];
		then
		# For every entry in hash_db.txt sed out $hashy
		echo "Fixing Internal Links in '$k'"
		while read hashy; do
			sed -e s/%20$hashy//g -i "$k"
		done < ./hash_db.txt
	fi
	done
}

######################
## MAIN Starts here ##
######################
if [[ -f ./hash_db.txt ]]; then
	rm ./hash_db.txt
fi

# Remove hashes from filenames
for f in ./Notion-Export/*; do
	if [[ -d "$f" ]];
	then
		rename "$f"
	fi

	FILETYPE=$(file -b "$f" | awk '{print $1}')
	if [[ $FILETYPE != "CSV" && $FILETYPE != "PNG" && $FILETYPE != "JPEG" ]];
		then
  		HASHVAL=$(echo $f | awk '{ print $NF }' | sed 's/\.md//g')
		echo "$HASHVAL" >> ./hash_db.txt

  		NEWNAME=$(echo $f | sed "s/ $HASHVAL//g")
		echo "Moving '$f' to '$NEWNAME'"
  		mv "$f" "$NEWNAME"		

	fi
done


# Fix internal links to notes and images
# Recursively sed out hashes from every file
# Remove lines shorter than 32 chars _and_ lines longer than 32
sed -r '/^.{,31}$/d' -i ./hash_db.txt
sed '/^.\{32\}./d' -i ./hash_db.txt
filtered_hash_list=$(sort ./hash_db.txt | uniq)
echo "$filtered_hash_list" > ./hash_db.txt

for f in ./Notion-Export/*; do
	if [[ -d "$f" ]];
	then
		fixInternalLink "$f"
	fi

	FILETYPE=$(file -b "$f" | awk '{print $1}')
	if [[ $FILETYPE != "CSV" && $FILETYPE != "PNG" && $FILETYPE != "JPEG" && $FILETYPE != "directory" ]];
		then
		echo "Fixing Internal Links in '$f'"
		while read hashy; do 
			sed -e s/%20$hashy//g -i "$f"
		done < ./hash_db.txt
		
	fi

done