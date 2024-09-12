
# Crazy Parser Project - README

## Overview
**Crazy Parser** is a Bash script designed to parse CrowdStrike detection JSON files into csv output. It extracts relevant fields from the detection data, including details about detected threats, command lines, filenames, and quarantine information. The script utilizes the `jq` tool for efficient JSON parsing and provides detailed error handling for robust execution.


## Requirements
- **jq**: A command-line JSON processor required for JSON parsing. Install it using:
  ```bash
  sudo apt install jq
  ```

## Script Usage

### Command Format:
```bash
./crazy_parser.sh <input_file>
```

### Example:
```bash
./crazy_parser.sh /path/to/crowdstrike_detections.json
```

### Arguments:
- `<input_file>`: The path to the CrowdStrike detection JSON file to be parsed.


## Error Codes
- `7`: Input file not found.
- `8`: `jq` is not installed.
- `10`: No input file provided in the arguments.
- `77`: jq query error.

## Temp Files
Several temporary files are created during script execution to hold intermediate results. These files are automatically deleted when the script completes.
