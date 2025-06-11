#!/bin/bash

# for speed, we wrote this with jq in bash

OUTPUT_FILE="data/telegram_messages_combined.csv"
echo "id,channel_id,date,message" > "$OUTPUT_FILE"
for json_file in decompressed_json/*.json; do
    if [ -f "$json_file" ]; then
        echo "Processing: $json_file"
        # Extract data from each JSON file and append to CSV (without header)
        jq -r '[(.id[0]//""), (.peer_id.channel_id[0]//""), (.date[0]//""), (.message[0]//""|gsub("\n";" ")|gsub("\"";"\"\""))] | @csv' "$json_file" >> "$OUTPUT_FILE"
    fi
done

echo "CSV file created: $OUTPUT_FILE"
