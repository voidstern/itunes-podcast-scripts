#!/bin/bash

# 1. Set the default duration
DURATION=30

# 2. Parse command line arguments
# ":t:" means look for a flag 't' that requires an argument
while getopts ":t:" opt; do
  case ${opt} in
    t)
      DURATION=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Optional: Validate that DURATION is actually a number
if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
    echo "Error: Duration must be a positive integer."
    exit 1
fi

echo "Starting wait for $DURATION minutes. Press ANY key to skip immediately."

# 3. The Wait Loop
for (( i=$DURATION; i>0; i-- )); do
    echo "$i minutes remaining..."
    
    # Wait 60 seconds (1 minute) for input
    read -t 60 -n 1 -s response
    
    # If exit code is 0, a key was pressed
    if [ $? -eq 0 ]; then
        echo -e "\nKey pressed! Skipping the remaining wait."
        break
    fi
done

echo "Continuing execution..."