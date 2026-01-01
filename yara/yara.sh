#!/bin/bash
# Wazuh YARA Active Response Script
# Reads INPUT_JSON from Wazuh syscheck alerts, scans the file with YARA, and logs the result.

# Read INPUT_JSON from stdin
read INPUT_JSON

# Debug: log the raw JSON
echo "wazuh-yara: DEBUG - INPUT_JSON=$INPUT_JSON" | sudo tee -a /var/ossec/logs/active-responses.log

# Extract the file path to scan
FILENAME=$(echo "$INPUT_JSON" | jq -r .syscheck.path)
echo "wazuh-yara: DEBUG - FILENAME=$FILENAME" | sudo tee -a /var/ossec/logs/active-responses.log

# Extract YARA executable path and rules path from extra_args
YARA_PATH=$(echo "$INPUT_JSON" | jq -r .parameters.extra_args[0])
YARA_RULES=$(echo "$INPUT_JSON" | jq -r .parameters.extra_args[1])

# Check if file exists
if [[ -n "$FILENAME" && -f "$FILENAME" ]]; then
    # Run YARA scan
    RESULT=$($YARA_PATH "$YARA_RULES" "$FILENAME")
    
    if [[ -n "$RESULT" ]]; then
        # Log YARA matches
        echo "wazuh-yara: INFO - Scan result: $RESULT" | sudo tee -a /var/ossec/logs/active-responses.log
    else
        echo "wazuh-yara: INFO - No YARA match for $FILENAME" | sudo tee -a /var/ossec/logs/active-responses.log
    fi
else
    echo "wazuh-yara: DEBUG - File does not exist or path empty, skipping scan" | sudo tee -a /var/ossec/logs/active-responses.log
fi
